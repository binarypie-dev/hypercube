#!/usr/bin/bash
set -e

export PATH="/home/linuxbrew/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/linuxbrew/.npm-global/bin:/home/linuxbrew/go/bin:/home/linuxbrew/.cargo/bin:$PATH"

# Debug mode: print environment and auth state
if [ "$1" = "--ai-dev-debug" ]; then
    echo "=== ai-dev debug ==="
    echo "uid=$(id -u) gid=$(id -g) user=$(whoami 2>/dev/null || echo unknown)"
    echo "HOME=$HOME"
    echo "PATH=$PATH"
    echo ""
    echo "=== TTY ==="
    ls -la /dev/pts/ 2>/dev/null || echo "no /dev/pts"
    echo "tty: $(tty 2>/dev/null || echo 'not a tty')"
    echo ""
    echo "=== env (GOOGLE_/GEMINI_/ANTHROPIC_) ==="
    env | grep -E "^(GOOGLE_|GEMINI_|ANTHROPIC_)" || echo "(none set)"
    echo ""
    echo "=== $HOME/.gemini/ ==="
    ls -la "$HOME/.gemini/" 2>/dev/null || echo "not found at $HOME/.gemini/"
    echo ""
    echo "=== $HOME/.claude/ ==="
    ls -la "$HOME/.claude/" 2>/dev/null || echo "not found at $HOME/.claude/"
    echo ""
    echo "=== $HOME/.config/claude/ ==="
    ls -la "$HOME/.config/claude/" 2>/dev/null || echo "not found at $HOME/.config/claude/"
    echo ""
    echo "=== which claude/gemini ==="
    which claude 2>/dev/null || echo "claude: not found"
    which gemini 2>/dev/null || echo "gemini: not found"
    echo ""
    echo "=== node os.homedir() ==="
    node -e "console.log(require(\"os\").homedir())" 2>/dev/null || echo "node not available"
    exit 0
fi

if [ $# -eq 0 ]; then
    exec bash
else
    exec "$@"
fi
