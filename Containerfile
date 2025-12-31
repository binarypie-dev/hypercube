# Hypercube Container Build
# Built from ublue-os/base-main with NVIDIA support included
# Single unified image for all hardware configurations

# ============================================
# Build Arguments
# ============================================
ARG FEDORA_VERSION="43"
ARG IMAGE_NAME=hypercube
ARG IMAGE_VENDOR=binarypie-dev
ARG SHA_HEAD_SHORT=""
ARG AKMODS_FLAVOR="coreos-stable"

# ============================================
# Stage 1: Context Aggregation
# ============================================
# Aggregate all build context into a single layer for mounting
FROM scratch AS ctx
COPY system_files /system_files
COPY build_files /build_files

# ============================================
# Stage 2: Main Build
# ============================================
FROM ghcr.io/ublue-os/base-main:${FEDORA_VERSION}

# Re-declare ARGs after FROM (they don't persist across stages)
ARG IMAGE_NAME
ARG IMAGE_VENDOR
ARG SHA_HEAD_SHORT
ARG FEDORA_VERSION
ARG AKMODS_FLAVOR

# Export build-time environment variables
ENV IMAGE_NAME=${IMAGE_NAME}
ENV IMAGE_VENDOR=${IMAGE_VENDOR}
ENV FEDORA_VERSION=${FEDORA_VERSION}
ENV AKMODS_FLAVOR=${AKMODS_FLAVOR}

# Copy dot_files (config templates) into the image
COPY dot_files /usr/share/hypercube/config

# Ensure all config files are readable by everyone
RUN chmod -R a+rX /usr/share/hypercube/config

# Build with mounted context and caches
# - Bind mount from ctx stage for build scripts and system files
# - Cache mounts for DNF and rpm-ostree to speed up rebuilds
# - Tmpfs for /tmp to avoid polluting the image
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/cache/rpm-ostree \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_files/shared/build.sh && \
    ostree container commit

# Final validation
RUN bootc container lint
