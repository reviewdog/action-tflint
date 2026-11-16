#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/tflint" "$test_dir/reviewdog"
sed -n '/^echo '\''::group:: Running tflint/,$p' "$repo_root/script.sh" > "$test_dir/report.sh"
cat > "$test_dir/tflint/tflint" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$TEST_ARGS"
echo '<checkstyle version="4.3"></checkstyle>'
EOF
cat > "$test_dir/reviewdog/reviewdog" <<'EOF'
#!/bin/bash
cat > /dev/null
EOF
chmod +x "$test_dir/tflint/tflint" "$test_dir/reviewdog/reviewdog"

export TFLINT_PATH="$test_dir/tflint" REVIEWDOG_PATH="$test_dir/reviewdog"
export TFLINT_PLUGIN_DIR="$test_dir/plugins" GITHUB_OUTPUT="$test_dir/output"
export TEST_ARGS="$test_dir/args"
export INPUT_GITHUB_TOKEN='' INPUT_TFLINT_TARGET_DIR='.' INPUT_TFLINT_CONFIG='.tflint.hcl'
export INPUT_REPORTER='github-check' INPUT_LEVEL='error'
export INPUT_FAIL_LEVEL='none' INPUT_FAIL_ON_ERROR='false' INPUT_FILTER_MODE='nofilter'

for INPUT_FLAGS in '' '--format=json' '--format compact --call-module-type=all'; do
  export INPUT_FLAGS
  bash "$test_dir/report.sh" > /dev/null
  # The last format option wins in TFLint; it must always be checkstyle.
  [[ "$(tail -n 1 "$TEST_ARGS")" == '--format=checkstyle' ]]
done
echo 'Format cases passed'
