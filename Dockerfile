FROM nixos/nix:latest

# Enable flakes
RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

WORKDIR /workspace

# Copy flake files first for better caching
COPY flake.nix flake.lock* ./

# Copy the rest of the configuration
COPY . .

# Default command shows available builds
CMD ["nix", "flake", "show"]
