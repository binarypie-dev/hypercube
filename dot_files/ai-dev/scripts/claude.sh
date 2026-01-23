#!/usr/bin/bash
set -euo pipefail

IMAGE="${AI_DEV_IMAGE:-ghcr.io/binarypie-dev/ai-dev:latest}"

mkdir -p "$HOME/.claude"
touch "$HOME/.claude.json"

exec podman run --rm -it --init \
    --user 0:0 \
    --security-opt label=disable \
    -e HOME="$HOME" \
    -v "$(pwd):$(pwd):rw" \
    -v "$HOME/.claude:$HOME/.claude:rw" \
    -v "$HOME/.claude.json:$HOME/.claude.json:rw" \
    -w "$(pwd)" \
    "$IMAGE" \
    claude "$@"
