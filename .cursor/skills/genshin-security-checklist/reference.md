# Reference — Genshin security checklist

Inspired by defensive themes from public agent skill libraries (mobile app
review, API Top 10 mindset, agent/tool poisoning awareness). **Not** a vendored
copy of those repos; keep this file short and project-specific.

## Key paths

| Area | Paths |
|------|--------|
| External content rule | `.cursor/rules/security-external-content.mdc` |
| User-facing errors | `genshin-builder-mobile/lib/core/errors/user_facing_error.dart` |
| HoYoLAB API | `genshin-builder-mobile/lib/data/hoyolab/hoyolab_api.dart` |
| Android manifest / backup | `genshin-builder-mobile/android/app/src/main/AndroidManifest.xml` |
| Data extraction | `genshin-builder-mobile/android/app/src/main/res/xml/data_extraction_rules.xml` |
| ProGuard / release | `genshin-builder-mobile/android/app/build.gradle.kts`, `proguard-rules.pro` |
| Signing example | `genshin-builder-mobile/android/key.properties.example` |
| Mobile CI secret guard | `.github/workflows/genshin-mobile-ci.yml` |
| Release example | `.github/workflows/genshin-mobile-release-example.yml` |

## Done (Phase 0–1)

- Backup disabled; extraction rules; minify/shrink; optional signing
- HoYoLAB timeouts; cookie after verify+roles only
- User vs debug error split; CI secret pattern guard; obfuscation example

## Deferred (call out when relevant)

- Production `applicationId` finalization
- SQLCipher / DB at-rest encryption
- Stricter JSON schema validation for remote configs
- Stronger Agent auto-commit / hook hardening

## Mapping to external skill themes (read-only inspiration)

| Theme | Use here as |
|-------|-------------|
| Mobile app pentest (MASTG-style) | Checklist B–D only; no live exploit |
| OWASP API Top 10 | Checklist E for web sync/auth |
| MCP / tool poisoning / prompt injection | Checklist A + existing Cursor rule |
| SBOM / supply chain | Checklist F (light dependency hygiene) |
