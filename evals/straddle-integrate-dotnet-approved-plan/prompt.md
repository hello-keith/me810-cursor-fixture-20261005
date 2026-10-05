---
description: "An approved plan that names the released C# SDK: Integrate reads the restored NuGet Straddle 1.0.4 package, adds the approved code beside the existing check payments, which keep working, and blocks only the Sandbox writes on the missing configuration."
tags: [integrate, direct, dotnet, configuration, grant-bash-write]
plugins: ["../..", "env-fixture"]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Bash, Write, Edit]
---
The Straddle plan is approved. Please implement it now with the restored C# SDK: the client factory, the charge method and the tests. We have not put the Sandbox key or environment into this shell yet, so this is code only today; no Sandbox setup until we do.
