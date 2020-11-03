FROM python:slim AS builder
ADD . /docs
WORKDIR /docs
RUN apt-get update \
    && apt-get install --no-install-recommends -y make \
    && python3 -m pip install --no-cache-dir -U pip \
    && python3 -m pip install --no-cache-dir Sphinx==3.3.0 \
    && make html BUILDDIR=/build

FROM nginx:alpine
COPY --from=builder /build/html /usr/share/nginx/html
