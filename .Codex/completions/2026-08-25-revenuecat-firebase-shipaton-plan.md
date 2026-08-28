# RevenueCat + Firebase Auth + Shipaton plan

## Completed

- Inspected the Flutter app, NestJS backend, and React admin repositories.
- Confirmed the existing canonical backend user/JWT, phone OTP, signup bonus,
  balance purchase, subscription, and bought-book architecture.
- Created `codex/revenuecat-firebase-auth` in both `aykitap-backend` and
  `aykitap-admin` without touching the mobile repo's dirty branch.
- Added the shared implementation and release plan at
  `../../REVENUECAT_FIREBASE_SHIPATON_PLAN.md`.
- Kept final theme/English QA, foldable work, and widget verification out of
  scope as requested.

## Important architecture decisions

- Backend `users.id` remains the canonical identity.
- Firebase identities attach to the canonical user instead of replacing it.
- RevenueCat App User ID is `user_<backendUserId>` on every platform.
- Backend wallet access and RevenueCat store entitlements are merged without
  duplicating user accounts or signup rewards.
- RevenueCat webhook processing must be authenticated, idempotent, sandbox
  isolated, and backed by server-side reconciliation.

## Verification

- Backend branch: `codex/revenuecat-firebase-auth`
- Admin branch: `codex/revenuecat-firebase-auth`
- No builds, dependency installs, migrations, or application code changes were
  run in this planning task.
