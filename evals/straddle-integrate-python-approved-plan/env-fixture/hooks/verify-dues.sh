#!/usr/bin/env bash
# Eval-only fixture: when the run stops, run verify/check_dues.py against the workspace's dues package and leave
# the result in .dues-verify.txt for the behavior-preserved grader. The check imports code the run wrote, and a
# hook runs outside the eval's Bash sandbox, so the check gets no network, an empty environment, and a filesystem
# view of only the system and Python install directories, this fixture, and the workspace (writable). Without
# bwrap or sandbox-exec to enforce that, it records that and does not run.
cd "${CLAUDE_PROJECT_DIR:-$PWD}"
work=$(pwd -P)
fixture=$(cd "${CLAUDE_PLUGIN_ROOT}" && pwd -P)
check="$fixture/verify/check_dues.py"
out=.dues-verify.txt
home=$(sed -n 's/^home *= *//p' .venv/pyvenv.cfg 2> /dev/null)
prefix=$(cd "$home/.." 2> /dev/null && pwd -P)
if [ ! -x .venv/bin/python ] || [ -z "$prefix" ]; then
  echo "verification not run: .venv or its base Python missing" > "$out"
elif command -v bwrap > /dev/null && bwrap --unshare-all --ro-bind / / true 2> /dev/null; then
  bwrap --unshare-all --die-with-parent --clearenv --setenv PATH /usr/bin:/bin --setenv HOME "$work" --setenv LANG C.UTF-8 \
    --ro-bind /usr /usr --ro-bind-try /lib /lib --ro-bind-try /lib64 /lib64 --ro-bind-try /bin /bin \
    --proc /proc --dev /dev --tmpfs /tmp --ro-bind "$prefix" "$prefix" --ro-bind "$fixture" "$fixture" --bind "$work" "$work" \
    --chdir "$work" .venv/bin/python -B "$check" > "$out" 2>&1
elif [ "$(uname -s)" = Darwin ] && command -v sandbox-exec > /dev/null; then
  readable=""
  for dir in /usr /System /Library /private/etc /dev /opt/homebrew "$prefix" "$fixture" "$work"; do readable="$readable (subpath \"$dir\")"; done
  env -i PATH=/usr/bin:/bin HOME="$work" LANG=en_US.UTF-8 sandbox-exec -p "(version 1)(allow default)(deny network*)
    (deny file-read*)(allow file-read-metadata)(allow file-read* (literal \"/\")$readable)
    (deny file-write*)(allow file-write* (subpath \"$work\") (literal \"/dev/null\"))" \
    .venv/bin/python -B "$check" > "$out" 2>&1
else
  echo "verification not run: no isolating runner (bwrap or sandbox-exec)" > "$out"
fi
{ echo "== $(date -u +%FT%TZ) $work"; tail -n 40 "$out"; echo; } >> "$fixture/dues-verify.log"
exit 0
