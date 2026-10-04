#!/bin/bash
# Eval-only fixture: when the run stops, compile verify/dues_verify_test.go into the workspace's dues package with a
# go test -overlay, run it, and leave the result in .dues-verify.txt for the behavior-preserved grader.
#
# Everything in the workspace is the run's, including vendor/ and .dues-verify.txt, and this hook runs outside the
# eval's Bash sandbox. So the hook itself never opens, stats or executes a workspace path, and leaves the workspace
# as its cwd before running anything: PATH is the system's, Go runs as /usr/local/bin/go with GOENV=off, and the
# system python3 runs isolated (-I -S). It reads only the runner's environment, this fixture, the Go install and the
# system python3. The check runs inside bwrap with no network, no inherited environment, the workspace read-only,
# and a filesystem view built only from those trusted sources. Its output goes to a hook-owned temp file, and the
# result enters the workspace as a new file renamed over .dues-verify.txt, so a planted symlink, hard link, FIFO or
# directory there is replaced or refused, never followed. Without a usable bwrap the check does not run.
set -u
export PATH=/usr/bin:/bin
[ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0
fixture=$(cd "$CLAUDE_PLUGIN_ROOT" && pwd -P) || exit 0
work=$(cd "$CLAUDE_PROJECT_DIR" && pwd -P) || exit 0
cd / || exit 0
python=/usr/bin/python3
goroot=$(env -i GOENV=off GOTOOLCHAIN=local /usr/local/bin/go env GOROOT) && goroot=$(cd "$goroot" && pwd -P) || exit 0
user_home=$("$python" -I -S -c 'import os, pwd; print(pwd.getpwuid(os.getuid()).pw_dir)') || exit 0
tmp=$(mktemp -d) || exit 0
trap 'rm -rf "$tmp"' EXIT

within() { case "$2/" in "$1"/*) return 0 ;; esac; return 1; } # $2 is $1 or inside it
unsafe=""
for dir in "$work" "$goroot" "$fixture"; do
  [ "$dir" = / ] && unsafe="$dir is the filesystem root"
  for home in "$user_home" "${HOME:-/}"; do within "$dir" "$home" && unsafe="$dir contains the home $home"; done
done
within "$work" "$goroot" && unsafe="the Go install is inside the workspace"
within "$work" "$fixture" && unsafe="the fixture is inside the workspace"

"$python" -I -S -c 'import json, sys; json.dump({"Replace": {sys.argv[1] + "/dues/dues_verify_test.go": sys.argv[2] + "/verify/dues_verify_test.go"}}, open(sys.argv[3], "w"))' \
  "$work" "$fixture" "$tmp/overlay.json" || exit 0
system=(--unshare-all --new-session --die-with-parent --clearenv --ro-bind /usr /usr
  --ro-bind-try /lib /lib --ro-bind-try /lib64 /lib64 --ro-bind-try /bin /bin --proc /proc --dev /dev --tmpfs /tmp)
if [ -n "$unsafe" ]; then
  echo "verification not run: $unsafe" > "$tmp/out"
elif [ -x /usr/bin/bwrap ] && bwrap "${system[@]}" /usr/bin/true 2> /dev/null; then
  bwrap "${system[@]}" --setenv PATH "$goroot/bin:/usr/bin:/bin" --setenv HOME /tmp --setenv LANG C.UTF-8 \
    --setenv GOROOT "$goroot" --setenv GOENV off --setenv GOTOOLCHAIN local --setenv GOFLAGS -mod=vendor \
    --setenv GOPROXY off --setenv GOCACHE /tmp/go-build --setenv GOPATH /tmp/go --setenv CGO_ENABLED 0 \
    --ro-bind "$goroot" "$goroot" --ro-bind "$fixture" "$fixture" --ro-bind "$tmp/overlay.json" /overlay.json \
    --ro-bind "$work" "$work" --chdir "$work" \
    "$goroot/bin/go" test -count=1 -v -overlay /overlay.json -run '^TestFixture' ./dues > "$tmp/out" 2>&1 < /dev/null
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
