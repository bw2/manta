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
    libncurses5-dev \
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

# samtools/htslib with Google Cloud Storage support, for slicing gs:// CRAMs before running Manta on the slice.
# This is separate from the htslib 1.9 that Manta bundles and links statically (built with --disable-libcurl).
ENV SAMTOOLS_VERSION="1.21"
RUN wget -q https://github.com/samtools/htslib/releases/download/${SAMTOOLS_VERSION}/htslib-${SAMTOOLS_VERSION}.tar.bz2 \
    && tar xjf htslib-${SAMTOOLS_VERSION}.tar.bz2 \
    && rm htslib-${SAMTOOLS_VERSION}.tar.bz2 \
    && cd htslib-${SAMTOOLS_VERSION} \
    && ./configure --enable-gcs \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -r htslib-${SAMTOOLS_VERSION}

RUN wget -q https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && tar xjf samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && rm samtools-${SAMTOOLS_VERSION}.tar.bz2 \
    && cd samtools-${SAMTOOLS_VERSION} \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -r samtools-${SAMTOOLS_VERSION}

# install gcloud (used to mint the GCS_OAUTH_TOKEN that htslib needs to read gs:// paths)
ENV GCLOUD_SDK_VERSION="512.0.0"
RUN wget -q https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && tar xzf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && rm google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz \
    && /google-cloud-sdk/install.sh -q

ENV PATH=/google-cloud-sdk/bin:$PATH

COPY CMakeLists.txt configure /manta-src/
COPY redist /manta-src/redist
COPY src /manta-src/src

# Bind-mount the host .git (read-only, BuildKit-only, never baked into an image layer) so that cmake's
# `git describe` call (src/cmake/getBuildTimeConfigInfo.cmake) can embed the real version, e.g. 1.6.0-4-gabcdef12,
# instead of falling back to "UNKNOWN". The bind-mounted .git keeps the host user's UID while this RUN executes
# as root, which trips git's "dubious ownership" check unless it's told to trust it.
# Manta builds and runs its C++ unit tests as part of `make`, so a failing unit test fails the image build.
# /manta-src is left in place: it is already in the COPY layers above, so deleting it would not shrink the image.
RUN --mount=type=bind,source=.git,target=/manta-src/.git,ro \
    git config --global --add safe.directory '*' \
    && mkdir /manta-build \
    && cd /manta-build \
    && /manta-src/configure --jobs=$(nproc) --prefix=/opt/manta \
    && make -j$(nproc) install \
    && cd / \
    && rm -r /manta-build

ENV PATH=/opt/manta/bin:$PATH
