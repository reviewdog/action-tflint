#!/bin/sh

cd "$GITHUB_WORKSPACE"

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

tflint ${INPUT_ARGS} \
  | reviewdog -f=checkstyle -name="tflint" -reporter=github-pr-review -level="${INPUT_LEVEL}"
