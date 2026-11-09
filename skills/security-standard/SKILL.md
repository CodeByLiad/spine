---
name: security-standard
description: Use whenever code is planned, written, reviewed, fixed or released under Spine. The company security standard every branch is held to. Non-negotiable rules (a violation is a Critical finding), the per-branch checklist implementers and reviewers apply, and the release checks run before merge.
---

# Security standard

Spine applies this standard to every branch, in every repo. Implementers follow it. Task reviewers
and the final reviewer check the diff against it. `writing-plans` copies the relevant rules into each
plan's Global Constraints. `finishing-a-branch` runs the release checks.

A project may add stricter rules of its own (its spec, its owner rulings, its `.spine/config.md`).
It may not relax these.

## 1. Non-negotiable rules — severity per section 4 (Critical rules block merge)

Rules naming a layer — subscription check, admin registry, identity service, per-product DB
role, shared process — apply **where the project has that layer**. A single-app repo with no
subscriptions is not in breach of rule 3 for lacking a subscription check. It must still
authenticate and authorise every route.

1. **No secrets in code.** API keys, tokens, passwords, signing secrets and connection strings live
   only in git-ignored env files and the host's secret store. Never in source, tests, docs, fixtures,
   client bundles or commit history.
2. **Server env never reaches the client.** Only variables explicitly meant for the browser (e.g. a
   `VITE_` / `NEXT_PUBLIC_` prefix) are bundled. A server secret behind a public prefix is a leak.
3. **Every route is authenticated and authorised on the server.** Token verification, then (where
   the project sells products or plans) the subscription check, then the role check, then the handler.
   Admin routes check an audited admin list where one exists, or an explicit admin role. No route
   relies on the client hiding a button.
4. **Object-level access on every id.** Every id that arrives in a URL **or a request body** is checked
   against the caller's tenant and permissions before it is read, written or joined. A foreign-key match
   proves only that the row exists somewhere, not that the caller owns it. Lists are scoped on the
   server, never filtered on the client.
5. **One owner of identity.** Where identity is a separate service, only it creates users, sets roles
   or touches passwords, and products read identity and never write it. In a single app, identity writes
   live in one module. A role removal takes effect on the next request.
6. **Parameterised queries only.** No string-built SQL. Never interpolate a JS array or user value into
   a SQL template. Database roles follow least privilege, one role per product where the platform allows.
7. **Passwords hashed with bcrypt (cost ≥ 10) or Argon2id.** Never stored or logged in clear text.
   Reset tokens are single-use and expire.
8. **State changes that move money, stock or approvals are guarded inside the transaction.**
   `UPDATE … WHERE status = '<expected>' RETURNING …`, and refuse (409) when no row returns, so a double
   submit or race can never apply twice or overwrite a concurrent decision.
9. **Input is validated on the server, and the database enforces key invariants itself.** CHECK, NOT NULL,
   UNIQUE and FK constraints for rules that must never break, so a route that forgets is still refused.
   Uploads: size cap enforced while reading, content type detected from the bytes, never trusted from the
   client.
10. **No process-global side effects from a product module** that shares a process with others
    (global type parsers, global middleware, monkey-patching, `process.exit`, timers at import).
11. **Tests never touch production.** Every test refuses to run unless the database is the named
    development target. Tests create their own tenants or use fixed test tenants. They never discover
    "another org", because that can land on a real customer.
12. **No production action without the owner's explicit OK.** Queries, writes, migrations, deploys and
    pushes included. Read-only is not a licence.
13. **No claim without proof.** A security fix is reported as fixed only when a test demonstrates it.

## 2. Per-branch checklist — implementer applies it, reviewers verify it

For every change in the diff, as applicable:

- [ ] No secret, key or connection string in the diff (code, tests, docs, fixtures, config)
- [ ] Every new or changed route sits behind the gate chain and has a role check
- [ ] Every id from URL or body is checked against the caller's tenant (rule 4)
- [ ] A cross-tenant test runs in both directions, with a positive control, **mutation-proved**
      (break the guard, see the test go red, restore from a backup copy, never `git checkout`)
- [ ] All SQL parameterised; no arrays or user values in SQL templates
- [ ] Money/stock/approval transitions status-guarded inside the transaction (rule 8), with a race test
- [ ] Database constraints back the business rules the route enforces
- [ ] Uploads capped while reading and content-sniffed
- [ ] Refusals return an explicit code and a plain message. **No stack trace, SQL text or internal path
      in any response body**
- [ ] CORS stays an explicit allowlist; never `*` with credentials
- [ ] Any cookie set or changed is `HttpOnly`, `Secure` and `SameSite` (Lax or Strict)
- [ ] Any new or changed service sends security headers: HSTS, `X-Frame-Options` (or CSP
      `frame-ancestors`), `X-Content-Type-Options: nosniff`, and a Content-Security-Policy
- [ ] Auth, login and public endpoints are rate-limited
- [ ] No new dependency without need. Any new dependency has no known High/Critical advisory
- [ ] No module-level side effects in code mounted alongside other products (rule 10)
- [ ] New tests refuse to run off the development database and create their own tenants

## 3. Release checks — `finishing-a-branch` runs these before merge or push

1. **Dependency audit.** Run the package manager's audit (e.g. `npm audit --omit=dev`). Any High or
   Critical advisory in a package the branch adds or upgrades blocks the merge. Pre-existing ones are
   reported to the owner, never silently ignored.
2. **Secrets scan.** Scan the branch's commits for secrets (e.g. `gitleaks detect --log-opts
   "<base>..HEAD"`). Any hit blocks the merge until the secret is removed **and rotated**. If the
   scanner is not installed, say so in the finish report — never imply it ran.
3. **Exposed files** (only for a branch that changes static serving, hosting or routing). Confirm that
   `.env`, `.git`, backups and logs are not reachable. Probing a live domain needs the owner's OK
   (rule 12).
4. **Threat-model pass** (only for a branch that touches identity, roles, money, cross-tenant data or a
   new public endpoint). The final reviewer states how the change could be chained with existing
   routes to escalate privilege or cross a tenant boundary, and what stops it. The controller checks
   the final-review report for this paragraph. If it is missing, the controller re-dispatches the
   final reviewer before recording the review receipt.

**Who owns which check.** `finishing-a-branch` owns checks 1–3: it runs them and records pass, fail
or "not run". The final reviewer owns check 4. The final reviewer may note dependency or secret
concerns it sees in the diff, but it does not replace the finish-stage scans.

## 4. Severity guide for reviewers — the single source both reviewers use

- **Critical:**
  - a violation of rules 1–8, 10, 11 or 12;
  - any cross-tenant read or write;
  - any privilege escalation;
  - a secret in the diff;
  - an unguarded money, stock or approval transition;
  - a password stored or logged in clear text.
- **Important:**
  - a violation of rule 9 (missing DB constraint, upload cap or content sniffing);
  - a violation of rule 13 (a security claim with no test);
  - a missing section 2 checklist item on a changed route or service;
  - a guard with no mutation proof;
  - a test that cannot fail.
- **Minor:** hardening that reduces risk, but whose absence is not exploitable in the current code.

**Mutation proof is verified, not taken on trust.** The reviewer checks the report's mutation evidence
against the diff. Where the evidence is thin, the reviewer re-runs the mutation on a temporary copy
outside the working tree. A reviewer never edits the tree and never runs `git checkout`.

**Reviewers never contact production or a live domain.**

The implementer's stated rationale never lowers a security finding's severity.
