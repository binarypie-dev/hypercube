# vim: set ft=make :
# Hypercube AI development environment commands

ai_scripts := "/usr/share/hypercube/config/ai-dev/scripts"

# Run Claude Code in the current directory
ai-claude *args:
    {{ai_scripts}}/claude.sh {{args}}

# Run Gemini CLI in the current directory
ai-gemini *args:
    {{ai_scripts}}/gemini.sh {{args}}

# Enter the ai-dev container interactively
ai-dev:
    {{ai_scripts}}/enter.sh

# Install claude and gemini wrapper scripts to ~/.local/bin
ai-setup:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Pulling ai-dev image..."
    podman pull ghcr.io/binarypie-dev/ai-dev:latest
    mkdir -p "$HOME/.local/bin"
    cp {{ai_scripts}}/claude.sh "$HOME/.local/bin/claude"
    cp {{ai_scripts}}/gemini.sh "$HOME/.local/bin/gemini"
    chmod +x "$HOME/.local/bin/claude" "$HOME/.local/bin/gemini"
    echo ""
    echo "Setup complete! You can now run 'claude' and 'gemini' directly."

# Upgrade ai-dev to latest image
ai-upgrade:
    #!/usr/bin/bash
    set -euo pipefail
    echo "Pulling latest ai-dev image..."
    podman pull ghcr.io/binarypie-dev/ai-dev:latest
    echo "Done! Latest image pulled."
