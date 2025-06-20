{ config, pkgs, lib, ... }: # home-manager itself is implicitly available in the user module

let
  user = "fabbemmbp"; # This user variable is now within the home-manager user context
in
{
  # You don't need `imports = [ ./dock ];` here anymore if you use home-manager's built-in module
  # and if ./dock contains local.dock, it's not being picked up correctly.

  # Use home-manager's built-in darwin.dock module

    # Example of persistent-others (folders/files on the right side of the dock)
    persistent-others = [
      { path = "${config.home.homeDirectory}/Downloads"; # Example path, adjust as needed
        label = "Downloads";
        displayAs = "folder"; # or "stack"
        showAs = "fan"; # or "grid", "list"
      }
    ];

    # If you want to enable recent applications, etc.
    # showRecentApps = true;
  };

  # You don't need this block if you're managing dock via darwin.dock above
  # local.dock = {
  #   enable = true;
  #   entries = [
  #     { path = "/Applications/Nix Apps/Slack.app/"; }
  #   ];
  # };

  # It me
  # This section is usually defined at the flake level or in a more global home-manager config
  # If you set system.primaryUser = "fabbemmbp"; in flake.nix, home-manager will apply to this user.
  # If you want to configure specific user attributes via home-manager:
  # users.users.${user} = {
  #   name = "${user}";
  #   home = "/Users/${user}";
  #   isHidden = false;
  #   shell = pkgs.zsh;
  # };

  home.stateVersion = "23.11"; # Set your home-manager state version

  # If you want to install home-manager packages here, use home.packages
  home.packages = [
    # pkgs.somePackage
  ];

  # This is where your actual home-manager configurations would go
  # For example:
  programs.git.enable = true;
  programs.git.userName = "fabbemmbp";
  programs.git.userEmail = "fabbe142@gmail.com";

  # Example of linking a file
  # home.file."path/to/your/file".source = ./path/to/source/file;

  # If you have shared home-manager configurations, you can still import them
  # programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib; };

  manual.manpages.enable = false; # Keep this if you want to disable manpages
}
