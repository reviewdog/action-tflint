#!/bin/bash

# Fail fast on errors, unset variables, and failures in piped commands
set -Eeuo pipefail

cd "${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}" || exit

echo '::group::Preparing'
  unameOS="$(uname -s)"
  case "${unameOS}" in
    Linux*)     os=linux;;
    Darwin*)    os=darwin;;
    CYGWIN*)    os=windows;;
    MINGW*)     os=windows;;
    MSYS_NT*)   os=windows;;
    *)          echo "Unknown system: ${unameOS}" && exit 1
  esac

  unameArch="$(uname -m)"
  case "${unameArch}" in
    x86*)      arch=amd64;;
    aarch64*)  arch=arm;;
    *)         echo "Unsupported architecture: ${unameArch}" && exit 1
  esac

  TEMP_PATH="$(mktemp -d)"
  echo "Detected ${os} running on ${arch}, will install tools in ${TEMP_PATH}"
  REVIEWDOG_PATH="${TEMP_PATH}/reviewdog"
  TFLINT_PATH="${TEMP_PATH}/tflint"

  if [[ -z "${INPUT_TFLINT_VERSION}" ]] || [[ "${INPUT_TFLINT_VERSION}" == "latest" ]]; then
    echo "Looking up the latest tflint version ..."
    tflint_version=$(curl --silent --show-error --fail --location "https://api.github.com/repos/terraform-linters/tflint/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  else
    tflint_version=${INPUT_TFLINT_VERSION}
  fi

  if [[ -z "${TFLINT_PLUGIN_DIR:-}" ]]; then
    export TFLINT_PLUGIN_DIR="${TFLINT_PATH}/.tflint.d/plugins"
    mkdir -p "${TFLINT_PLUGIN_DIR}"
  else
    echo "Found pre-configured TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR}"
  fi
echo '::endgroup::'

echo "::group::🐶 Installing reviewdog (${REVIEWDOG_VERSION}) ... https://github.com/reviewdog/reviewdog"
  curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${REVIEWDOG_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo "::group:: Installing tflint (${tflint_version}) ... https://github.com/terraform-linters/tflint"
  curl --silent --show-error --fail \
    --location "https://github.com/terraform-linters/tflint/releases/download/${tflint_version}/tflint_${os}_${arch}.zip" \
    --output "${TEMP_PATH}/tflint.zip"

  unzip -u "${TEMP_PATH}/tflint.zip" -d "${TEMP_PATH}/temp-tflint"
  test ! -d "${TFLINT_PATH}" && install -d "${TFLINT_PATH}"
  install "${TEMP_PATH}/temp-tflint/tflint" "${TFLINT_PATH}"
  rm -rf "${TEMP_PATH}/tflint.zip" "${TEMP_PATH}/temp-tflint"
echo '::endgroup::'

for RULESET in ${INPUT_TFLINT_RULESETS}; do
  PLUGIN="tflint-ruleset-${RULESET}"
  REPOSITORY="https://github.com/terraform-linters/${PLUGIN}"

  echo "::group:: Installing tflint plugin for ${RULESET} (latest) ... ${REPOSITORY}"
    curl --silent --show-error --fail \
      --location "${REPOSITORY}"/releases/latest/download/"${PLUGIN}"_"${os}"_"${arch}".zip \
      --output "${PLUGIN}".zip \
    && unzip "${PLUGIN}".zip -d "${TFLINT_PLUGIN_DIR}" && rm "${PLUGIN}".zip
  echo '::endgroup::'
done

echo "::group:: Print tflint details ..."
  "${TFLINT_PATH}/tflint" --version
echo '::endgroup::'


echo '::group:: Running tflint with reviewdog 🐶 ...'
  export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

  # Allow failures now, as reviewdog handles them
  set +Eeuo pipefail

  # shellcheck disable=SC2086
  TFLINT_PLUGIN_DIR=${TFLINT_PLUGIN_DIR} "${TFLINT_PATH}/tflint" --format=checkstyle ${INPUT_FLAGS} . \
    | "${REVIEWDOG_PATH}/reviewdog" -f=checkstyle \
        -name="tflint" \
        -reporter="${INPUT_REPORTER}" \
        -level="${INPUT_LEVEL}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -filter-mode="${INPUT_FILTER_MODE}"

  tflint_return="${PIPESTATUS[0]}" reviewdog_return="${PIPESTATUS[1]}" exit_code=$?
  echo "::set-output name=tflint-return-code::${tflint_return}"
  echo "::set-output name=reviewdog-return-code::${reviewdog_return}"
echo '::endgroup::'

exit "${exit_code}"
