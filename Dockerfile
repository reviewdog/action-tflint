FROM alpine:3.11

RUN apk --no-cache --update add git curl \
    && rm -rf /var/cache/apk/*

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /usr/local/bin/

RUN curl -L "$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep -o -E "https://.+?_linux_amd64.zip")" > tflint.zip \
    && unzip tflint.zip && rm tflint.zip \
    && install tflint /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
