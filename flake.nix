{
  description = "Fabbem Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.neovim
          pkgs.vim
          pkgs.alacritty
          pkgs.aerospace
          pkgs.mkalias
          pkgs.python3
          pkgs.discord
          pkgs.spotify
          pkgs.slack
          pkgs.lunarvim
          pkgs.raycast
          pkgs.checkstyle
          pkgs.tmux
          pkgs.zsh
          pkgs.oh-my-zsh
          pkgs.zsh-autocomplete
          pkgs.gradle
          pkgs.zsh-powerlevel10k
          pkgs.zsh-syntax-highlighting
        ];

      fonts.packages = with pkgs; [
        nerd-fonts.iosevka-term
      ];

        homebrew = {
          enable = true;
          casks = [
            "ghostty"
            "steam"
            "firefox"
            "karabiner-elements"
          ];
          onActivation.cleanup = "zap";
        };


      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';
      system.defaults = {
        dock.autohide = true;
      };

      # Allow for broken packages
      nixpkgs.config.allowBroken = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;
      # Enable alternative shell support in nix-darwin.
      # programs.zsh = {
      #   oh-my-zsh = {
      #     enable = true;
      #     plugins = ["git" "zsh-autocomplete"];
      #   };
      # };

      programs.zsh.interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

      ZSH_THEME=""
      plugins=(
            git
            )

      source $ZSH/oh-my-zsh.sh

      # source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '';

      programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"; 

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."fabbemmbp" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "fabianmoorpucar";
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
