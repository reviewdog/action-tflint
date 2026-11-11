#!/bin/bash
set -euo pipefail

# Exercise the reporting portion of the action without downloads or GitHub writes.
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/tflint" "$test_dir/reviewdog"
sed -n '/^echo '\''::group:: Running tflint/,$p' "$repo_root/script.sh" > "$test_dir/report.sh"
cat > "$test_dir/tflint/tflint" <<'EOF'
#!/bin/bash
echo '<checkstyle version="4.3"></checkstyle>'
exit "$TEST_TFLINT_STATUS"
EOF
cat > "$test_dir/reviewdog/reviewdog" <<'EOF'
#!/bin/bash
cat > /dev/null
exit "$TEST_REVIEWDOG_STATUS"
EOF
chmod +x "$test_dir/tflint/tflint" "$test_dir/reviewdog/reviewdog"

export TFLINT_PATH="$test_dir/tflint" REVIEWDOG_PATH="$test_dir/reviewdog"
export TFLINT_PLUGIN_DIR="$test_dir/plugins" GITHUB_OUTPUT="$test_dir/output"
export INPUT_GITHUB_TOKEN='' INPUT_TFLINT_TARGET_DIR='.' INPUT_TFLINT_CONFIG='.tflint.hcl'
export INPUT_FLAGS='' INPUT_REPORTER='github-check' INPUT_LEVEL='error'
export INPUT_FAIL_LEVEL='none' INPUT_FAIL_ON_ERROR='false' INPUT_FILTER_MODE='nofilter'

check_status() {
  export TEST_TFLINT_STATUS="$1" TEST_REVIEWDOG_STATUS="$2"
  : > "$GITHUB_OUTPUT"
  local actual=0
  bash "$test_dir/report.sh" > /dev/null || actual=$?
  if [[ "$actual" -ne "$3" ]]; then
    echo "tflint=$1 reviewdog=$2: expected $3, got $actual" >&2
    exit 1
  fi
  grep -qx "tflint-return-code=$1" "$GITHUB_OUTPUT"
  grep -qx "reviewdog-return-code=$2" "$GITHUB_OUTPUT"
}

check_status 0 0 0
check_status 2 0 0
check_status 2 1 1
check_status 0 1 1
check_status 1 0 1
check_status 1 1 1
check_status 127 0 127
echo 'Exit-code cases passed'
