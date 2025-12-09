{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Kubernetes
    kubectl
    kubectx
    k9s
    kubernetes-helm
    stern
    kustomize
    kubeseal
    argocd
    fluxcd

    # Container tools
    lazydocker
    dive
    ctop
    skopeo
    buildah

    # Infrastructure
    terraform
    opentofu

    # Cloud CLIs
    awscli2
    google-cloud-sdk
    azure-cli

    # Development
    gitui
    gh
    pre-commit
    tokei
    hyperfine
    just

    # Modern CLI tools
    eza
    bat
    delta
    zoxide
    fzf
    starship
    atuin
    direnv
    navi

    # Network/API
    httpie
    curlie
    xh
    grpcurl

    # Data/JSON
    jq
    yq-go
    fx
    gron

    # Monitoring/Logs
    htop
    btop
    procs
    duf
    ncdu
    bandwhich
    gping

    # Core CLI
    ripgrep
    fd
    tree

    # Security
    age
    sops
    trivy
    cosign

    # Misc
    tldr
    glow
    slides
    vhs
    charm-freeze
  ];
}
