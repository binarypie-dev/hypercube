# vim: set ft=make :
# Hypercube AI development environment commands

ai_image := "ghcr.io/binarypie-dev/ai-dev:latest"
ai_podman_flags := "--rm -it --user 0:0 --security-opt label=disable"

# Run Claude Code in the current directory
ai-claude *args:
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p "$HOME/.claude" "$HOME/.config/claude"
    exec podman run {{ai_podman_flags}} \
        -e HOME="$HOME" \
        -v "$(pwd):$(pwd):rw" \
        -v "$HOME/.claude:$HOME/.claude:rw" \
        -v "$HOME/.config/claude:$HOME/.config/claude:rw" \
        -w "$(pwd)" \
        {{ai_image}} \
        claude {{args}}

# Run Gemini CLI in the current directory
ai-gemini *args:
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p "$HOME/.gemini"
    env_flags=""
    for var in $(env | grep -E '^(GOOGLE_|GEMINI_)' | cut -d= -f1); do
        env_flags="$env_flags -e $var"
    done
    exec podman run {{ai_podman_flags}} \
        -e HOME="$HOME" \
        $env_flags \
        -v "$(pwd):$(pwd):rw" \
        -v "$HOME/.gemini:$HOME/.gemini:rw" \
        -w "$(pwd)" \
        {{ai_image}} \
        gemini {{args}}

# Enter the ai-dev container interactively
ai-dev:
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p "$HOME/.claude" "$HOME/.config/claude" "$HOME/.gemini"
    env_flags=""
    for var in $(env | grep -E '^(GOOGLE_|GEMINI_|ANTHROPIC_)' | cut -d= -f1); do
        env_flags="$env_flags -e $var"
    done
    exec podman run {{ai_podman_flags}} \
        -e HOME="$HOME" \
        $env_flags \
        -v "$(pwd):$(pwd):rw" \
        -v "$HOME/.claude:$HOME/.claude:rw" \
        -v "$HOME/.config/claude:$HOME/.config/claude:rw" \
        -v "$HOME/.gemini:$HOME/.gemini:rw" \
        -w "$(pwd)" \
        {{ai_image}}

# Install claude and gemini wrapper scripts to ~/.local/bin
ai-setup:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Pulling ai-dev image..."
    podman pull {{ai_image}}

    mkdir -p "$HOME/.local/bin"

    cat > "$HOME/.local/bin/claude" << 'WRAPPER'
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p "$HOME/.claude" "$HOME/.config/claude"
    exec podman run --rm -it \
        --user 0:0 \
        --security-opt label=disable \
        -e HOME="$HOME" \
        -v "$(pwd):$(pwd):rw" \
        -v "$HOME/.claude:$HOME/.claude:rw" \
        -v "$HOME/.config/claude:$HOME/.config/claude:rw" \
        -w "$(pwd)" \
        ghcr.io/binarypie-dev/ai-dev:latest \
        claude "$@"
    WRAPPER
    chmod +x "$HOME/.local/bin/claude"

    cat > "$HOME/.local/bin/gemini" << 'WRAPPER'
    #!/usr/bin/bash
    set -euo pipefail
    mkdir -p "$HOME/.gemini"
    env_flags=""
    for var in $(env | grep -E '^(GOOGLE_|GEMINI_)' | cut -d= -f1); do
        env_flags="$env_flags -e $var"
    done
    exec podman run --rm -it \
        --user 0:0 \
        --security-opt label=disable \
        -e HOME="$HOME" \
        $env_flags \
        -v "$(pwd):$(pwd):rw" \
        -v "$HOME/.gemini:$HOME/.gemini:rw" \
        -w "$(pwd)" \
        ghcr.io/binarypie-dev/ai-dev:latest \
        gemini "$@"
    WRAPPER
    chmod +x "$HOME/.local/bin/gemini"

    echo ""
    echo "Setup complete! You can now run 'claude' and 'gemini' directly."

# Upgrade ai-dev to latest image
ai-upgrade:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Pulling latest ai-dev image..."
    podman pull {{ai_image}}
    echo "Done! Latest image pulled."
