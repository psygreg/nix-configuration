# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, unstable, nix-flatpak, lanzaboote, lib, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot = {
    loader.systemd-boot.enable = lib.mkForce false;
    loader.efi.canTouchEfiVariables = true;
    loader.timeout = 2;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "tcp_bbr" ];
    kernelParams = [
      "quiet"
      "splash"
      "transparent_hugepage=always"
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

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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

  services = {
    # Enable the KDE Plasma Desktop Environment.
    # displayManager = {
      # sddm = {
        # enable = true;
        # wayland.enable = true;
      # };
    # };
    # desktopManager.plasma6.enable = true;

    # enable Cosmic desktop
    # displayManager.cosmic-greeter.enable = true;
    # desktopManager.cosmic.enable = true;
    
    # enable gnome desktop
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    gnome.games.enable = false;

    # Configure keymap in X11
    xserver.xkb = {
      layout = "us";
      variant = "intl";
    };

    # Enable CUPS to print documents.
    printing = { 
      enable = true;
      drivers = with pkgs; [ cups-brother-hl1210w ];
    };

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
	      "com.mattjakeman.ExtensionManager"
        "com.chatterino.chatterino"
        "com.discordapp.Discord"
        "com.protonvpn.www"
        "fr.handbrake.ghb"
        "io.github.thetumultuousunicornofdarkness.cpu-x"
        "me.proton.Mail"
        "org.prismlauncher.PrismLauncher"
        "org.upscayl.Upscayl"
        "org.audacityteam.Audacity"
        "org.gnome.Logs"
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
    
    # preload settings - aggressive setup for SSDs and 16GB+ RAM
    preload-ng = {
      enable = true;
      settings = {
        cycle = 15;
        memTotal = -5;
        memFree = 70;
        memCached = 10;
        memBuffers = 50; 
        minSize = 1000000; 
        processes = 60;
        sortStrategy = 0;
        autoSave = 1800;
        mapPrefix = "/nix/store/;/run/current-system/;!/";
        exePrefix = "/nix/store/;/run/current-system/;!/";
      };
    };

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;
  };

  # enable flathub
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  # systemd service to set vm.min_free_kbytes dynamically as 1% of total memory size
  systemd.services.set-min-free-mem = {
    description = "Set vm.min_free_kbytes dynamically";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      User = "root";
      RemainAfterExit = true;
    };
    script = ''
      TOTAL_MEM=$(${pkgs.gawk}/bin/awk '/MemTotal/ {printf "%.0f", $2 * 0.01}' /proc/meminfo)
      if [ -z "$TOTAL_MEM" ] || [ "$TOTAL_MEM" -eq 0 ]; then
        echo "Failed to calculate memory size" >&2
        exit 1
      fi
      ${pkgs.sysctl}/bin/sysctl -w vm.min_free_kbytes=$TOTAL_MEM
    '';
  };

  zramSwap.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.psygreg = {
    isNormalUser = true;
    description = "Victor Gregory";
    extraGroups = [ "networkmanager" "wheel" "podman" "render" "video" "openrazer" ];
    # Subuid and subgid ranges for user namespaces, fixes distrobox
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
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

    # gamescope setup
    gamescope = {
	    enable = true;
	    capSysNice = false;
    };
  };

  # xdg.portal = with pkgs; {
    # enable = true;
    # extraPortals = [ xdg-desktop-portal-gtk ];
  # };

  # Allow unfree packages
  nixpkgs = { 
    config.allowUnfree = true;
    overlays = [
      (final: _prev: {
        resolve2023 = import (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/0d70460758949966e91d9ecb823b821f963cefbb.tar.gz";
          sha256 = "sha256:0arg4dakkqvhc814jq1vjrbw2apxzrq7xvw2vsn75l299d0zy43y";
        }) {
          inherit (final) system;
          config.allowUnfree = true;
        };
        gamescope = _prev.gamescope.overrideAttrs (oldAttrs: {
          patches = (oldAttrs.patches or [ ]) ++ [
            # Fornece o caminho para o seu novo arquivo de patch
            # Esse caminho é relativo à localização DESTE arquivo overlay.
            # Veja este comentário que referencia o patch:
            # https://github.com/ValveSoftware/gamescope/issues/1934#issuecomment-3225349079
            ./1867.patch
          ];
    	  });
      })
    ];
  }; 

  # cosmic from unstable
  # nixpkgs.config.packageOverrides = pkgs: {
  	# cosmic = unstable.cosmic;
	# cosmic-greeter = unstable.cosmic-greeter;
  # };  

  # additional hardware
  hardware = {
    enableAllFirmware = true;
    firmware = [ pkgs.linux-firmware ];

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
      	intel-compute-runtime
      	intel-media-driver
      	vpl-gpu-rt
      ];
    };

    openrazer.enable = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = with pkgs; {
    systemPackages = [
      # gnome stuff
      refine
      vanilla-dmz
      tela-icon-theme
      ffmpegthumbnailer
      # utilities
      clinfo
      podman-compose
      distrobox
      (distrobox.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          for file in $out/bin/*; do
            sed -i 's|distrobox_path="$(dirname "$(realpath "$0")")"|distrobox_path="/run/current-system/sw/bin"|g' "$file"
            sed -i 's|distrobox_path="$(dirname "$(readlink -f "$0")")"|distrobox_path="/run/current-system/sw/bin"|g' "$file"
          done
        '';
      }))
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
      sbctl
      disfetch
      wayland-utils
      # apps
      clapper
      clapper-enhancers
      vscode
      gimp
      mission-center
      typora
      protonplus
      heroic
      protontricks
      vintagestory
      # OBS setup
      obs-studio
      obs-studio-plugins.obs-pipewire-audio-capture
      obs-studio-plugins.obs-move-transition
      obs-studio-plugins.obs-scene-as-transition
      obs-studio-plugins.obs-vkcapture
      #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      #  wget
    ] ++ ( with unstable; [ faugus-launcher ] );
    # plasma6.excludePackages = [
	    # kdePackages.discover
	    # kdePackages.elisa
    # ];
    gnome.excludePackages = with pkgs; [ totem epiphany gnome-software geary gnome-music gnome-tour gnome-user-docs ];
    # environment variable fixes
    sessionVariables = {
      MESA_SHADER_CACHE_MAX_SIZE = "12G";
      # AMD_VULKAN_ICD = "RADV";
      # KWIN_COMPOSE = "O2ES";
      GSK_RENDERER = "gl";
    };
  };

  fonts.packages = with pkgs; [
	  nerd-fonts.adwaita-mono
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
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    dates = "daily";
    allowReboot = false;  # Set to true if you want automatic reboots
  };

  # systemd services for automatic updates with flakes enabled
  systemd.services.nixos-flake-update = {
    description = "Update NixOS flake inputs";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      WorkingDirectory = "/etc/nixos";
      ExecStart = "${pkgs.nixVersions.stable}/bin/nix flake update";
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
  systemd.timers.nixos-flake-update = {
    description = "Daily NixOS flake update timer";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
      OnBootSec = "15min";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
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
  system.stateVersion = "25.11"; # Did you read the comment?

}
