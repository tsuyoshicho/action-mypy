#!/bin/bash

# - Exit with error on any failed command.
# - Any unset variable is an immediate error.
# - Show trace executed statements
# - Show the executed script before executing it.
set -euxv

# shellcheck disable=SC2086,SC2089,SC2090

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

# check setup method
SETUP="false"
case "${INPUT_SETUP_METHOD}" in
  "nothing")
    SETUP="false"
    ;;
  "install")
    SETUP="true"
    ;;
  *)
    # adaptive and other invalid value
    # Check execute_command is valid.
    echo '::group:: Check command is executable'
    echo "Execute command with version option: ${INPUT_EXECUTE_COMMAND} --version"
    if ${INPUT_EXECUTE_COMMAND} --version > /dev/null 2>&1 ; then
      echo 'Success command execution, skip installation.'
      SETUP="false"
    else
      echo 'Failure command execution, execute installation.'
      SETUP="true"
    fi
    echo '::endgroup::'
    ;;
esac

# Install mypy if needed.
if [[ "${SETUP}" == "true" ]] ; then
  echo '::group:: Installing mypy ...  https://github.com/python/mypy'
  echo "Execute setup: ${INPUT_SETUP_COMMAND}"
  ${INPUT_SETUP_COMMAND}
  echo '::endgroup::'
fi

echo '::group:: Prepare reviewdog/mypy'
# Version output.
echo "Execute command and version: ${INPUT_EXECUTE_COMMAND}"
${INPUT_EXECUTE_COMMAND} --version

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# safe extract files/dirs
TARGETS_LIST="${INPUT_TARGET:-.}"
echo '::endgroup::'

# pre-run(missing stub detect)
if [[ "${INPUT_INSTALL_TYPES}" == "true" ]] ; then
  echo '::group:: Installing types'
  echo 'Pre-run and detect missing stubs'
  # shellcheck disable=SC2086
  mypy_check_output="$(${INPUT_EXECUTE_COMMAND}   \
                            ${TARGETS_LIST} 2>&1  \
                            )" || mypy_exit_val="$?"
  # discard result
  echo 'Install types'
  ${INPUT_EXECUTE_COMMAND} --install-types --non-interactive
  echo '::endgroup::'
fi

echo '::group:: Running mypy with reviewdog 🐶 ...'
mypy_exit_val="0"
reviewdog_exit_val="0"

# Below from this line, errors are handled.
# (mypy_exit_val and reviewdog_exit_val)
# Disable error report
set +e

# lint check
# Flags
#   first, user flags
#   second, set reviewdog supplement flags(abspath, column num) and suppress pretty flag
# same flag: win later
# --hide-error-context : suppress error context NOTE: entry
# shellcheck disable=SC2086
mypy_check_output="$(${INPUT_EXECUTE_COMMAND}   \
                          ${INPUT_MYPY_FLAGS}   \
                          --output json         \
                          --hide-error-context  \
                          --show-column-numbers \
                          --show-absolute-path  \
                          --no-pretty           \
                          ${TARGETS_LIST} 2>&1  \
                          )" || mypy_exit_val="$?"

# shellcheck disable=SC2086
echo "${mypy_check_output}" |                        \
      python ./mypy_to_rdjson/mypy_to_rdjson.py |    \
      reviewdog                                      \
      -f=rdjson                                      \
      -name="${INPUT_TOOL_NAME:-mypy}"               \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}"            \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}"        \
      -level="${INPUT_LEVEL}"                        \
      ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"
echo '::endgroup::'

# Throw error if an error occurred and fail_on_error is true
if [[ "${INPUT_FAIL_ON_ERROR}" == "true"       \
      && ( "${mypy_exit_val}" != "0"           \
           || "${reviewdog_exit_val}" != "0" ) \
   ]]; then
  exit 1
fi
