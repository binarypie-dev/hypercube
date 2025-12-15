# Hypercube Container Build
# Aligned with Bluefin patterns

# ============================================
# Build Arguments
# ============================================
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin-dx:stable-daily
ARG IMAGE_NAME=hypercube
ARG IMAGE_VENDOR=binarypie-dev
ARG SHA_HEAD_SHORT=""

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
FROM ${BASE_IMAGE}

# Re-declare ARGs after FROM (they don't persist across stages)
ARG IMAGE_NAME
ARG IMAGE_VENDOR
ARG SHA_HEAD_SHORT

# Export build-time environment variables
ENV IMAGE_NAME=${IMAGE_NAME}
ENV IMAGE_VENDOR=${IMAGE_VENDOR}

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
