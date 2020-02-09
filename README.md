# GitHub Action: Run tflint with reviewdog

[![Test](https://github.com/reviewdog/action-tflint/workflows/Test/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/reviewdog/action-tflint/workflows/reviewdog/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/reviewdog/action-tflint/workflows/depup/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3Adepup)
[![release](https://github.com/reviewdog/action-tflint/workflows/release/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/reviewdog/action-tflint?logo=github&sort=semver)](https://github.com/reviewdog/action-tflint/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

This action runs [tflint](https://github.com/wata727/tflint) with
[reviewdog](https://github.com/reviewdog/reviewdog) on pull requests
to enforce best practices.

## Examples

### With `github-pr-check`

By default, with `reporter: github-pr-check` an annotation is added to
the line:

![Example comment made by the action, with github-pr-check](./example-github-pr-check.png)

### With `github-pr-review`

With `reporter: github-pr-review` a comment is added to
the Pull Request Conversation:

![Example comment made by the action, with github-pr-review](./example-github-pr-review.png)

## Inputs

### `github_token`

**Required**. Must be in form of `github_token: ${{ secrets.github_token }}`.

### `level`

Optional. Report level for reviewdog [`info`,`warning`,`error`].
It's same as `-level` flag of reviewdog.
The default is `error`.

### `reporter`

Optional. Reporter of reviewdog command [`github-pr-check`,`github-pr-review`].
The default is `github-pr-check`.

### `working_directory`

Optional. Directory to run the action on, from the repo root.
The default is `.` ( root of the repository).

### `flags`

Optional. List of arguments to send to tflint.
For the output to be parsable by reviewdog [`--format=checkstyle` is enforced](./entrypoint.sh).
The default is `--module`.

## Outputs

## `tflint-return-code`

The `tflint` command return code.

## `reviewdog-return-code`

The `reviewdog` command return code.

## Example usage

```yml
name: reviewdog
on: [pull_request]
jobs:
  tflint:
    name: runner / tflint
    runs-on: ubuntu-latest

    steps:
      - name: Clone repo
        uses: actions/checkout@master

      # Install latest Terraform manually as
      #  Docker-based GitHub Actions are
      #  slow due to lack of caching
      - name: Install Terraform
        run: |
          curl -LO https://raw.github.com/robertpeteuil/terraform-installer/master/terraform-install.sh
          chmod +x terraform-install.sh
          ./terraform-install.sh -a

      - name: Terraform init
        run: |
          terraform init

      - name: tflint
        uses: reviewdog/action-tflint@master
        with:
          github_token: ${{ secrets.github_token }}
          working_directory: "testdata" # Change working directory
          reporter: github-pr-review # Change reporter
          flags: "--deep" # Add custom flags
```

## Development

### Release

#### [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr)
You can bump version on merging Pull Requests with specific labels (bump:major,bump:minor,bump:patch).
Pushing tag manually by yourself also work.

#### [haya14busa/action-update-semver](https://github.com/haya14busa/action-update-semver)

This action updates major/minor release tags on a tag push. e.g. Update v1 and v1.2 tag when released v1.2.3.
ref: https://help.github.com/en/articles/about-actions#versioning-your-action

### Lint - reviewdog integration

This reviewdog action template itself is integrated with reviewdog to run lints
which is useful for Docker container based actions.

Supported linters:

- [reviewdog/action-shellcheck](https://github.com/reviewdog/action-shellcheck)
- [reviewdog/action-hadolint](https://github.com/reviewdog/action-hadolint)
- [reviewdog/action-misspell](https://github.com/reviewdog/action-misspell)

### Dependencies Update Automation
This repository uses [haya14busa/action-depup](https://github.com/haya14busa/action-depup) to update
reviewdog version.
