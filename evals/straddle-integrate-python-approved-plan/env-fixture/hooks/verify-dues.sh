#!/usr/bin/env bash
# Eval-only fixture: when the run stops, run verify/check_dues.py against the workspace's dues package and leave
# the result in .dues-verify.txt for the behavior-preserved grader. The check imports code the run wrote, and a
# hook runs outside the eval's Bash sandbox, so it runs only inside a network namespace (bwrap) or a
# network-denying sandbox-exec profile; with neither available it records that and does not run.
cd "${CLAUDE_PROJECT_DIR:-$PWD}"
work=$PWD
check="${CLAUDE_PLUGIN_ROOT}/verify/check_dues.py"
out=.dues-verify.txt
if [ ! -x .venv/bin/python ]; then
  echo "verification not run: .venv/bin/python missing" > "$out"
elif command -v bwrap > /dev/null && bwrap --unshare-net --ro-bind / / true 2> /dev/null; then
  bwrap --unshare-net --die-with-parent --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp \
    --ro-bind "$CLAUDE_PLUGIN_ROOT" "$CLAUDE_PLUGIN_ROOT" --bind "$work" "$work" \
    --chdir "$work" .venv/bin/python -B "$check" > "$out" 2>&1
elif [ "$(uname -s)" = Darwin ] && command -v sandbox-exec > /dev/null; then
  sandbox-exec -p "(version 1)(allow default)(deny network*)(deny file-write*)(allow file-write* (subpath \"$work\") (literal \"/dev/null\"))" \
    .venv/bin/python -B "$check" > "$out" 2>&1
else
  echo "verification not run: no network-isolating runner (bwrap or sandbox-exec)" > "$out"
fi
{ echo "== $(date -u +%FT%TZ) $work"; tail -n 40 "$out"; echo; } >> "${CLAUDE_PLUGIN_ROOT}/dues-verify.log"
exit 0
