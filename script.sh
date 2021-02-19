#!/bin/bash

cd "${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}" || exit

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo '::group:: Installing tflint ... https://github.com/terraform-linters/tflint'
curl -sfL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh > install_tflint_linux.sh
chmod +x install_tflint_linux.sh
TFLINT_VERSION="${INPUT_TFLINT_VERSION}" ./install_tflint_linux.sh
rm install_tflint_linux.sh
echo '::endgroup::'


export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

echo '::group:: Running tflint with reviewdog 🐶 ...'
# shellcheck disable=SC2086
tflint --format=checkstyle ${INPUT_FLAGS} . \
  | reviewdog -f=checkstyle -name="tflint" -reporter="${INPUT_REPORTER}" -level="${INPUT_LEVEL}" -fail-on-error="${INPUT_FAIL_ON_ERROR}" -filter-mode="${INPUT_FILTER_MODE}"

tflint_return="${PIPESTATUS[0]}" reviewdog_return="${PIPESTATUS[1]}" exit_code=$?
echo ::set-output name=tflint-return-code::"${tflint_return}"
echo ::set-output name=reviewdog-return-code::"${reviewdog_return}"
echo '::endgroup::'

exit $exit_code
