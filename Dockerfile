FROM python:3.9.0-alpine

ENV REVIEWDOG_VERSION=v0.11.0

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3006
RUN apk --no-cache add git

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b /usr/local/bin/ ${REVIEWDOG_VERSION}

COPY requirements.txt /requirements.txt

# hadolint ignore=DL3006,DL3018,DL3013
RUN apk add --no-cache --virtual .build-deps gcc musl-dev \
 && pip install cython \
 && pip install -r requirements.txt --default-timeout=100 future \
 && apk del .build-deps

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
