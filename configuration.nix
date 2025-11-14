# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, ... }:
let
    sources = import ./sources.nix;
    lanzaboote = import sources.lanzaboote;
    nix-flatpak = builtins.fetchTarball {
      url = "https://github.com/gmodena/nix-flatpak/archive/refs/tags/v0.6.0.tar.gz";
      sha256 = "0s3mpb28rcmma29vv884fi3as926bfszhn7v8n74bpnp5qg5a1c8";
    };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      lanzaboote.nixosModules.lanzaboote
      "${nix-flatpak}/modules/nixos.nix"
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader -- modified for lanzaboote
  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 2;

    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

  # Use latest kernel.
    kernelPackages = pkgs.linuxPackages_lqx;
    kernelParams = [ 
	    "quiet"
	    "splash"
	    "mitigations=off"
	    "i915.force_probe=!e20b"
	    "xe.force_probe=e20b"
    ];
    kernel.sysctl = {
      "kernel.split_lock_mitigate" = 0;
      "kernel.nmi_watchdog" = 0;
    };
  };

  networking = {
    hostName = "nixos"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "us-acentos";
  security.rtkit.enable = true;

  # Enable the X11 windowing system.
  services = { 
    xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

    # Configure keymap in X11
    xserver.xkb = {
      layout = "us";
      variant = "intl";
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable sound with pipewire.
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    # CachyOS ananicy setup
    ananicy = with pkgs; {
	    enable = true;
	    package = ananicy-cpp;
	    rulesProvider = ananicy-rules-cachyos;
    }; 

    # other performance stuff
    preload.enable = true;

    # earlyOOM setup
    earlyoom = {
      enable = true;
      freeSwapThreshold = 2;
      freeMemThreshold = 2;
      extraArgs = [
          "-g" "--avoid" "'^(X|plasma.*|konsole|kwin|wayland|gnome.*)$'"
      ];
    };

    # enable nix-flatpak declarative flatpaks
    flatpak = {
      enable = true;
      packages = [
        "com.chatterino.chatterino"
        "com.discordapp.Discord"
        "com.stremio.Stremio"
        "com.github.rafostar.Clapper"
        "com.protonvpn.www"
        "fr.handbrake.ghb"
        "io.github.thetumultuousunicornofdarkness.cpu-x"
        "me.proton.Mail"
        "org.prismlauncher.PrismLauncher"
        "org.qbittorrent.qBittorrent"
	"com.mattjakeman.ExtensionManager"
      ];
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
  };

  zramSwap.enable = true;
  
  nixpkgs.config = {
    # Allow unfree packages
    allowUnfree = true;
    # override intel-vaapi for intel-media-driver
    packageOverrides = pkgs: {
      intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
    };
  };

  # additional hardware
  hardware = {
    enableAllFirmware = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # intel-compute-runtime
        intel-media-driver
        # intel-graphics-compiler
	libvdpau-va-gl
	vpl-gpu-rt
      ];
    };

    openrazer.enable = true;
  };
    
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.psygreg = {
    isNormalUser = true;
    description = "Victor";
    extraGroups = [ "networkmanager" "wheel" "podman" "openrazer" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  programs = {
    # Install firefox.
    firefox.enable = true;
    # enable starship
    starship.enable = true;
    # enable GSR
    gpu-screen-recorder.enable = true;

  # steam setup
    steam = {
  	  enable = true;
  	  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  	  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };

  # enable flathub
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
	  # gnome extensions and stuff
	  #gnomeExtensions.arcmenu
	  #gnomeExtensions.appindicator
	  #gnomeExtensions.dash-to-panel
	  #gnomeExtensions.caffeine
	  #gnomeExtensions.clipboard-indicator
	  #gnomeExtensions.blur-my-shell
	  refine
	  tela-icon-theme
	  # utilities
	  podman-compose
	  distrobox
	  boxbuddy
	  host-spawn
	  addwater
	  starship
	  git
	  lshw
	  appimage-run
	  pciutils
	  openrazer-daemon
	  polychromatic
	  niv
	  sbctl
	  disfetch
	  # apps
	  mission-center
	  protonplus
	  audacity
	  gimp3
	  # gpu-screen-recorder-gtk
	  heroic
	  vintagestory
	  # OBS setup
	  obs-studio
	  obs-studio-plugins.obs-move-transition
	  obs-studio-plugins.obs-scene-as-transition
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ]; 

  fonts.packages = with pkgs; [
	  noto-fonts
	  noto-fonts-cjk-sans
	  noto-fonts-color-emoji
	  liberation_ttf
	  cantarell-fonts
  ];

  virtualisation = {
        containers.enable = true;
        podman = {
                enable = true;
                dockerCompat = true;
                defaultNetwork.settings.dns_enabled = true; # Required for cont>
        };
  };

  # nix management automations
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    dates = "daily";
    allowReboot = false;  # Set to true if you want automatic reboots
  };

  # environment variable fixes
  environment.sessionVariables = {
	  VDPAU_DRIVER = "va_gl";
	  GSK_RENDERER = "gl";
	  MESA_SHADER_CACHE_MAX_SIZE = "12G";
	  LIBVA_DRIVER_NAME = "iHD";
  };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
