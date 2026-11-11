# VEYORA AI proxy

Small Node.js proxy that keeps the OpenAI key off mobile devices.

## Run

### Local Node.js
```bash
cd backend
cp .env.example .env
npm run start:env
```

### Docker
```bash
# Build and run with Docker
docker build -t veyora-ai-proxy .
docker run -p 8787:8787 --env-file .env veyora-ai-proxy

# Or using docker-compose from repository root
docker compose up -d
```

Health check: `curl http://localhost:8787/health`

## Flutter configuration

Pass the proxy URL and shared token at build/run time:

```bash
flutter run \
  --dart-define=AI_PROXY_URL=http://127.0.0.1:8787 \
  --dart-define=AI_PROXY_TOKEN=replace-with-a-long-random-token
```

Android emulator: use `http://10.0.2.2:8787`. iOS simulator: `http://127.0.0.1:8787`.

Without these defines the app uses its local AI engine and no network AI calls.

## Notes

- `AI_PROXY_TOKEN` is optional, but set it before exposing the proxy publicly.
- `OPENAI_MODEL` defaults to `gpt-4o-mini`; any JSON-mode-capable chat model works.
- Requests are capped at 2 MB and rate-limited per IP.
- This proxy does not store resume or interview content.
