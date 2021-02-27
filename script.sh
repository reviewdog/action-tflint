#!/bin/bash

cd "${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}" || exit

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo '::group:: Installing tflint ... https://github.com/terraform-linters/tflint'
curl -sfL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | TFLINT_VERSION="${INPUT_TFLINT_VERSION}" bash
echo '::endgroup::'

export TFLINT_PLUGIN_DIR="${TEMP_PATH}/.tflint.d/plugins"
for RULESET in ${INPUT_TFLINT_RULESETS}; do
  PLUGIN="tflint-ruleset-${RULESET}"
  REPOSITORY="https://github.com/terraform-linters/${PLUGIN}"

  echo "::group:: Installing tflint plugin for ${RULESET} ... ${REPOSITORY}"
  mkdir -p "${TFLINT_PLUGIN_DIR}"
  curl -sfL "${REPOSITORY}"/releases/latest/download/"${PLUGIN}"_"$(uname | sed 's/Darwin/darwin/; s/Linux/linux/')"_"$(uname -m | sed 's/x86_/amd/; s/aarch64/arm/')".zip -o "${PLUGIN}".zip && unzip "${PLUGIN}".zip -d "${TFLINT_PLUGIN_DIR}" && rm "${PLUGIN}".zip
  echo '::endgroup::'
done

echo "::group:: Print tflint version details"
tflint --version
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
