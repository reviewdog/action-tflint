FROM alpine:3.11

ENV REVIEWDOG_VERSION=v0.9.17

# hadolint ignore=DL3018
RUN apk --no-cache --update add bash git \
    && rm -rf /var/cache/apk/*

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

RUN wget -O - -q $(wget -q https://api.github.com/repos/terraform-linters/tflint/releases/latest -O - | grep -o -E "https://.+?_linux_amd64.zip") > tflint.zip \
    && unzip tflint.zip && rm tflint.zip \
    && install tflint /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
