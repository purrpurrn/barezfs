{ config, pkgs, lib, ... }: {
  config = {
    networking.hostId = "7a4e0835";
    boot = {
      supportedFilesystems = [ "zfs" ];
      initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "sdhci_pci" ];
      kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages; # Latest Kernel supported by ZFS
      tmp.cleanOnBoot = true; # Clears `/tmp` on boot
      zfs = {
	forceImportRoot = false;
        package = pkgs.zfs_unstable;
        requestEncryptionCredentials = true;
      };
    };

    # Swap
    swapDevices = [{ device = "/dev/disk/by-label/SWAP"; }];

    services.zfs = {
      trim.enable = true;
      autoScrub.enable = true;
    };
  
    # Generic ZFS + tmpfs impermanence filesystem layout
    fileSystems = {
      "/boot" = {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
	options = [ "umask=0077" ]; # semi-secures `/boot` from being world accessible. source: https://github.com/NixOS/nixpkgs/issues/279362#issuecomment-1913126484 & https://github.com/NixOS/nixpkgs/issues/279362#issuecomment-1913506090
      };

      # ZFS Pool or tmpfs - root
      "/" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=6G"
          "mode=755"
        ];
      };

      # ZFS Pool - Nix Store
      "/nix" = {
        device = "zroot/nix";
        fsType = "zfs";
	neededForBoot = true;
      };

      # ZFS Pool - `/tmp` — NixOS uses `/tmp` to build artifacts, I don't wanna allocate lots of RAM to temporarily store those.
      "/tmp" = {
        device = "zroot/tmp";
        fsType = "zfs";
      };

      # ZFS Pool - Impermanence
      "/persist" = {
        device = "zroot/persist";
        fsType = "zfs";
        neededForBoot = true;
      };
    };
  };
}
