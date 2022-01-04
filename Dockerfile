FROM python:3.10-slim AS builder

ARG WORKSHOP_SERVER="<workshop server>"
ARG WORKSHOP_IDE_SERVER="<workshop IDE>"
ARG WORKSHOP_CHECK_SERVER="localhost"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        build-essential \
        libjpeg-dev \
        libxml2-dev \
        libxslt1-dev \
        make \
        zlib1g-dev \
    && python3 -m pip install --no-cache-dir -U pip

ADD . /docs
WORKDIR /docs

RUN python3 -m pip install --no-cache-dir --prefer-binary -r /docs/requirements.txt

RUN export WORKSHOP_SERVER="${WORKSHOP_SERVER}" \
              WORKSHOP_IDE_SERVER="${WORKSHOP_IDE_SERVER}" \
              WORKSHOP_CHECK_SERVER="${WORKSHOP_CHECK_SERVER}" \
              ANSIBLE_DAY2_GIT_URL="${ANSIBLE_DAY2_GIT_URL}" \
    && sed -i -e "s/{WORKSHOP_SERVER}/${WORKSHOP_SERVER}/g" \
              -e "s/{WORKSHOP_IDE_SERVER}/${WORKSHOP_IDE_SERVER}/g" \
              -e "s/{WORKSHOP_CHECK_SERVER}/${WORKSHOP_CHECK_SERVER}/g" \
              -e "s/{ANSIBLE_DAY2_GIT_URL}/${ANSIBLE_DAY2_GIT_URL}/g" \
              _static/* \
    && make html BUILDDIR=/build



FROM nginx:alpine
EXPOSE 80
COPY --from=builder /build/html /usr/share/nginx/html

ADD docker/nginx-default.conf /etc/nginx/conf.d/default.conf
