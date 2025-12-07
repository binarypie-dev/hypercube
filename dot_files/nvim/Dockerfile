# Neovim Development Environment
# Layered for optimal build caching
FROM fedora:43

# =============================================================================
# LAYER 1: System packages (changes rarely)
# =============================================================================
RUN dnf update -y && dnf install -y \
    # Build essentials
    gcc \
    gcc-c++ \
    make \
    cmake \
    automake \
    autoconf \
    libtool \
    # Required for Homebrew and general development
    git \
    curl \
    wget \
    unzip \
    zip \
    tar \
    gzip \
    xz \
    bzip2 \
    # Libraries needed by various tools
    openssl-devel \
    readline-devel \
    zlib-devel \
    libffi-devel \
    ncurses-devel \
    sqlite-devel \
    bzip2-devel \
    xz-devel \
    # Terminal and shell
    procps-ng \
    findutils \
    which \
    file \
    # For clipboard support
    xclip \
    xsel \
    # For Neovim
    gettext \
    # Sudo for Homebrew
    sudo \
    # For proper locale support
    langpacks-en \
    glibc-langpack-en \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# =============================================================================
# LAYER 2: User setup (changes rarely)
# =============================================================================
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ARG USERNAME=nvim
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# =============================================================================
# LAYER 3: Homebrew installation (changes rarely)
# =============================================================================
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1

# =============================================================================
# LAYER 4: Homebrew core packages - Neovim & languages (changes occasionally)
# =============================================================================
RUN brew install \
    neovim \
    go \
    python@3.12 \
    node \
    ruby \
    lua \
    luarocks

# =============================================================================
# LAYER 5: Homebrew CLI tools (changes occasionally)
# =============================================================================
RUN brew install \
    # Search and find
    ripgrep \
    fd \
    fzf \
    # Tree-sitter
    tree-sitter \
    # Git tools
    lazygit \
    gh \
    # Formatters
    stylua \
    prettier \
    shfmt \
    # Linters
    shellcheck \
    hadolint \
    # Shells
    fish \
    # Other utilities
    jq \
    yq \
    bat \
    eza \
    delta \
    # Image processing
    imagemagick \
    ghostscript \
    # LaTeX
    tectonic

# =============================================================================
# LAYER 6: Homebrew infrastructure tools (changes occasionally)
# =============================================================================
RUN brew install \
    terraform \
    tflint \
    helm \
    sqlfluff \
    lua-language-server

# =============================================================================
# LAYER 7: Rust toolchain (changes occasionally)
# =============================================================================
RUN brew install rustup-init \
    && rustup-init -y --default-toolchain stable

ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

RUN . "$HOME/.cargo/env" && \
    rustup component add rustfmt clippy rust-analyzer

# =============================================================================
# LAYER 8: Go tools (changes occasionally)
# =============================================================================
ENV GOPATH="/home/${USERNAME}/go"
ENV PATH="${GOPATH}/bin:${PATH}"

RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install mvdan.cc/gofumpt@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# =============================================================================
# LAYER 9: Python tools (changes occasionally)
# =============================================================================
RUN pip3 install --user --break-system-packages \
    pynvim \
    ruff \
    black \
    isort \
    debugpy

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# =============================================================================
# LAYER 10: Node.js/npm tools (changes occasionally)
# =============================================================================
# Note: prettier is installed via Homebrew, not npm (avoids conflict)
RUN npm install -g \
    neovim \
    typescript \
    typescript-language-server \
    @vtsls/language-server \
    eslint \
    eslint_d \
    @eslint/config-array \
    bash-language-server \
    dockerfile-language-server-nodejs \
    yaml-language-server \
    markdownlint-cli2 \
    markdown-toc \
    @tailwindcss/language-server \
    pyright \
    tree-sitter-cli \
    @mermaid-js/mermaid-cli

# =============================================================================
# LAYER 11: Directory setup & environment (changes rarely)
# =============================================================================
RUN mkdir -p /home/${USERNAME}/.config/nvim \
    && mkdir -p /home/${USERNAME}/.local/share/nvim \
    && mkdir -p /home/${USERNAME}/.local/state/nvim \
    && mkdir -p /home/${USERNAME}/.cache/nvim \
    && mkdir -p /home/${USERNAME}/workspace

# Install Ghostty terminfo for terminal compatibility
RUN curl -fsSL https://raw.githubusercontent.com/ghostty-org/ghostty/main/src/terminfo/ghostty.terminfo \
    | tic -x -o ~/.terminfo -

# =============================================================================
# LAYER 12: Pre-install treesitter parsers (changes rarely)
# =============================================================================
RUN nvim --headless \
    -c "TSInstallSync bash c diff dockerfile fish git_config git_rebase gitattributes gitcommit gitignore go gomod gosum gowork hcl helm html javascript jsdoc json jsonc lua luadoc luap markdown markdown_inline printf python query regex ron rust sql terraform toml tsx typescript vim vimdoc xml yaml" \
    -c "qall"

# Create OSC52 clipboard init (loaded before user config)
RUN echo "vim.g.clipboard = { \
  name = 'OSC 52', \
  copy = { \
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'), \
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'), \
  }, \
  paste = { \
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'), \
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'), \
  }, \
}" > /home/${USERNAME}/.config/nvim-clipboard.lua

ENV EDITOR=nvim
ENV VISUAL=nvim
ENV TERM=xterm-256color

WORKDIR /home/${USERNAME}/workspace

ENTRYPOINT ["nvim", "--cmd", "luafile /home/nvim/.config/nvim-clipboard.lua"]
