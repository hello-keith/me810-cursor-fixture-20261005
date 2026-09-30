#!/usr/bin/env bash
# Eval-only scaffold: writes a small fixture repository, commits it, and installs a
# Straddle CLI stand-in at ./bin/straddle. The stand-in prints fixed offline outputs,
# logs every call, and refuses network commands. It never runs the real CLI.
set -euo pipefail
mkdir -p bin src
cat > package.json <<'EOF'
{
  "name": "walkies",
  "private": true,
  "type": "module",
  "scripts": { "start": "tsx src/server.ts", "test": "node --test" },
  "dependencies": { "express": "^4.19.2" },
  "devDependencies": { "tsx": "^4.19.0", "typescript": "^5.6.0" }
}
EOF
cat > src/server.ts <<'EOF'
import express from 'express';

const app = express();
app.use(express.json());

app.post('/bookings', (req, res) => {
  // TODO: collect payment from the owner and pay the walker after the walk.
  res.status(201).json({ id: 'bk_1', walkerId: req.body.walkerId });
});

app.listen(3000);
EOF
printf 'bin/\n.straddle-fixture-calls.log\n' > .gitignore
git init -q
git add -A
git -c user.name=eval -c user.email=eval@example.invalid commit -qm "fixture"
: > .straddle-fixture-calls.log
cat > bin/straddle <<'STUB'
#!/usr/bin/env bash
root="$(cd "$(dirname "$0")/.." && pwd)"
printf '%s\n' "$*" >> "$root/.straddle-fixture-calls.log"
case "$*" in
  "--version"|"version")
    echo "straddle v1.0.3" ;;
  "auth status --agent"|"auth status --json")
    cat <<'JSON'
{
  "authenticated": false,
  "config": "/home/dev/.config/straddle/config.toml",
  "source": "",
  "verified": false
}
JSON
    echo 'Error: no credentials configured' >&2; exit 4 ;;
  *doctor*|*accounts*)
    echo "eval fixture: network commands are refused in this case" >&2
    exit 97 ;;
  *)
    echo "eval fixture: unsupported command: $*" >&2
    exit 2 ;;
esac
STUB
chmod +x bin/straddle
