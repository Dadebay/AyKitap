# Backend RevenueCat deployment guide

Created `BACKEND_DEPLOY_REVENUECAT_TURKMEN_SERVER.md` at the `aykitap_full`
workspace root for the backend developer.

It covers branch merge/build gates, PostgreSQL backup and all currently known
pending Firebase/RevenueCat migrations, production Docker/env corrections,
RevenueCat webhook and secret setup, staged enablement, and a VPN-independent
external HTTPS relay fallback for restricted Türkmenistan egress.

The instructions were checked against the current backend controllers,
environment validation, TypeORM scripts, compose file, and RevenueCat client.
No backend, admin, database, dashboard, or server state was changed.

