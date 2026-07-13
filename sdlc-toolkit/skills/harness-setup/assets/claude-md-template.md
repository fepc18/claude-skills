# CLAUDE.md — Claude Code Work Contract

**Project:** [ProjectName]
**Purpose:** [Brief description of what this system does]
**Last Updated:** [Date]
**Maintainers:** [Team/Persons responsible]

This document is the **contract** between you (Claude Code) and this project. It defines what you can do, what you cannot do, and when you should stop and ask for approval. Read this before every task.

---

## 1. Tech Stack & Versions

**Framework & Language:**
- [Language]: [Exact version] (e.g., Node.js 20.11.0, Go 1.21.1, Python 3.11)
- [Primary Framework]: [Version] (e.g., Express 4.18, Chi 5.0, React 18.2)
- [Database]: [Version] (e.g., PostgreSQL 15.2)
- [Testing]: [Version] (e.g., Jest 29.7, Go testing, Vitest 0.34)

**Important:** Always use these exact versions. Don't upgrade or downgrade without explicit approval. Check `.nvmrc`, `go.mod`, `requirements.txt`, or `package.json` for the source of truth.

**Package Manager:**
- [npm / yarn / pnpm / go mod / pip]: [How to install dependencies]
- Example: `npm install` for Node projects, `go mod download` for Go

---

## 2. Folder Structure

This is where code lives. Don't create files outside these paths without asking.

```
[ProjectName]/
├── src/                          # All source code
│   ├── components/               # [React only] UI components
│   │   ├── atoms/               # Basic building blocks
│   │   ├── molecules/           # Component combinations
│   │   ├── organisms/           # Complex components
│   │   └── pages/               # Page-level components
│   ├── hooks/                    # Custom React hooks
│   ├── services/                 # API calls, business logic
│   ├── utils/                    # Helper functions
│   ├── types/                    # TypeScript interfaces
│   ├── routes/                   # [Node.js] Express routes
│   ├── handlers/                 # [Node.js] Request handlers
│   ├── middleware/               # [Node.js] Express middleware
│   ├── models/                   # [Golang] Domain entities
│   ├── repositories/             # [Golang] Data access
│   └── tests/                    # Unit & integration tests
├── migrations/                   # Database migrations (PROTECTED)
├── infra/                        # Infrastructure code (PROTECTED)
│   ├── terraform/
│   ├── docker/
│   └── kubernetes/
├── .env.example                  # Environment variable template
├── .env.production               # Production env (PROTECTED)
├── docker-compose.yml            # Local dev setup
├── Makefile / package.json       # Build & test commands
└── CLAUDE.md                      # This file

[Other critical files - Dockerfile, CI/CD, configs - PROTECTED]
```

---

## 3. Protected Paths — NEVER Modify Without Asking

These folders/files are off-limits unless explicitly approved for this task:

| Path | Why Protected | Exception |
|------|--------------|-----------|
| `/migrations/` | Schema changes impact production | Only if ticket explicitly says "add migration" |
| `/infra/`, `/terraform/`, `docker-compose.yml` | Infrastructure critical | Explicit approval required |
| `.env*`, `config.prod.js` | Secrets & production config | Never touch |
| `Dockerfile`, `.github/workflows/`, `azure-pipelines.yml` | Deployment critical | Explicit approval required |
| `package-lock.json`, `go.sum` | Dependency lock files | Only auto-updated by package manager |
| `.git/` | Git internals | Never touch |

**If you need to modify a protected path:**
1. Stop immediately
2. Explain why it's needed in a comment
3. Wait for human approval before proceeding

---

## 4. Development Conventions

These are the rules for writing code that fits this project:

### Imports & Dependencies

```
[Language-specific import order]

Example for TypeScript/JavaScript:
1. React / external packages (import React from 'react')
2. External libraries (import { Button } from '@mui/material')
3. Local components (import Header from './components/Header')
4. Types/interfaces (import { User } from '../types')
5. Styles (import './Button.css')

Example for Go:
1. Standard library (import "fmt")
2. External packages (import "github.com/chi-render/chi")
3. Internal packages (import "myapp/internal/domain")
```

**Rule:** If a file starts with the wrong import order, fix it before committing.

### Naming Conventions

- **Files:** kebab-case for filenames (user-service.ts, product-handler.go)
- **Classes/Types:** PascalCase (UserService, PaymentHandler)
- **Functions/Variables:** camelCase (getUserById, calculateTotal)
- **Constants:** UPPER_SNAKE_CASE (API_TIMEOUT, MAX_RETRIES)
- **Folders:** kebab-case (user-management, payment-service)

### Code Style

- **Max line length:** 100 characters (wrap longer lines)
- **Indentation:** 2 spaces (not tabs)
- **Comments:** Explain WHY, not WHAT. Code should be self-documenting.

Example of good comment:
```
// Retry with exponential backoff to handle transient network failures
// without overwhelming the service during outages
```

Bad comment:
```
// Loop through users
```

### Error Handling

[Language-specific error handling pattern]

**JavaScript/TypeScript:**
```typescript
// Always handle errors explicitly
try {
  const user = await getUserById(id);
} catch (error) {
  console.error('Failed to get user:', error.message);
  throw new AppError('User not found', 404);
}
```

**Go:**
```go
// Check errors immediately after operations
user, err := getUserById(ctx, id)
if err != nil {
    return nil, fmt.Errorf("get user: %w", err)
}
```

---

## 5. Testing Requirements

**All code must be tested before commit.** This is non-negotiable.

### Test Commands

Run these BEFORE every commit:

