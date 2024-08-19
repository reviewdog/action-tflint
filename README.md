# GitHub Action: Run tflint with reviewdog

[![Test](https://github.com/reviewdog/action-tflint/workflows/Test/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/reviewdog/action-tflint/workflows/reviewdog/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3Areviewdog)
[![release](https://github.com/reviewdog/action-tflint/workflows/release/badge.svg)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/reviewdog/action-tflint?logo=github&sort=semver)](https://github.com/reviewdog/action-tflint/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)
[![depup](https://github.com/reviewdogaction-tflint/workflows/depup/badge.svg?branch=master&event=push)](https://github.com/reviewdog/action-tflint/actions?query=workflow%3Adepup+event%3Apush+branch%3Amaster)

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

### `filter_mode`

Optional. Filtering for the reviewdog command [`added`,`diff_context`,`file`,`nofilter`].

The default is `added`.

See [reviewdog documentation for filter mode](https://github.com/reviewdog/reviewdog/tree/master#filter-mode) for details.

### `fail_on_error`

Optional. Exit code for reviewdog when errors are found [`true`,`false`].

The default is `false`.

See [reviewdog documentation for exit codes](https://github.com/reviewdog/reviewdog/tree/master#exit-codes) for details.

### `working_directory`

Optional. Directory to run the action on, from the repo root.
The default is `.` ( root of the repository).

### `tflint_version`

Optional. The tflint version to install and use.
The default is `latest`.

### `tflint_rulesets`

Optional. Space separated, official (from the terraform-linters GitHub organization) tflint rulesets to install and use. If a pre-configured `TFLINT_PLUGIN_DIR` is set, rulesets are installed in that directory.
Default is `` (empty).

### `tflint_init`

Optional. Whether to run `tflint --init` prior to linting (useful if you have a .tflint.hcl with some values in it).
The default is `false`.

### `tflint_target_dir`

Optional. The target dir for the tflint command. This is the directory passed to tflint as opposed to working_directory which is the directory the command is executed from.
The default is `.`.

### `tflint_config`

Optional. Config file name for tflint.
The default is `.tflint.hcl`

### `flags`

Optional. List of arguments to send to `tflint`.
For the output to be parsable by reviewdog [`--format=checkstyle` is enforced](./entrypoint.sh).
The default is `--call-module-type=all`.

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
        uses: actions/checkout@v4

      # Install latest Terraform manually as
      #  Docker-based GitHub Actions are
      #  slow due to lack of caching
      # Note: Terraform is not needed for tflint
      - name: Install Terraform
        run: |
          brew install terraform

      # Run init to get module code to be able to use `--call-module-type=all`
      - name: Terraform init
        run: |
          terraform init

      # Minimal example
      - name: tflint
        uses: reviewdog/action-tflint@v1
        with:
          github_token: ${{ secrets.github_token }}

      # More complex example
      - name: tflint
        uses: reviewdog/action-tflint@v1
        with:
          github_token: ${{ secrets.github_token }}
          working_directory: "testdata" # Optional. Change working directory
          reporter: github-pr-review # Optional. Change reporter
          fail_on_error: "true" # Optional. Fail action if errors are found
          filter_mode: "nofilter" # Optional. Check all files, not just the diff
          tflint_version: "v0.24.0" # Optional. Custom version, instead of latest
          tflint_rulesets: "azurerm google" # Optional. Extra official rulesets to install
          flags: "--call-module-type=all" # Optional. Add custom tflint flags
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
