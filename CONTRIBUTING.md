# Contributing to VEYORA

Thank you for your interest in contributing to **VEYORA**! We welcome contributions from developers, designers, and documentation writers of all skill levels.

---

## 📜 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Branching Strategy & Commit Guidelines](#branching-strategy--commit-guidelines)
- [Testing & Quality Checks](#testing--quality-checks)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project adheres to the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## How Can I Contribute?

- **Reporting Bugs**: Check the [GitHub Issues](https://github.com/trydigital2/veyora/issues) before opening a new issue. Use our [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).
- **Suggesting Features**: Submit a feature proposal using the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md).
- **Submitting Pull Requests**: Pick up an open issue or discuss new ideas with the maintainers first.

---

## Development Setup

### 1. Prerequisites
- **Flutter SDK**: 3.41 or newer
- **Dart SDK**: 3.11 or newer
- **Node.js**: 18+ (for AI proxy backend development)
- An IDE with Flutter plugins (VS Code, Android Studio, or IntelliJ IDEA)

### 2. Clone the Repository
```bash
git clone https://github.com/trydigital2/veyora.git
cd veyora
```

### 3. Flutter App Setup
```bash
flutter pub get
flutter run
```

### 4. Backend AI Proxy Setup (Optional)
```bash
cd backend
cp .env.example .env
npm run start:env
```

---

## Branching Strategy & Commit Guidelines

### Branch Naming Conventions
- `feature/<feature-name>` (e.g., `feature/voice-interview-mode`)
- `fix/<bug-description>` (e.g., `fix/ats-score-calculation`)
- `docs/<topic>` (e.g., `docs/proxy-deployment`)
- `refactor/<scope>` (e.g., `refactor/resume-parser`)

### Commit Messages
We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat:` A new feature
- `fix:` A bug fix
- `docs:` Documentation changes only
- `style:` Changes that do not affect the meaning of the code
- `refactor:` A code change that neither fixes a bug nor adds a feature
- `test:` Adding missing tests or correcting existing tests
- `ci:` Changes to CI configuration files and scripts

---

## Testing & Quality Checks

Before submitting any code changes, ensure all checks pass:

### Flutter Checks
```bash
# Verify formatting
dart format --output=none --set-exit-if-changed .

# Static analysis
flutter analyze

# Run unit and widget tests
flutter test
```

### Backend Checks
```bash
cd backend
npm test
```

---

## Pull Request Process

1. Fork the repo and create your branch from `main`.
2. Make your changes with concise, descriptive commits.
3. Verify that all automated tests and linter checks pass locally.
4. Update relevant documentation (e.g., `README.md` or API documentation).
5. Open a Pull Request referencing the related issue number.
6. A maintainer will review your PR and provide feedback.
