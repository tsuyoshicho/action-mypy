#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

echo "[action-mypy] mypy version:"
mypy --version

echo "[action-mypy] reviewdog version:"
reviewdog --version

echo "[action-mypy] mypy and reviewdog output:"
# shellcheck disable=SC2086
mypy \
    --show-column-numbers \
    --show-absolute-path \
    ${INPUT_MYPY_FLAGS} \
    "${INPUT_TARGET:-.}" \
  | reviewdog                                                     \
      -efm="%f:%l:%c: %t%*[^:]: %m"                               \
      -name="mypy"                                                \
      -reporter="${INPUT_REPORTER:-github-pr-check}"              \
      -filter-mode="${INPUT_FILTER_MODE}"                         \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}"                     \
      -level="${INPUT_LEVEL}"                                     \
      ${INPUT_REVIEWDOG_FLAGS}
