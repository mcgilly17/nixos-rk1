{ config, pkgs, lib, ... }:

{
  # Use latest kernel for RK3588 support (6.11+ recommended)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable all available kernel modules for RK3588
  boot.initrd.availableKernelModules = [
    "xhci_pci" "usbhid" "usb_storage" "sd_mod" "mmc_block"
    "nvme" "ahci" "sdhci_of_dwcmshc"  # Storage controllers
  ];

  # RK3588 specific kernel modules
  boot.kernelModules = [
    "rockchipdrm"
    "rockchip_thermal"
    "rockchip_saradc"
    "panfrost"  # GPU driver
    "fusb302"  # USB-C controller
  ];

  # Boot loader configuration for ARM64
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # File systems - optimize for eMMC
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ]; # Reduce wear on eMMC
    };
  };

  # Networking - no hardcoded hostname for generic cluster deployment
  networking = {
    # hostName not set - will default to "nixos" for generic deployment
    # Set unique hostnames post-deployment: hostnamectl set-hostname rk1-node1
    useDHCP = lib.mkDefault true;  # Simpler DHCP config
    # dhcpcd.enable = false;  # Uncomment if DHCP causes build issues
  };

  # Enable SSH with root access for testing
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set root password for testing (change this!)
  users.users.root.password = "nixos123";

  # Basic system packages for testing and hardware verification
  environment.systemPackages = with pkgs; [
    vim
    htop
    lm_sensors  # Works on RK3588 for temperature monitoring
    ethtool
    usbutils
    pciutils
    # Storage tools - compatible with ARM64
    hdparm
    smartmontools
    # Network testing
    iperf3
    tcpdump
  ];

  # Temperature monitoring
  hardware.sensor.iio.enable = true;  # Industrial I/O sensors support

  # Power management and thermal control
  powerManagement.enable = true;
  # thermald is Intel-specific, not for ARM/RK3588

  # Enable container support for future K3s
  virtualisation.containers.enable = true;
  virtualisation.podman.enable = true;

  # Disable unnecessary services to reduce resource usage
  services.udisks2.enable = false;
  documentation.enable = false;
  documentation.nixos.enable = false;

  # System version
  system.stateVersion = "24.05";
}