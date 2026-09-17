# V2 Validation Snapshot

Branch: `feature/cyberpunk-pixelmatch-v2`

Code commit: `1f2ef8055f422fffa891ace2e86eabde506cb846`

GitHub Actions run: `35255740382`

Result: `success`

Validated by CI:
- arm64 iOS dynamic library compilation succeeded.
- Mach-O inspection step succeeded.
- Artifact upload succeeded.
- Output artifact: `DylibCaidan-arm64`.

Not yet validated:
- real-device injection startup
- actual on-device pixel matching against the concept image
- touch pass-through under the target host app
- rotation / background-foreground / scene transitions
