# Codex instructions

- The authoritative specification is [Game 002 — 古代日本風・投剣探索アクション / プロトタイプ仕様](https://app.notion.com/p/3ec32305966281aab50fe218f60b533b).
- Use Godot 4 and GDScript.
- Implement and verify one phase at a time. Do not start the next phase until the current phase is confirmed.
- Keep scenes and scripts small and readable; avoid premature abstractions.
- When adding scenery that can overlap characters, register its occluding shapes and front/back boundary with the map. Apply the Notion depth-display policy without waiting for individual requests; verify front, behind, and exit views. Characters need four directional poses and alternating motion of both feet.
- Store code, tests, project settings, and code-specific instructions in this repository.
- Record important implementation decisions, verification results, specification differences, and unresolved issues in Notion.
- Read the local AGENTS.md first. Consult the Notion specification when detailed or updated requirements are needed.
