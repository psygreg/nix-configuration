# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
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
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "tcp_bbr" ];
    kernelParams = [
	    "quiet"
	    "splash"
	    "preempt=full"
    ];
    kernel.sysctl = {
      "kernel.split_lock_mitigate" = 0;
      "kernel.nmi_watchdog" = 0;
      "net.core.netdev_max_backlog" = 4096;
      "fs.file-max" = 2097152;
      "net.ipv4.tcp_congestion_control" = "bbr";
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

    # Enable the Plasma Desktop Environment.
    displayManager.sddm = { 
	    enable = true;
	    wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;

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
        "com.github.rafostar.Clapper"
        "com.protonvpn.www"
        "fr.handbrake.ghb"
        "io.github.thetumultuousunicornofdarkness.cpu-x"
        "me.proton.Mail"
        "org.prismlauncher.PrismLauncher"
	      "com.mattjakeman.ExtensionManager"
	      "org.upscayl.Upscayl"
	      "org.chromium.Chromium"
	      "org.audacityteam.Audacity"
      ];
      update.auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
    
    # udev rules
    udev = {
	    enable = true;
	    extraRules = ''
		    ACTION=="add", SUBSYSTEM=="sound", KERNEL=="card*", DRIVERS=="snd_hda_intel", TEST!="/run/udev/snd-hda-intel-powersave", \
    			RUN+="${pkgs.bash}/bin/bash -c 'touch /run/udev/snd-hda-intel-powersave; \
        			[[ $$(cat /sys/class/power_supply/BAT0/status 2>/dev/null) != \"Discharging\" ]] && \
        			echo $$(cat /sys/module/snd_hda_intel/parameters/power_save) > /run/udev/snd-hda-intel-powersave && \
        			echo 0 > /sys/module/snd_hda_intel/parameters/power_save'"

		    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", TEST=="/sys/module/snd_hda_intel", \
    			RUN+="${pkgs.bash}/bin/bash -c 'echo $$(cat /run/udev/snd-hda-intel-powersave 2>/dev/null || \
        			echo 10) > /sys/module/snd_hda_intel/parameters/power_save'"

		    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", TEST=="/sys/module/snd_hda_intel", \
    			RUN+="${pkgs.bash}/bin/bash -c '[[ $$(cat /sys/module/snd_hda_intel/parameters/power_save) != 0 ]] && \
        			echo $$(cat /sys/module/snd_hda_intel/parameters/power_save) > /run/udev/snd-hda-intel-powersave; \
        			echo 0 > /sys/module/snd_hda_intel/parameters/power_save'"

		    KERNEL=="rtc0", GROUP="audio"
		    KERNEL=="hpet", GROUP="audio"

		    DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"

		    # HDD
		    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", \
    			ATTR{queue/scheduler}="bfq"
		    # SSD
		    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", \
    			ATTR{queue/scheduler}="mq-deadline"
		    # NVMe SSD
		    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", \
    		  ATTR{queue/scheduler}="none"
	    '';
    };
  };

  zramSwap.enable = true;
  
  nixpkgs.config = {
    # Allow unfree packages
    allowUnfree = true;
  };

  # additional hardware
  hardware = {
    enableAllFirmware = true;

    graphics = {
      enable = true;
      enable32Bit = true;
    };
    # enable ROCM through opencl
    amdgpu.opencl.enable = true;

    firmware = [ pkgs.linux-firmware ];

    openrazer.enable = true;
  };

  systemd.tmpfiles.rules = 
  let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas
        hipblas
        clr
	      rocm-runtime
	      rocm-device-libs
	      rocminfo
	      rocm-smi
      ];
    };
  in [
    "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
  ];
    
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

  # steam setup
    steam = {
  	  enable = true;
  	  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  	  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
  
  xdg.portal = with pkgs; {
	  enable = true;
	  extraPortals = [ xdg-desktop-portal-gtk ];
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
    # gnome stuff
	  kdePackages.partitionmanager
	  tela-icon-theme
	  ffmpegthumbnailer
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
	  gimp3
	  heroic
	  faugus-launcher
	  protontricks
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
	  poppins
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
    dates = "daily";
    allowReboot = false;  # Set to true if you want automatic reboots
  };

  # environment variable fixes
  environment.sessionVariables = {
	  MESA_SHADER_CACHE_MAX_SIZE = "12G";
    AMD_VULKAN_ICD = "RADV";
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
