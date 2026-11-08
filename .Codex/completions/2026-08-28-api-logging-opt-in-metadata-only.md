# API logging opt-in and metadata-only

- API traffic logging is disabled by default, including debug builds.
- `--dart-define=API_LOGGING=true` enables debug-only method/path/status/timing
  metadata; profile and release builds remain silent.
- Headers, hosts, query strings, request/response bodies, exception messages,
  tokens, and personal data are never formatted or printed by the interceptor.
- Real Dio request data is unchanged.
- Focused regression tests: 12 passed.
- Targeted Flutter analysis: no issues.
- No build, APK, app bundle, or iOS build was run.
