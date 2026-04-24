# Security Policy

## Reporting a vulnerability

If you find a security issue in this repository — a skill that could leak secrets, a validator bug that could be exploited, credentials accidentally committed, or anything else — please **do not open a public issue**.

Instead, report privately via GitHub's security advisory flow:
[**Report a vulnerability**](https://github.com/torsday/dotagents/security/advisories/new)

You should receive an acknowledgement within 72 hours. If the report is valid, we'll work with you on a fix timeline and coordinate disclosure.

## Scope

In scope:

- Skill content that instructs an agent to exfiltrate secrets, bypass auth, or take destructive action without confirmation
- Validator script or CI workflow bugs that could be exploited by a malicious PR
- Credentials, tokens, or private data accidentally committed to the repo
- Dependencies pinned to known-vulnerable versions

Out of scope:

- Reports about agents misbehaving in general — this library teaches agents to behave well; individual misuse is the agent harness's concern
- Issues in downstream tools (OpenCode, Claude Code, `glab`, `gh`) — report those to their respective projects
- Speculative risks without a demonstrated attack path

## Supported versions

The latest released version on `main` is the only supported version. Fixes are released as normal version bumps (patch for security fixes, minor for new features per [SemVer](https://semver.org/)).
