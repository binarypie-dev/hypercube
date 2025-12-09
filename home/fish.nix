{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # VIM Mode
      fish_vi_key_bindings

      # Prompt settings (hydro)
      set --global hydro_multiline true
      set --global fish_prompt_pwd_dir_length 100
      set --global hydro_color_pwd $fish_color_comment
      set --global hydro_color_git $fish_color_operator
      set --global hydro_color_error $fish_color_error
      set --global hydro_color_prompt $fish_color_command
      set --global hydro_color_duration $fish_color_param

      # Modern CLI aliases
      alias ls 'eza --icons'
      alias ll 'eza -la --icons --git'
      alias tree 'eza --tree --icons'
      alias cat 'bat'
      alias grep 'rg'
      alias find 'fd'
      alias top 'btop'
      alias du 'duf'
      alias df 'duf'
      alias ps 'procs'

      # Kubernetes aliases
      alias k 'kubectl'
      alias kx 'kubectx'
      alias kn 'kubens'
      alias kgp 'kubectl get pods'
      alias kgs 'kubectl get svc'
      alias kgd 'kubectl get deployments'
      alias kl 'kubectl logs -f'
      alias ke 'kubectl exec -it'

      # Git aliases
      alias g 'git'
      alias ga 'git add'
      alias gc 'git commit'
      alias gp 'git push'
      alias gl 'git pull'
      alias gst 'git status'
      alias gd 'git diff'
      alias gco 'git checkout'
      alias gb 'git branch'
      alias lg 'lazygit'

      # Docker/Container aliases
      alias d 'docker'
      alias dc 'docker compose'
      alias ld 'lazydocker'

      # Terraform aliases
      alias tf 'terraform'
      alias tfi 'terraform init'
      alias tfp 'terraform plan'
      alias tfa 'terraform apply'

      # Init zoxide
      zoxide init fish | source

      # Init direnv
      direnv hook fish | source

      # Init atuin for shell history
      atuin init fish | source
    '';

    plugins = [
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];
  };
}
