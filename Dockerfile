FROM python:slim AS builder

ARG WORKSHOP_SERVER="<workshop server>"
ARG WORKSHOP_CHECK_SERVER="localhost"

ADD . /docs
WORKDIR /docs
RUN apt-get update \
    && apt-get install --no-install-recommends -y make \
    && python3 -m pip install --no-cache-dir -U pip \
    && python3 -m pip install --no-cache-dir Sphinx==3.3.0 \
    && export WORKSHOP_SERVER="${WORKSHOP_SERVER}" \
              WORKSHOP_CHECK_SERVER="${WORKSHOP_CHECK_SERVER}" \
              ANSIBLE_DAY2_GIT_URL="${ANSIBLE_DAY2_GIT_URL}" \
    && sed -i -e "s/{WORKSHOP_SERVER}/${WORKSHOP_SERVER}/g" \
              -e "s/{WORKSHOP_CHECK_SERVER}/${WORKSHOP_CHECK_SERVER}/g" \
              -e "s/{ANSIBLE_DAY2_GIT_URL}/${ANSIBLE_DAY2_GIT_URL}/g" \
              _static/* \
    && make html BUILDDIR=/build

FROM nginx:alpine
COPY --from=builder /build/html /usr/share/nginx/html

ADD docker/nginx-default.conf /etc/nginx/conf.d/default.conf
