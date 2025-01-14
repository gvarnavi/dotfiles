{
  description = "Georgios nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
	  pkgs.discord
	  pkgs.inkscape-with-extensions
	  pkgs.mkalias
          pkgs.neovim
	  pkgs.nodejs_22
	  pkgs.obsidian
	  pkgs.rectangle
	  pkgs.spotify
	  pkgs.stow
	  pkgs.vim
	  pkgs.warp-terminal
	  pkgs.whatsapp-for-mac
	  pkgs.zoom-us
        ];

      # Homebrew config
      homebrew = {
        enable = true;
	brews = [
	  "mas"
	  "uv"
	];
	casks = [
	  "docker"
	  "firefox"
	  "ghostty"
	  "the-unarchiver"
	];
	masApps = {
	  "Slack" = 803453959;
	};
	onActivation.cleanup = "zap";
	onActivation.autoUpdate = true;
	onActivation.upgrade = true;
      };

      # Enable binaries for Intel CPUs
      nix.extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
      '';

      # binaries for Linux
      nix.linux-builder.enable = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Fingerprint sudo
      security.pam.enableSudoTouchIdAuth = true;

      # Index applications in spotlight hack
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

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Set some defaults
      system.defaults = {
        dock.autohide = true;
	dock.mru-spaces = false;
	dock.persistent-apps = [
	  "/System/Applications/Messages.app"
	  "/System/Applications/iPhone Mirroring.app"
	  "/System/Cryptexes/App/System/Applications/Safari.app"
	  "/Applications/Slack.app"
	  "${pkgs.discord}/Applications/Discord.app"
	  "${pkgs.obsidian}/Applications/Obsidian.app"
	  "${pkgs.spotify}/Applications/Spotify.app"
	  "${pkgs.warp-terminal}/Applications/Warp.app"
	  "/Applications/Ghostty.app"
	];
	finder.AppleShowAllExtensions = true;
	finder.FXPreferredViewStyle = "clmv";
	loginwindow.GuestEnabled = false;
	NSGlobalDomain.AppleICUForce24HourTime = true;
	NSGlobalDomain.AppleInterfaceStyle = "Dark";
	NSGlobalDomain.KeyRepeat = 2;
	screencapture.location = "~/Pictures/screenshots";
	screensaver.askForPasswordDelay = 10;
      };

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."air" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration
        nix-homebrew.darwinModules.nix-homebrew
	{
	  nix-homebrew = {
	    enable = true;
	    # Apple Silicon Only
	    enableRosetta = true;
	    # User owning the Homebrew prefix
	    user = "gvarnavides";
	  };
        }
      ];
    };
  };
}
