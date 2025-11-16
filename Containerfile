# This build argument allows building different variants (regular vs NVIDIA)
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin-dx:stable-daily

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Build Elephant from source (cached layer)
FROM ${BASE_IMAGE} AS elephant-builder
COPY packages/elephant/build.sh /tmp/build-elephant.sh
RUN --mount=type=cache,dst=/var/cache \
  --mount=type=cache,dst=/var/log \
  --mount=type=tmpfs,dst=/tmp/build \
  chmod +x /tmp/build-elephant.sh && \
  /tmp/build-elephant.sh

# Build Walker from source (cached layer)
FROM ${BASE_IMAGE} AS walker-builder
COPY packages/walker/build.sh /tmp/build-walker.sh
RUN --mount=type=cache,dst=/var/cache \
  --mount=type=cache,dst=/var/log \
  --mount=type=tmpfs,dst=/tmp/build \
  chmod +x /tmp/build-walker.sh && \
  /tmp/build-walker.sh

# Base Image
FROM ${BASE_IMAGE}

# Copy Elephant binary and service from builder
COPY --from=elephant-builder /usr/bin/elephant /usr/bin/elephant
COPY --from=elephant-builder /usr/lib/systemd/user/elephant.service /usr/lib/systemd/user/elephant.service

# Copy Walker binary and resources from builder
COPY --from=walker-builder /usr/bin/walker /usr/bin/walker
COPY --from=walker-builder /usr/share/walker /usr/share/walker

# Copy dot_files into the image at /usr/share/hypercube/config
COPY dot_files /usr/share/hypercube/config

# Ensure all config files are readable by everyone
RUN chmod -R a+rX /usr/share/hypercube/config

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-dx-nvidia:stable-daily
#
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
  --mount=type=cache,dst=/var/cache \
  --mount=type=cache,dst=/var/log \
  --mount=type=tmpfs,dst=/tmp \
  /ctx/build.sh && \
  ostree container commit

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
