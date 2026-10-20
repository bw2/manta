# syntax=docker/dockerfile:1
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/bw2/manta"
LABEL org.opencontainers.image.licenses="GPL-3.0-only"

# Manta's workflow scripts (configManta.py, runWorkflow.py and the bundled pyflow) run only under Python 2.
# Ubuntu 22.04 is the last Ubuntu release that still ships a python2 package.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates \
    build-essential \
    cmake \
    git \
    python2 \
    bzip2 \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libboost-chrono-dev \
    libboost-date-time-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-regex-dev \
    libboost-serialization-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-timer-dev \
    wget \
    curl \
    procps \
    time \
    && rm -rf /var/lib/apt/lists/*

# install gcloud (used to mint the GCS_OAUTH_TOKEN that htslib needs to read non-public gs:// paths)
ENV GCLOUD_SDK_VERSION="512.0.0"
RUN wget -q https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && tar xzf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && rm google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && /google-cloud-sdk/install.sh -q

ENV PATH=/google-cloud-sdk/bin:$PATH

COPY scratch/make_release_tarball.bash /manta-src/scratch/make_release_tarball.bash

# Build Manta the way Illumina built its releases: scratch/make_release_tarball.bash runs `git archive` on the
# committed HEAD, records the `git describe` version (e.g. 1.6.0-4-gabcdef12), and sets DEVELOPER_MODE to false.
# Building straight from a git checkout leaves DEVELOPER_MODE on, which turns every compiler warning into an error.
# Because the source comes from `git archive HEAD`, uncommitted changes in the build context are not included.
#
# The host .git is bind-mounted read-only (BuildKit-only, never baked into an image layer). It keeps the host
# user's UID while this RUN executes as root, which trips git's "dubious ownership" check unless it's told to trust it.
#
# Ubuntu 22.04's boost 1.74 has a header bug: boost/serialization/set.hpp uses library_version_type without
# including the header that defines it (fixed in later boost releases). Force-including that header works around it.
#
# Manta builds and runs its C++ unit tests as part of `make`, so a failing unit test fails the image build.
RUN --mount=type=bind,source=.git,target=/manta-src/.git,ro \
    git config --global --add safe.directory '*' \
    && mkdir /manta-release \
    && cd /manta-release \
    && bash /manta-src/scratch/make_release_tarball.bash \
    && tar xjf manta-*.release_src.tar.bz2 \
    && mkdir build \
    && cd build \
    && CXXFLAGS="-include boost/serialization/library_version_type.hpp" \
        ../manta-*.release_src/configure --jobs=$(nproc) --prefix=/opt/manta \
    && make -j$(nproc) install \
    && cd / \
    && rm -r /manta-release

# Manta's bundled htslib/samtools 1.21 are built with libcurl, so they read gs://, s3:// and http(s):// URLs.
# Put them on the PATH, e.g. for slicing a gs:// CRAM with samtools before running Manta on the slice.
RUN ln -s /opt/manta/libexec/samtools /opt/manta/libexec/htsfile /opt/manta/libexec/bgzip /opt/manta/libexec/tabix \
    /usr/local/bin/

ENV PATH=/opt/manta/bin:$PATH
