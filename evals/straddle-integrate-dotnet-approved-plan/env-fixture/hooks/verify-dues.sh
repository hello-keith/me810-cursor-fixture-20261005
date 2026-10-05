#!/bin/bash
# Eval-only fixture: when the run stops, compile verify/FixtureVerify.cs into the workspace's test project and run it
# with `dotnet test --no-restore`, leaving the result in .dues-verify.txt for the behavior-preserved grader.
#
# Everything in the workspace is the run's, including .nuget and .dues-verify.txt, and this hook runs outside the
# eval's Bash sandbox. So the hook itself never opens, stats or executes a workspace path, and leaves the workspace
# as its cwd before running anything: PATH is the system's and the only interpreter it runs is the system python3,
# isolated (-I -S). The check runs inside bwrap with no network, no inherited environment, and a filesystem view
# built only from the system directories (the apt .NET SDK lives in /usr/lib/dotnet), this fixture, and the workspace
# mounted read-only. It builds a copy of src/ and tests/ in its own /tmp, reading packages from the workspace's
# .nuget/packages, so the fixture's test file and the build output never reach the real workspace.
# Its output goes to a hook-owned temp file, and the result enters the workspace as a new file renamed over
# .dues-verify.txt, so a planted symlink, hard link, FIFO or directory there is replaced or refused, never followed.
# Without a usable bwrap the check does not run.
set -u
export PATH=/usr/bin:/bin
[ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0
fixture=$(cd "$CLAUDE_PLUGIN_ROOT" && pwd -P) || exit 0
work=$(cd "$CLAUDE_PROJECT_DIR" && pwd -P) || exit 0
cd / || exit 0
python=/usr/bin/python3
user_home=$("$python" -I -S -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)') || exit 0
tmp=$(mktemp -d) || exit 0
trap 'rm -rf "$tmp"' EXIT

within() { case "$2/" in "$1"/*) return 0 ;; esac; return 1; } # $2 is $1 or inside it
unsafe=""
for dir in "$work" "$fixture"; do
  [ "$dir" = / ] && unsafe="$dir is the filesystem root"
  for home in "$user_home" "${HOME:-/}"; do within "$dir" "$home" && unsafe="$dir contains the home $home"; done
done
within "$work" "$fixture" && unsafe="the fixture is inside the workspace"

system=(--unshare-all --new-session --die-with-parent --clearenv --ro-bind /usr /usr
  --ro-bind-try /lib /lib --ro-bind-try /lib64 /lib64 --ro-bind-try /bin /bin --proc /proc --dev /dev --tmpfs /tmp)
if [ -n "$unsafe" ]; then
  echo "verification not run: $unsafe" > "$tmp/out"
elif [ -x /usr/bin/bwrap ] && bwrap "${system[@]}" /usr/bin/true 2> /dev/null; then
  bwrap "${system[@]}" --setenv PATH /usr/bin:/bin --setenv HOME /tmp --setenv DOTNET_CLI_HOME /tmp --setenv LANG C.UTF-8 \
    --setenv DOTNET_NOLOGO 1 --setenv DOTNET_CLI_TELEMETRY_OPTOUT 1 --setenv MSBUILDDISABLENODEREUSE 1 \
    --ro-bind /etc/passwd /etc/passwd --ro-bind "$fixture" "$fixture" --ro-bind "$work" "$work" --chdir /tmp \
    /bin/sh -c 'mkdir w && cp -R "$2/src" "$2/tests" w/ && cp "$1/verify/FixtureVerify.cs" w/tests/Dues.Tests/ &&
      exec dotnet test w/tests/Dues.Tests --no-restore --filter "FullyQualifiedName~FixtureVerify" \
      --logger "console;verbosity=normal"' sh "$fixture" "$work" \
    > "$tmp/out" 2>&1 < /dev/null
else
  echo "verification not run: no usable bwrap to confine the check" > "$tmp/out"
fi

"$python" -I -S - "$work" "$tmp/out" <<'EOF'
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
