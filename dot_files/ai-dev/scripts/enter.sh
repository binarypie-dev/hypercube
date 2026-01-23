#!/usr/bin/bash
set -euo pipefail

IMAGE="${AI_DEV_IMAGE:-ghcr.io/binarypie-dev/ai-dev:latest}"

mkdir -p "$HOME/.claude" "$HOME/.gemini"
touch "$HOME/.claude.json"

env_flags=""
for var in $(env | grep -E '^(GOOGLE_|GEMINI_|ANTHROPIC_)' | cut -d= -f1); do
    env_flags="$env_flags -e $var"
done

exec podman run --rm -it --init \
    --user 0:0 \
    --security-opt label=disable \
    -e HOME="$HOME" \
    $env_flags \
    -v "$(pwd):$(pwd):rw" \
    -v "$HOME/.claude:$HOME/.claude:rw" \
    -v "$HOME/.claude.json:$HOME/.claude.json:rw" \
    -v "$HOME/.gemini:$HOME/.gemini:rw" \
    -w "$(pwd)" \
    "$IMAGE" \
    "$@"
