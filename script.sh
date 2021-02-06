#!/bin/sh

# shellcheck disable=SC2086,SC2089,SC2090

cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit

TEMP_PATH="$(mktemp -d)"
PATH="${TEMP_PATH}:$PATH"

echo '::group::🐶 Installing reviewdog ... https://github.com/reviewdog/reviewdog'
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}" 2>&1
echo '::endgroup::'

echo '::group:: Installing mypy ...  https://github.com/python/mypy'
if type "mypy" > /dev/null 2>&1 ; then
  echo 'already installed'
else
  echo 'install mypy'
  pip install mypy
fi

if type "mypy" > /dev/null 2>&1 ; then
  mypy --version
else
  echo 'This repository was not configured for mypy, process done.'
  exit 1
fi
echo '::endgroup::'

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"


echo '::group:: Running mypy with reviewdog 🐶 ...'
# shellcheck disable=SC2086
mypy                                                              \
    --show-column-numbers                                         \
    --show-absolute-path                                          \
    ${INPUT_MYPY_FLAGS}                                           \
    "${INPUT_TARGET:-.}"                                          \
  | reviewdog                                                     \
      -efm="%f:%l:%c: %t%*[^:]: %m"                               \
      -name="mypy"                                                \
      -reporter="${INPUT_REPORTER:-github-pr-check}"              \
      -filter-mode="${INPUT_FILTER_MODE}"                         \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}"                     \
      -level="${INPUT_LEVEL}"                                     \
      ${INPUT_REVIEWDOG_FLAGS}
echo '::endgroup::'

