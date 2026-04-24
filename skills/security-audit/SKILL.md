---
name: security-audit
description: Full-scope security audit — injection, auth, secrets, crypto, OWASP top 10
compatibility: opencode
---

Looking at the code, perform a focused security review. This goes deeper than the bug-detection pass in a standard refactor.

> [!IMPORTANT]
> **Model capability check:** this skill produces meaningfully better output on a deep-reasoning model — subtle vulnerabilities (auth-boundary reasoning, race conditions, crypto nuance, input-validation corner cases) are found more reliably by deeper models. If you're on a smaller or faster tier, pause and ask before proceeding: _"This skill benefits from a deeper model because subtle vulnerabilities reward thorough scanning. Proceed on the current tier, or stop so you can switch?"_

> [!NOTE]
> **When NOT to use:** Don't use as a substitute for automated scanning in CI — use both. Don't use to audit code you know has known unresolved vulnerabilities; fix the known issues first.

## Protocol

1. Read the relevant files — understand the data flow before looking for vulnerabilities.
2. List findings with severity before suggesting fixes.
3. Propose remediations. Apply only if asked.

---

## Review Areas

### Input Validation & Injection

- All untrusted input (user, API, file, env) validated at the boundary
- SQL injection — parameterized queries used, no string concatenation in queries
- Command injection — no unsanitized input passed to shell commands
- XSS — output encoded appropriately for context (HTML, JS, URL, CSS)
- Path traversal — file paths resolved and constrained to expected directories

### Authentication & Authorization

- Authentication checked before any protected resource is accessed
- Authorization checked at the resource level, not just the route level
- JWTs validated: signature, expiry, audience, issuer
- Session tokens: secure, httpOnly, sameSite flags set
- No auth logic bypassable via parameter manipulation
- CSRF protection on all state-mutating endpoints (SameSite cookies, CSRF tokens, or custom request headers for APIs)
- Mass assignment: user-supplied fields filtered to an allowlist before binding to models — no `req.body` spread directly onto DB objects

### Rate Limiting & Abuse Prevention

- Rate limiting on authentication endpoints (login, password reset, MFA) — brute force protection
- Rate limiting on expensive or public-facing endpoints
- Account lockout or exponential backoff after repeated auth failures
- No unbounded operations triggerable by unauthenticated users (ReDoS, expensive queries, large file uploads without limits)

### Secrets & Credentials

- No hardcoded secrets, API keys, passwords, or tokens in source
- Secrets loaded from environment or secrets manager, not config files checked into git
- `.env` files in `.gitignore`
- Secrets not logged, even at debug level
- GitLab CI: secrets live in project/group CI/CD variables with `Masked` and `Protected` set, never in `.gitlab-ci.yml`

### Data Exposure

- Error messages don't leak stack traces, internal paths, or schema details to clients
- API responses don't include fields the requester shouldn't see
- PII handled according to data minimization principles
- Sensitive data encrypted at rest and in transit

### Dependencies

- Known CVEs in direct dependencies (`npm audit`, `bundler-audit`, `pip-audit`, etc.)
- Dependency versions pinned or bounded appropriately
- No abandoned or suspicious packages
- GitLab Dependency Scanning enabled in CI

### Server-Side Request Forgery (SSRF)

- User-supplied URLs or hostnames used in server-side requests: validated against an allowlist of permitted hosts/schemes
- Internal network addresses (`169.254.x.x`, `10.x.x.x`, `localhost`) blocked when fetching user-supplied URLs
- Cloud metadata endpoints (`169.254.169.254`) not reachable via user-controlled inputs

### Cryptography

- No custom crypto — use established libraries
- Passwords hashed with bcrypt, argon2, or scrypt (not MD5/SHA1/SHA256 alone)
- Sufficient entropy for tokens and nonces
- Timing-safe comparisons for secrets, tokens, and HMAC signatures (constant-time comparison, not `===`)

---

## Severity Scale

**Critical** — exploitable without authentication; data loss or full compromise possible
**High** — exploitable with minimal privileges; significant data or system impact
**Medium** — requires specific conditions; meaningful but limited impact
**Low** — defense-in-depth improvements; low direct exploitability
**Info** — best practice gaps worth noting

---

## Output Format

List findings grouped by severity (Critical → Info). For each finding:

**[Severity] `location`** — what the issue is → why it matters → recommended remediation

Only report what is actually present in the code. Do not pad with theoretical risks that have no evidence in the reviewed files.

---

## Stopping condition

When running in a loop, stop scheduling further invocations when no findings above **Info** severity remain — all Critical, High, Medium, and Low items have been remediated or explicitly accepted with a documented rationale.

Emit this exact phrase so a loop runner recognizes it:

> **Loop exit:** No findings above Info severity remain. Stopping.
