import http from 'node:http';
import crypto from 'node:crypto';

const PORT = Number(process.env.PORT || 8787);
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o-mini';
const AI_PROXY_TOKEN = process.env.AI_PROXY_TOKEN || '';
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || '*';
const MAX_BODY_BYTES = 2 * 1024 * 1024;
const RATE_LIMIT = Number(process.env.RATE_LIMIT || 30);
const RATE_WINDOW_MS = 60_000;
const requestLog = new Map();

const TASKS = new Set([
  'resume_analysis',
  'job_match',
  'summary',
  'experience',
  'cover_letter',
  'interview_questions',
  'interview_feedback',
]);

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ALLOWED_ORIGIN);
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Vary', 'Origin');
}

function sendJson(res, status, body) {
  cors(res);
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

function safeEqual(actual, expected) {
  const a = Buffer.from(actual);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

function authorized(req) {
  if (!AI_PROXY_TOKEN) return true;
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  return safeEqual(token, AI_PROXY_TOKEN);
}

function withinRateLimit(req) {
  const ip = req.socket.remoteAddress || 'unknown';
  const now = Date.now();
  const entry = requestLog.get(ip);
  if (!entry || now - entry.start > RATE_WINDOW_MS) {
    requestLog.set(ip, { start: now, count: 1 });
    return true;
  }
  entry.count += 1;
  return entry.count <= RATE_LIMIT;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error('Request body is too large.'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

function truncate(value, max) {
  return typeof value === 'string' ? value.slice(0, max) : '';
}

function strings(value, max = 12) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string' && item.trim())
    .map((item) => item.trim())
    .slice(0, max);
}

function score(value, fallback = 60) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(0, Math.min(100, Math.round(parsed)));
}

function wordCount(text) {
  return text.trim().split(/\s+/).filter(Boolean).length;
}

function normalize(task, raw, payload) {
  const data = raw && typeof raw === 'object' ? raw : {};
  switch (task) {
    case 'resume_analysis':
      return {
        overallScore: score(data.overallScore),
        atsScore: score(data.atsScore),
        skillsScore: score(data.skillsScore),
        experienceScore: score(data.experienceScore),
        educationScore: score(data.educationScore),
        formattingScore: score(data.formattingScore),
        strengths: strings(data.strengths, 6),
        weaknesses: strings(data.weaknesses, 6),
        missingSkills: strings(data.missingSkills, 10),
        suggestions: strings(data.suggestions, 6),
        detectedSkills: strings(data.detectedSkills, 18),
        wordCount: wordCount(payload.resumeText || ''),
      };
    case 'job_match':
      return {
        score: score(data.score),
        matchedSkills: strings(data.matchedSkills, 14),
        missingSkills: strings(data.missingSkills, 10),
        suggestions: strings(data.suggestions, 6),
        summary: truncate(data.summary, 1200),
      };
    case 'summary':
    case 'experience':
    case 'cover_letter':
      if (typeof data.content !== 'string' || !data.content.trim()) {
        throw new Error('The model did not return generated content.');
      }
      return { content: data.content.trim() };
    case 'interview_questions': {
      const questions = Array.isArray(data.questions) ? data.questions : [];
      const cleaned = questions
        .filter((q) => q && typeof q.text === 'string' && q.text.trim())
        .slice(0, 10)
        .map((q, index) => ({
          id: `q${index + 1}`,
          text: q.text.trim(),
          category: truncate(q.category, 40) || payload.category || 'General',
          hint: truncate(q.hint, 400),
          idealPoints: strings(q.idealPoints, 6),
        }));
      if (!cleaned.length) throw new Error('The model did not return interview questions.');
      return { questions: cleaned };
    }
    case 'interview_feedback':
      return {
        score: score(data.score),
        strengths: strings(data.strengths, 5),
        improvements: strings(data.improvements, 5),
        modelAnswer: truncate(data.modelAnswer, 4000),
        deliveryTip: truncate(data.deliveryTip, 600),
      };
    default:
      throw new Error('Unknown task.');
  }
}

function promptFor(task, payload) {
  const role = truncate(payload.targetRole || payload.role || 'the target role', 160);
  switch (task) {
    case 'resume_analysis':
      return `Analyze this resume for the target role "${role}".
Return only JSON with exactly these keys:
overallScore, atsScore, skillsScore, experienceScore, educationScore, formattingScore (integers 0-100),
strengths (3-5 strings), weaknesses (3-5 strings), missingSkills (up to 8 strings),
suggestions (4-6 specific strings), detectedSkills (up to 14 strings).

Be specific, recruiter-grade, and realistic. Penalize missing metrics, weak structure, and missing role keywords.

RESUME:
${truncate(payload.resumeText, 50000)}`;
    case 'job_match':
      return `Compare this resume against the job "${truncate(payload.jobTitle, 160)}" at "${truncate(payload.company, 160)}".
Return only JSON with exactly these keys:
score (integer 0-100), matchedSkills (strings), missingSkills (strings),
suggestions (4-6 actionable strings), summary (2-3 sentences).

JOB DESCRIPTION:
${truncate(payload.jobDescription, 30000)}

RESUME:
${truncate(payload.resumeText, 50000)}`;
    case 'summary':
      return `Write a polished resume professional summary.
Return only JSON: {"content": "..."}.
Use 2-3 sentences, first person without "I", no clichés, no markdown.
Name: ${truncate(payload.name, 120)}
Target role: ${role}
Experience level: ${truncate(payload.experienceLevel, 80)}
Strongest skills: ${strings(payload.skills, 10).join(', ')}`;
    case 'experience':
      return `Write 3 resume bullet points for this role.
Return only JSON: {"content": "..."}.
Use past-tense action verbs, quantified impact where plausible, and no markdown.
Role: ${truncate(payload.role, 160)}
Company: ${truncate(payload.company, 160)}
Relevant skills: ${strings(payload.skills, 10).join(', ')}`;
    case 'cover_letter':
      return `Write a tailored ${truncate(payload.style, 40) || 'Professional'} cover letter.
Return only JSON: {"content": "..."}.
No markdown. Include a greeting, 3-4 tight paragraphs, and a sign-off.
Candidate: ${truncate(payload.name, 120)}
Target role: ${role}
Company: ${truncate(payload.company, 160)}
Experience level: ${truncate(payload.experienceLevel, 80)}
Candidate skills: ${strings(payload.resumeSkills, 16).join(', ')}
Contact: ${truncate(payload.email, 160)} ${truncate(payload.phone, 80)}

JOB DESCRIPTION:
${truncate(payload.jobDescription, 30000)}`;
    case 'interview_questions': {
      const count = Math.max(1, Math.min(Number(payload.count) || 6, 10));
      return `Generate ${count} realistic interview questions.
Return only JSON: {"questions":[{"text":"...","category":"...","hint":"...","idealPoints":["..."]}]}.
Category: ${truncate(payload.category, 60) || 'Mixed'}
Level: ${truncate(payload.level, 60) || 'Mid-level'}
Role: ${role}
Mix behavioral, role-specific, and technical questions as appropriate.`;
    }
    case 'interview_feedback':
      return `Evaluate this interview answer for a ${role} interview.
Return only JSON with exactly these keys:
score (integer 0-100), strengths (2-4 strings), improvements (2-4 strings),
modelAnswer (a stronger 120-220 word answer), deliveryTip (one concrete tip).

QUESTION:
${truncate(JSON.stringify(payload.question || {}), 4000)}

CANDIDATE ANSWER:
${truncate(payload.answer, 12000)}`;
    default:
      throw new Error('Unknown task.');
  }
}

async function callOpenAi(task, payload) {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    signal: AbortSignal.timeout(45_000),
    body: JSON.stringify({
      model: OPENAI_MODEL,
      temperature: 0.4,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content:
            'You are VEYORA, a precise career intelligence engine. Return only valid JSON. Never invent credentials, employers, or degrees.',
        },
        { role: 'user', content: promptFor(task, payload) },
      ],
    }),
  });

  const body = await response.text();
  if (!response.ok) {
    throw new Error(`OpenAI request failed (${response.status}): ${body.slice(0, 500)}`);
  }
  const decoded = JSON.parse(body);
  const content = decoded?.choices?.[0]?.message?.content;
  if (typeof content !== 'string' || !content.trim()) {
    throw new Error('OpenAI returned an empty response.');
  }
  return JSON.parse(content);
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    sendJson(res, 200, {
      ok: true,
      configured: Boolean(OPENAI_API_KEY),
      model: OPENAI_MODEL,
      authRequired: Boolean(AI_PROXY_TOKEN),
    });
    return;
  }

  if (req.method !== 'POST' || req.url !== '/api/ai') {
    sendJson(res, 404, { error: 'Not found.' });
    return;
  }

  if (!authorized(req)) {
    sendJson(res, 401, { error: 'Unauthorized.' });
    return;
  }
  if (!withinRateLimit(req)) {
    sendJson(res, 429, { error: 'Too many requests. Please slow down.' });
    return;
  }
  if (!OPENAI_API_KEY) {
    sendJson(res, 503, { error: 'OPENAI_API_KEY is not configured on the proxy.' });
    return;
  }

  try {
    const raw = await readBody(req);
    const body = JSON.parse(raw);
    const task = body?.task;
    const payload = body?.payload;
    if (!TASKS.has(task)) {
      sendJson(res, 400, { error: 'Unsupported task.' });
      return;
    }
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      sendJson(res, 400, { error: 'A payload object is required.' });
      return;
    }

    const result = normalize(task, await callOpenAi(task, payload), payload);
    sendJson(res, 200, { result });
  } catch (error) {
    console.error(`[${new Date().toISOString()}]`, error.message);
    const message = error instanceof SyntaxError ? 'Invalid JSON request body.' : 'AI request failed.';
    sendJson(res, 502, { error: message });
  }
});

server.listen(PORT, () => {
  console.log(`VEYORA AI proxy listening on http://localhost:${PORT}`);
  console.log(`Model: ${OPENAI_MODEL} · configured: ${Boolean(OPENAI_API_KEY)}`);
});
