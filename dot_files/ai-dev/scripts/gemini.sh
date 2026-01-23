#!/usr/bin/bash
set -euo pipefail

IMAGE="${AI_DEV_IMAGE:-ghcr.io/binarypie-dev/ai-dev:latest}"

mkdir -p "$HOME/.gemini"

env_flags=""
for var in $(env | grep -E '^(GOOGLE_|GEMINI_)' | cut -d= -f1); do
    env_flags="$env_flags -e $var"
done

exec podman run --rm -it --init \
    --user 0:0 \
    --security-opt label=disable \
    -e HOME="$HOME" \
    $env_flags \
    -v "$(pwd):$(pwd):rw" \
    -v "$HOME/.gemini:$HOME/.gemini:rw" \
    -w "$(pwd)" \
    "$IMAGE" \
    gemini "$@"
