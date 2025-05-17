#!/bin/bash

# - Exit with error on any failed command.
# - Any unset variable is an immediate error.
# - Show trace executed statements
# - Show the executed script before executing it.
set -euxv

BASE_PATH="$(cd "$(dirname "$0")" && pwd)"

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
                            )" || _mypy_exit_val="$?"
  # discard result
  echo 'Install types'
  ${INPUT_EXECUTE_COMMAND} --install-types --non-interactive
  echo '::endgroup::'
fi


# cleanup function
cleanup() {
  if [ -n "${MYPYTMPDIR:-}" ] && [ -d "${MYPYTMPDIR:-}" ]; then
    rm -rf "$MYPYTMPDIR"
  fi
}

MYPYTMPDIR=$(mktemp -d)
trap cleanup EXIT

echo '::group:: Running mypy with reviewdog 🐶 ...'
_mypy_exit_val="0"
reviewdog_exit_val="0"

# Below from this line, errors are handled.
# (_mypy_exit_val and reviewdog_exit_val)
# Disable error report
set +e

# lint check
# Flags
#   first, user flags
#   second, set reviewdog supplement flags(abspath, column num) and suppress pretty flag
# same flag: win later

fail_level="${INPUT_FAIL_LEVEL}"
if [[ "${INPUT_FAIL_LEVEL}" == "none" ]] && [[ "${INPUT_FAIL_ON_ERROR}" == "true" ]]; then
  fail_level="error"
fi

echo "report level is: ${INPUT_LEVEL}"
echo "fail level is: ${fail_level}"

if [[ "${INPUT_OUTPUT_JSON}" != "true" ]] ; then
  # Do not use JSON output

  # shellcheck disable=SC2086
  mypy_check_output="$(${INPUT_EXECUTE_COMMAND}   \
                            ${INPUT_MYPY_FLAGS}   \
                            --show-column-numbers \
                            --show-absolute-path  \
                            --no-pretty           \
                            ${TARGETS_LIST} 2>&1  \
                            )" || _mypy_exit_val="$?"

  # note ignore
  IGNORE_NOTE_EFM_OPTION=("-efm=%-G%f:%l:%c: note: %m")

  # shellcheck disable=SC2086
  echo "${mypy_check_output}" | reviewdog              \
        "${IGNORE_NOTE_EFM_OPTION[@]}"                 \
        -efm="%f:%l:%c: %t%*[^:]: %m"                  \
        -efm="%f:%l: %t%*[^:]: %m"                     \
        -efm="%f: %t%*[^:]: %m"                        \
        -name="${INPUT_TOOL_NAME:-mypy}"               \
        -reporter="${INPUT_REPORTER:-github-pr-check}" \
        -filter-mode="${INPUT_FILTER_MODE}"            \
        -fail-level="${fail_level}"                    \
        -level="${INPUT_LEVEL}"                        \
        ${INPUT_REVIEWDOG_FLAGS} || reviewdog_exit_val="$?"

else
  # Use JSON output
  # require mypy==1.11 or higher

  # --hide-error-context : suppress error context NOTE: entry
  # shellcheck disable=SC2086
  ${INPUT_EXECUTE_COMMAND}           \
    ${INPUT_MYPY_FLAGS}              \
    --output json                    \
    --hide-error-context             \
    --show-column-numbers            \
    --show-absolute-path             \
    --no-pretty                      \
    ${TARGETS_LIST}                  \
    > ${MYPYTMPDIR}/mypy_output.json \
    2> /dev/null                     \
    || _mypy_exit_val="$?"

  # echo "mypy output result:"
  # cat "${MYPYTMPDIR}/mypy_output.json"

  python3 "${BASE_PATH}/mypy_to_rdjson/mypy_to_rdjson.py" < "${MYPYTMPDIR}/mypy_output.json" > "${MYPYTMPDIR}/mypy_rdjson.json"

  # echo "mypy output rdjson:"
  # cat "${MYPYTMPDIR}/mypy_rdjson.json"

  # shellcheck disable=SC2086
  reviewdog                                                     \
    -f=rdjson                                                   \
    -name="${INPUT_TOOL_NAME:-mypy}"                            \
    -reporter="${INPUT_REPORTER:-github-pr-check}"              \
    -filter-mode="${INPUT_FILTER_MODE}"                         \
    -fail-level="${fail_level}"                                 \
    -level="${INPUT_LEVEL}"                                     \
    ${INPUT_REVIEWDOG_FLAGS} < "${MYPYTMPDIR}/mypy_rdjson.json" \
    || reviewdog_exit_val="$?"
fi

echo '::endgroup::'

# Throw error if an error occurred and fail_on_error is true
# mypy exit code : 0 no type error, 1 has type error
# ignore it
if [[ "${reviewdog_exit_val}" != "0" ]]; then
  exit 1
fi
