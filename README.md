# action-mypy

[![Test](https://github.com/tsuyoshicho/action-mypy/workflows/Test/badge.svg)](https://github.com/tsuyoshicho/action-mypy/actions?query=workflow%3ATest)
[![reviewdog](https://github.com/tsuyoshicho/action-mypy/workflows/reviewdog/badge.svg)](https://github.com/tsuyoshicho/action-mypy/actions?query=workflow%3Areviewdog)
[![depup](https://github.com/tsuyoshicho/action-mypy/workflows/depup/badge.svg)](https://github.com/tsuyoshicho/action-mypy/actions?query=workflow%3Adepup)
[![release](https://github.com/tsuyoshicho/action-mypy/workflows/release/badge.svg)](https://github.com/tsuyoshicho/action-mypy/actions?query=workflow%3Arelease)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/tsuyoshicho/action-mypy?logo=github&sort=semver)](https://github.com/tsuyoshicho/action-mypy/releases)
[![action-bumpr supported](https://img.shields.io/badge/bumpr-supported-ff69b4?logo=github&link=https://github.com/haya14busa/action-bumpr)](https://github.com/haya14busa/action-bumpr)

![github-pr-review demo](https://user-images.githubusercontent.com/96727/101124511-93c38700-363a-11eb-9a3c-899e7052e60b.png)
![github-pr-check demo](https://user-images.githubusercontent.com/96727/101124474-83131100-363a-11eb-990f-0824dc13f3e1.png)

This is a action-mypy repository for [reviewdog](https://github.com/reviewdog/reviewdog) action with release automation.

**Limitation**:
**mypy report multiline error, but now, multiline error may be handled under JSON output is enabled.**

Notice:
This action is `composition action`.

You accept below one:

- Your workflow manually setup to run `pip install -r requirements.txt` or other setup method.
- This action automatic run `pip install mypy`.

## Input

```yaml
inputs:
  github_token:
    description: 'GITHUB_TOKEN'
    required: false
    default: '${{ github.token }}'
  workdir:
    description: |
      Working directory of where to run mypy command.
      Relative to the root directory.
    required: false
    default: '.'
  target:
    description: |
      Target files and/or directories of mypy command.
      Enumerate in a space-separated list.
      Relative to the working directory.
    required: false
    default: '.'
  ### Flags for setup/execute ###
  execute_command:
    description: |
      mypy execute command.
      Normally it is "mypy", but for example "poetry run mypy"
      if you want to run at Poetry without activating the virtual environment.
    required: false
    default: 'mypy'
  setup_command:
    description: |
      mypy setup command.
      Runs when "setup_method" is "install" or required by "adaptive".
      If you want to fix the version of mypy, set the value as in the following example.
      "pip install mypy==1.6.0"
    required: false
    default: 'pip install mypy'
  setup_method:
    description: |
      mypy setup method. Select from below.
      "nothing" - no setup process.
      This option expects the user to prepare the environment
      (ex. previous workflow step executed "pip install -r requirements.txt").
      If you do not want immediately package installation (e.g., in a poetry environment), must be this.
      "adaptive" - Check "execute_command" with "--version" is executable.
      If it can be executed, do the same as "nothing", otherwise do the same as "install".
      "install" - execute "setup_command".

      Incorrect values behave as "adaptive".
    required: false
    default: 'nothing'
  install_types:
    description: |
      Pre-run mypy and check for missing stubs.
      Then perform stub installation.
      (ex. ${execute_command} --install-types)
    required: false
    default: 'true'
  ### Flags for reviewdog ###
  level:
    description: 'Report level for reviewdog [info,warning,error]'
    required: false
    default: 'error'
  reporter:
    description: 'Reporter of reviewdog command [github-pr-check,github-pr-review].'
    required: false
    default: 'github-pr-check'
  filter_mode:
    description: |
      Filtering mode for the reviewdog command [added,diff_context,file,nofilter].
      Default is added.
    required: false
    default: 'added'
  fail_level:
    description: |
      Optional.  Exit code control for reviewdog, [none,any,info,warning,error]
      Default is `none`.
    default: 'none'
  fail_on_error:
    description: |
      Deprecated.

      Optional.  Exit code for reviewdog when errors are found [true,false]
      Default is `false`.

      If `true` is set, it will be interpreted as "-fail-level=error".
      But if "-fail-level" is set non-`none`, it will be ignored.
    default: 'false'
  reviewdog_flags:
    description: 'Additional reviewdog flags'
    required: false
    default: ''
  ### Flags for mypy ###
  mypy_flags:
    description: 'mypy options (default: <none>)'
    required: false
    default: ''
  tool_name:
    description: 'Tool name to use for reviewdog reporter'
    default: 'mypy'
  ignore_note:
    description: |
      Currently, this option is always true.
      Ignore "note: entries" that as reported by mypy.

      Old description:
      Ignore note entry.
      mypy report some error with optional note entry.
      This option is workaround.
    required: false
    default: 'true'
  output_json:
    description: |
      Use the JSON output format available in mypy 1.11 or higher.

      This option defaults to false due to version limitations
      and because it is still experimental.
      Note the mypy version when setting to true.
    required: false
    default: 'false'
```

### Input note

`mypy_flags` is used for workflow setting. (eg '--strict --strict-equality').

Currently always suppress note.

## Usage

```yaml
name: reviewdog
on: [pull_request]
jobs:
  mypy:
    name: runner / mypy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: tsuyoshicho/action-mypy@v4
        with:
          github_token: ${{ secrets.github_token }}
          # Change reviewdog reporter if you need [github-pr-check,github-check,github-pr-review].
          reporter: github-pr-review
          # Change reporter level if you need.
          # GitHub Status Check won't become failure with warning.
          level: warning
          # Change the current directory to run mypy command.
          # mypy command reads setup.cfg or other settings file in this path.
          workdir: src
```

### Using with Poetry

If you use mypy with [Poetry](https://github.com/python-poetry/poetry), you can use it with the following settings (`poetry shell` do not work in GitHub workflow, see [issue 66](https://github.com/tsuyoshicho/action-mypy/issues/66)).

Example setting:

```yaml
name: reviewdog
on: [pull_request]
jobs:
  mypy:
    name: runner / mypy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: tsuyoshicho/action-mypy@v4
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review
          level: warning
          workdir: src
          execute_command: 'poetry run mypy'
```

### Debug output

You can set the "-tee" [flag](https://github.com/reviewdog/reviewdog#debugging) in the `reviewdog_flags` to log the process.

## Development

### Release

#### [haya14busa/action-bumpr](https://github.com/haya14busa/action-bumpr)

You can bump version on merging Pull Requests with specific labels (bump:major,bump:minor,bump:patch).
Pushing tag manually by yourself also work.

#### [haya14busa/action-update-semver](https://github.com/haya14busa/action-update-semver)

This action updates major/minor release tags on a tag push. e.g. Update v1 and v1.2 tag when released v1.2.3.
ref: https://help.github.com/en/articles/about-actions#versioning-your-action

### Lint - reviewdog integration

This reviewdog action mypy itself is integrated with reviewdog to run lints
which is useful for Docker container based actions.

![reviewdog integration](https://user-images.githubusercontent.com/3797062/72735107-7fbb9600-3bde-11ea-8087-12af76e7ee6f.png)

### Dependencies Update Automation

This repository uses [haya14busa/action-depup](https://github.com/haya14busa/action-depup) to update
reviewdog version.

[![reviewdog depup demo](https://user-images.githubusercontent.com/3797062/73154254-170e7500-411a-11ea-8211-912e9de7c936.png)](https://github.com/reviewdog/action-template/pull/6)
