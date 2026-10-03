#!/usr/bin/env bash
# Eval-only fixture: when the run stops, run verify/check_dues.py against the workspace's dues package and leave
# the result in .dues-verify.txt for the behavior-preserved grader.
#
# Everything in the workspace is the run's, including .venv and .dues-verify.txt, and this hook runs outside the
# eval's Bash sandbox. So the hook itself never opens, stats or executes a workspace path. It reads only the
# runner's environment, this fixture, and the runner's own python3. The check runs inside bwrap with no network,
# no inherited environment, and a filesystem view built only from those trusted sources plus the workspace. Its
# output goes to a hook-owned temp file, and the result enters the workspace as a new file renamed over
# .dues-verify.txt, so a planted symlink, hard link, FIFO or directory there is replaced or refused, never followed.
# Without a usable bwrap the check does not run.
set -u
[ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0
fixture=$(cd "$CLAUDE_PLUGIN_ROOT" && pwd -P) || exit 0
work=$(cd "$CLAUDE_PROJECT_DIR" && pwd -P) || exit 0
python=$(command -v python3) || exit 0
prefix=$("$python" -c 'import sys; print(sys.base_prefix)') && prefix=$(cd "$prefix" && pwd -P) || exit 0
user_home=$("$python" -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)') || exit 0
tmp=$(mktemp -d) || exit 0
trap 'rm -rf "$tmp"' EXIT

within() { case "$2/" in "$1"/*) return 0 ;; esac; return 1; } # $2 is $1 or inside it
unsafe=""
for dir in "$work" "$prefix" "$fixture"; do
  [ "$dir" = / ] && unsafe="$dir is the filesystem root"
  for home in "$user_home" "${HOME:-/}"; do within "$dir" "$home" && unsafe="$dir contains the home $home"; done
done
within "$work" "$prefix" && unsafe="the Python install is inside the workspace"
within "$work" "$fixture" && unsafe="the fixture is inside the workspace"

system=(--unshare-all --new-session --die-with-parent --clearenv --ro-bind /usr /usr
  --ro-bind-try /lib /lib --ro-bind-try /lib64 /lib64 --ro-bind-try /bin /bin --proc /proc --dev /dev --tmpfs /tmp)
if [ -n "$unsafe" ]; then
  echo "verification not run: $unsafe" > "$tmp/out"
elif command -v bwrap > /dev/null && bwrap "${system[@]}" /usr/bin/true 2> /dev/null; then
  bwrap "${system[@]}" --setenv PATH /usr/bin:/bin --setenv HOME "$work" --setenv LANG C.UTF-8 \
    --ro-bind "$prefix" "$prefix" --ro-bind "$fixture" "$fixture" --bind "$work" "$work" --chdir "$work" \
    .venv/bin/python -B "$fixture/verify/check_dues.py" > "$tmp/out" 2>&1 < /dev/null
else
  echo "verification not run: no usable bwrap to confine the check" > "$tmp/out"
fi

"$python" - "$work" "$tmp/out" <<'EOF'
import os, secrets, sys
work, result = sys.argv[1], sys.argv[2]
data = open(result, "rb").read()
directory = os.open(work, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
staged = f".dues-verify-{secrets.token_hex(8)}.tmp"
fd = os.open(staged, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o644, dir_fd=directory)
os.write(fd, data)
os.close(fd)
try:
    os.replace(staged, ".dues-verify.txt", src_dir_fd=directory, dst_dir_fd=directory)
except OSError:
    os.unlink(staged, dir_fd=directory)
EOF
{ echo "== $(date -u +%FT%TZ) $work"; tail -n 40 "$tmp/out"; echo; } >> "$fixture/dues-verify.log"
exit 0
