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
**mypy report multiline error, but now, multiline error cannot be handled in one unit.**
**It handles the error line by line.**
see [Issue](https://github.com/tsuyoshicho/action-mypy/issues/38).

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
      Target file or directory of mypy command.
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
    required: false
    default: 'pip install mypy'
  setup_method:
    description: |
      mypy setup method. Select from below.
      "adaptive" - Check "execute_command" with "--version" is executable.
      If it can be executed, do the same as "nothing", otherwise do the same as "install".
      "nothing" - no setup process.
      This option expects the user to prepare the environment
      (ex. previous workflow step executed "pip install -r requirements.txt").
      "install" - execute "setup_command".

      Incorrect values behave as "adaptive".
    required: false
    default: 'adaptive'
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
  fail_on_error:
    description: |
      Exit code for reviewdog when errors are found [true,false]
      Default is `false`.
    required: false
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
      Ignore note entry.
      mypy report some error with optional note entry.
      This option is workaround.
    default: 'false'
```

### Input note

`mypy_flags` is used for workflow setting. (eg '--strict --strict-equality').

But when this flag as set, ignore and do not affect setup.cfg or other mypy's settings file parameters.

Use this flag when you want to check a workflow that is different from the project settings.

## Usage

```yaml
name: reviewdog
on: [pull_request]
jobs:
  mypy:
    name: runner / mypy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: tsuyoshicho/action-mypy@v3
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
      - uses: actions/checkout@v2
      - uses: tsuyoshicho/action-mypy@v3
        with:
          github_token: ${{ secrets.github_token }}
          reporter: github-pr-review
          level: warning
          workdir: src
          execute_command: 'poetry run mypy'
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

This reviewdog action mypy itself is integrated with reviewdog to run lints
which is useful for Docker container based actions.

![reviewdog integration](https://user-images.githubusercontent.com/3797062/72735107-7fbb9600-3bde-11ea-8087-12af76e7ee6f.png)

### Dependencies Update Automation
This repository uses [haya14busa/action-depup](https://github.com/haya14busa/action-depup) to update
reviewdog version.

[![reviewdog depup demo](https://user-images.githubusercontent.com/3797062/73154254-170e7500-411a-11ea-8211-912e9de7c936.png)](https://github.com/reviewdog/action-template/pull/6)
