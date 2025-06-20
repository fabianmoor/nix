{
  description = "Fabbem Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Add home-manager as an input
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Ensure home-manager uses the same nixpkgs
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager}:
  let
    username = "fabbemmbp"; # Define username once
    configuration = { pkgs, config, ... }: {
    users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.vim
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
          pkgs.google-java-format
          pkgs.tmux
          pkgs.zsh
          pkgs.oh-my-zsh
          pkgs.zsh-autocomplete
          pkgs.gradle
          pkgs.zsh-powerlevel10k
          pkgs.zsh-syntax-highlighting
          pkgs.cargo
          pkgs.plantuml-c4
          pkgs.wget
          pkgs.maven
          pkgs.zulu23
          pkgs.yabai
          pkgs.skhd
          pkgs.sketchybar
          pkgs.hackgen-nf-font
          pkgs.neofetch
          pkgs.mysql84
          pkgs.lazygit
          pkgs.fzf
          pkgs.ripgrep
          pkgs.java-language-server
          pkgs.vimPlugins.nvim-jdtls
          pkgs.iterm2
        ];

      fonts.packages = with pkgs; [
        nerd-fonts.iosevka-term
        nerd-fonts.jetbrains-mono
      ];

        homebrew = {
          enable = true;
          brews = [
            "neovim"
            "mas"
            "lua-language-server"
            "pyright"
            "jdtls"
            "ltex-ls"
            "cliclick"
            "mysql-client"
            "chafa"
            "ffmpeg"
          ];
          casks = [
            "ghostty"
            "steam"
            "firefox"
            "karabiner-elements"
            "alt-tab"
            "linearmouse"
            "transmission"
            "rar"
          ];
          taps = [
            "homebrew/bundle"
          ];
          masApps = {
            "mappaMini" = 6739544806;
          };
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
      # This is still okay for system-wide defaults, not for specific app entries
      system.defaults = {
        dock.autohide = true;
        # Ensure these paths are correct and accessible to the user
        dock.persistent-apps = [
          "/nix/store/8xk9w9zpjydxzr31hvabr0f59pnj18xj-slack-4.42.120/Applications/Slack.app"
          "/System/Applications/Messages.app"
        ];
      };

      system.activationScripts.clearDock = {
        text = ''
          echo "Clearing existing persistent dock items..." >&2
          defaults delete com.apple.dock persistent-apps
          defaults delete com.apple.dock persistent-others
          killall Dock # Restart Dock to apply changes immediately
        '';
        # Make sure it runs early in the activation process
        # The higher the priority number, the earlier it runs.
        # Darwin-rebuild's own scripts run at 20.
        # This will run before nix-darwin sets system.defaults.
        priority = 10;
      };

      # Allow for broken packages
      nixpkgs.config.allowBroken = true;

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable Linux Binaries
      nix.linux-builder.enable = true;

      # Enable touchId for auth
      security.pam.services.sudo_local.touchIdAuth = true;

      programs.zsh.interactiveShellInit = ''
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

      ZSH_THEME=""
      plugins=(
            git
            )

      source $ZSH/oh-my-zsh.sh

      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '';

      programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      system.primaryUser = username; # Use the defined username

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Unable to install unsupported apps. // For instance Linux Binaries
      nixpkgs.config.allowUnsupportedSystem = true;
    };
  in
  {
    darwinConfigurations."fabbemmbp" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        # home-manager.darwinModules.home-manager # Include home-manager darwin module
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = username; # Use the defined username
            autoMigrate = true;
          };
        }
        # Pass the home-manager configuration for the user
        # {
        #   home-manager.users.${username} = {
        #     home.stateVersion = "23.11"; # Set your home-manager state version
        #     imports = [
        #       # Import your home-manager.nix here
        #       # ./modules/home-manager.nix
        #     ];
        #   };
        # }
      ];
    };
  };
}
