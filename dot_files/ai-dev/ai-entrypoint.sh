#!/usr/bin/bash
set -e

# Fix root's home directory in /etc/passwd to match host $HOME
# This ensures os.homedir() in Node.js (used by claude/gemini) returns the correct path
if [ -n "$HOME" ] && [ "$HOME" != "/root" ]; then
    sed -i "s|root:x:0:0:[^:]*:/root:|root:x:0:0:root:$HOME:|" /etc/passwd 2>/dev/null || true
fi

# Symlink claude install paths to where the native installer expects them at runtime
# (installed under /home/linuxbrew at build time, but $HOME differs at runtime)
if [ -n "$HOME" ] && [ "$HOME" != "/home/linuxbrew" ]; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
    ln -sf /home/linuxbrew/.local/bin/claude "$HOME/.local/bin/claude" 2>/dev/null || true
    ln -sf /home/linuxbrew/.local/share/claude "$HOME/.local/share/claude" 2>/dev/null || true
fi

# Ensure claude auth files are readable within the container
chmod -R a+rX "$HOME/.claude" 2>/dev/null || true
chmod a+rw "$HOME/.claude.json" 2>/dev/null || true

export PATH="$HOME/.local/bin:/home/linuxbrew/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/linuxbrew/.npm-global/bin:/home/linuxbrew/go/bin:/home/linuxbrew/.cargo/bin:$PATH"

# Debug mode: print environment and auth state
if [ "$1" = "--ai-dev-debug" ]; then
    echo "=== ai-dev debug ==="
    echo "uid=$(id -u) gid=$(id -g) user=$(whoami 2>/dev/null || echo unknown)"
    echo "HOME=$HOME"
    echo "PATH=$PATH"
    echo ""
    echo "=== /etc/passwd root entry ==="
    grep "^root:" /etc/passwd
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