```bash
[For Node.js:]
npm test                # Run all tests
npm run test:watch     # Run tests in watch mode
npm run lint           # Check code style
npm run type-check     # TypeScript type checking

[For Go:]
make test              # Run go test -v ./...
make lint              # Run golangci-lint
make build             # Verify it compiles

[For Python:]
pytest                 # Run pytest
black --check .        # Code style check
```

**Rule:** If ANY test fails, fix it before moving forward. Don't commit with failing tests.

### Test Structure

- **Location:** Tests live in `__tests__/`, same folder as code, or `_test.go` suffix
- **Naming:** `[feature].test.ts` or `[feature]_test.go`
- **Coverage:** Aim for 80%+ coverage on business logic. UI component tests are lower priority.
- **Mocking:** Use MSW (Mock Service Worker) for API mocks in React. Use interfaces + mocks in Go.

Example test:
```typescript
// src/services/__tests__/userService.test.ts
describe('getUserById', () => {
  it('returns user when found', async () => {
    const user = await getUserById('123');
    expect(user.id).toBe('123');
  });

  it('throws error when user not found', async () => {
    await expect(getUserById('nonexistent')).rejects.toThrow();
  });
});
```

---

## 6. Before Every Commit

Follow this checklist every single time before you make a commit:

1. **Run tests:** `[test command]` — all must PASS
2. **Run linter:** `[lint command]` — zero errors
3. **Check types:** `[type command]` (TypeScript/Go) — no warnings
4. **Review changes:** `git diff` — make sure it looks right
5. **Write commit message:** Follow format below
6. **Make commit:** `git commit -m "..."`

**If anything fails, FIX IT before continuing.**

### Commit Message Format

```
[type]: [short description, <50 chars]

[Optional longer explanation if needed, wrapped at 72 chars.
Explain WHAT changed and WHY, not HOW.]

[Optional: mention related issues or decisions]
```

**Types:** `feat` (new feature), `fix` (bug fix), `test` (test addition), `refactor` (code cleanup), `docs` (documentation)

Examples:
```
feat: add POST /users endpoint with email validation

fix: handle concurrent payment requests correctly

test: add test for negative amount validation

refactor: extract user service into separate module
```

---

## 7. When to Stop & Ask For Approval

Don't decide these alone — STOP and explain what you need to do:

### Always Ask Before:

- **Deleting any file** — Even if it seems unused. Code might be imported somewhere obscure.
  - Action: Comment why it should be deleted, wait for approval.

- **Changing function/API signatures** — Existing code might depend on it.
  - Action: List all places that call this function, explain the change, wait for approval.

- **Database schema changes** — These are deployed separately and can't be easily rolled back.
  - Action: Describe the change (new column, index, table), suggest the migration SQL, wait for approval.

- **Adding new external dependencies** — Might conflict with existing versions or introduce security issues.
  - Action: Explain why it's needed, list the version, wait for approval.

- **Changing authentication/security logic** — Risk of breaking access control.
  - Action: Explain the change, show test coverage, wait for approval.

- **Modifying CI/CD pipeline** — Could break deployments.
  - Action: Describe what changes, wait for approval.

### Proceed Without Asking:

- Adding new features in isolated files (new routes, new components, new services)
- Adding tests for existing code
- Fixing bugs within existing functions (not changing signatures)
- Refactoring code without changing behavior
- Adding documentation comments
- Fixing linting/formatting issues

### When Unsure

If you're not sure whether something needs approval: **ask anyway**. It's better to over-communicate than to break something.

---

## 8. Common Patterns in This Project

Here are the expected patterns. Follow these exactly:

### [Node.js] Express Route Handler

```typescript
// src/routes/users.ts
import { Router, Request, Response, NextFunction } from 'express';
import { getUserById } from '../services/userService';
import { AppError } from '../types/errors';

const router = Router();

router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const user = await getUserById(id);

    res.status(200).json(user);
  } catch (error) {
    next(error); // Pass to error handler middleware
  }
});

export default router;
```

### [React] Functional Component

```typescript
// src/components/molecules/UserCard.tsx
import React from 'react';
import { User } from '../../types';

interface UserCardProps {
  user: User;
  onDelete?: (id: string) => void;
}

export const UserCard: React.FC<UserCardProps> = ({ user, onDelete }) => {
  return (
    <div className="user-card">
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      {onDelete && (
        <button onClick={() => onDelete(user.id)}>Delete</button>
      )}
    </div>
  );
};
```

### [Go] Handler Function

```go
// internal/interface/http/user_handler.go
package http

import (
	"net/http"
	"github.com/go-chi/chi/v5"
	"myapp/internal/domain"
	"myapp/internal/application"
)

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "id")

	user, err := h.getUserUC.Execute(r.Context(), userID)
	if err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}
```

---

## 9. Troubleshooting

**Q: Tests are failing with "module not found"**
A: Run `npm install` or `go mod download` to fetch dependencies.

**Q: Linter complains about formatting**
A: Run the auto-fixer: `npm run lint -- --fix` or `go fmt ./...`

**Q: I can't write to /migrations/**
A: That path is protected. Describe what migration you need in a comment, and wait for approval.

**Q: A file I'm trying to edit is on the protected list**
A: Check the "Protected Paths" section. If you need to modify it, explain why and wait for approval.

**Q: TypeScript says unknown type**
A: Check if you imported the type. All imports must be explicit (no global types).

---

## 10. Questions or Ambiguity?

If this document doesn't answer your question, ask before proceeding. Better to clarify than to waste time on the wrong approach.

Common questions to ask:
- "Should I add a new file in [folder]?"
- "Is this approach correct, or is there a better pattern?"
- "Do I need to change the database schema for this?"
- "Should I add a new test file or add tests to the existing one?"

---

**Remember:** This project is a team effort. You're part of the team. Ask questions, follow conventions, test everything, and we'll ship solid code together.
