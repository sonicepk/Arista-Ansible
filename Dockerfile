# Copyright (c) 2018 Arista Networks, Inc.  All rights reserved.
# Arista Networks, Inc. Confidential and Proprietary.

FROM golang:1.11.4-alpine3.8 as build
LABEL maintainer="Giuseppe Valente gvalente@arista.com"

ENV CFSSLVERSION 1.3.2

RUN apk add git gcc libc-dev \
    && wget https://github.com/cloudflare/cfssl/archive/${CFSSLVERSION}.tar.gz \
    && echo "aba27a282c8ca8e95769996aea7e5300b0c3f8fea7ae26484d19a7e1a0330f0b3a0649407062f1a10e8c93136693954e3b24c92456f69db3abee509f982ba554  ${CFSSLVERSION}.tar.gz" | sha512sum -c - \
    && tar xvf ${CFSSLVERSION}.tar.gz \
    && mkdir -p /go/src/github.com/cloudflare \
    && mv cfssl-${CFSSLVERSION} /go/src/github.com/cloudflare/cfssl \
    && go install github.com/cloudflare/cfssl/cmd/...

FROM aristanetworks/base:2.0
LABEL maintainer="Giuseppe Valente gvalente@arista.com"

# TODO: Remove cryptography version pinning
# See https://github.com/paramiko/paramiko/issues/1369#issuecomment-456940895
RUN apk add \
    bash \
    git \
    libffi \
    libpq \
    libressl \
    openssh-client \
    py3-pip \
    python3 \
    util-linux \
  && apk add --virtual build-dependencies \
    gcc \
    libffi-dev \
    make \
    musl-dev \
    libressl-dev \
    postgresql-dev \
    python3-dev \
  && pip3 install --upgrade pip \
  && pip3 install \
    cryptography==2.4.2 \
    ansible==2.8.1 \
    apache-libcloud \
    netaddr \
    openshift \
    passlib \
    psycopg2 \
    PyYAML \
  && apk del build-dependencies \
  && ln -s /usr/bin/python3 /usr/bin/python

# Install helm and helm-tiller plugin
ENV HELM_VERSION 2.12.0-k8sauthpatch
ENV HELM_HOME /home/prod/.helm
RUN cd /tmp \
  && wget -nv https://github.com/asetty/helm/releases/download/v2.12.0-k8sauthpatch/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
  && echo "8a3251fa569655499642ee1ce7dfd39215de3d255b88241ac377905c969aedb9 helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    | sha256sum - \
  && tar xvf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
  && cp linux-amd64/helm /usr/bin/helm \
  && cp linux-amd64/tiller /usr/bin/tiller \
  && rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64 \
  && mkdir -p ${HELM_HOME}/plugins \
  && helm plugin install https://github.com/rimusz/helm-tiller \
  && helm init --client-only \
  && helm repo update \
  && helm tiller install \
  && chmod -R a+w /home/prod/.helm

# Install kubectl
RUN wget -nv https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/linux/amd64/kubectl \
  	-O /usr/bin/kubectl \
  && echo "8e94e8bafdcd919a183143d6f3364b75278e277d  /usr/bin/kubectl" | sha1sum -c - \
  && chmod +x /usr/bin/kubectl

# Install cfssl binaries
COPY --from=0 /go/bin/cfssl /usr/bin
COPY --from=0 /go/bin/cfssl-bundle /usr/bin
COPY --from=0 /go/bin/cfssl-certinfo /usr/bin
COPY --from=0 /go/bin/cfssl-newkey /usr/bin
COPY --from=0 /go/bin/cfssl-scan /usr/bin
COPY --from=0 /go/bin/cfssljson /usr/bin
COPY --from=0 /go/bin/mkbundle /usr/bin
COPY --from=0 /go/bin/multirootca /usr/bin

ENV GCLOUD_VERSION 246.0.0
ENV PATH $PATH:/usr/lib/google-cloud-sdk/bin

# Install gcloud
RUN wget -nv https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
    -O google-cloud-sdk.tar.gz \
  && echo "832567cbd0046fd6c80f55196c5c2a8ee3a0f1e1e2587b4a386232bd13abc45b  google-cloud-sdk.tar.gz" | sha256sum - \
  && tar xvf google-cloud-sdk.tar.gz -C /usr/lib \
  && rm google-cloud-sdk.tar.gz \
  && gcloud config set disable_usage_reporting true \
  && gcloud components install --quiet alpha beta

# Patch #79 for kubernetes-client https://github.com/kubernetes-client/python-base/pull/79.diff
# https://github.com/kubernetes-client/python-base/pull/79/commits/529a72a2bf4901d40e7551c4acaf8219609dcfb9.diff
# Removed the changes to config/kube_config_test.py since they do not patch cleanly and are not required.
#COPY kubernetes-client-79.diff /tmp/79.diff
#RUN cd $(python -c 'import kubernetes.config, inspect, re; print(re.sub(r"/kubernetes/config/.*", "/kubernetes/", inspect.getfile(kubernetes.config)))') \
#&& patch -p1 < /tmp/79.diff
