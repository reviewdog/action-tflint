#!/bin/bash

cd "${GITHUB_WORKSPACE}/${INPUT_WORKING_DIRECTORY}"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# shellcheck disable=SC2086
tflint --format=checkstyle ${INPUT_FLAGS} . \
  | reviewdog -f=checkstyle -name="tflint" -reporter="${INPUT_REPORTER}" -level="${INPUT_LEVEL}"

tflint_return="${PIPESTATUS[0]}" reviewdog_return="${PIPESTATUS[1]}" exit_code=$?

echo ::set-output name=tflint-return-code::"${tflint_return}"
echo ::set-output name=reviewdog-return-code::"${reviewdog_return}"

exit $exit_code
