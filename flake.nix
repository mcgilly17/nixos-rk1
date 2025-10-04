{
  description = "NixOS disk image for RK1/RK3588 eMMC flashing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    targetSystem = "aarch64-linux";

    # Support building from multiple host systems
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in
  {
    nixosConfigurations.rk1 = nixpkgs.lib.nixosSystem {
      system = targetSystem;
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./configuration.nix
        {
          # Override SD image settings for RK1/RK3588 with automatic bootloader injection
          sdImage = {
            imageBaseName = "nixos-rk1";
            # Expand root partition to fill available space (good for eMMC)
            expandOnBoot = true;

            # Automatically inject RK1 bootloader after image is built
            postBuildCommands = ''
              echo "Installing RK1 bootloader to image..."

              # Copy the extracted RK1 bootloader to sectors 64+ (where RK3588 ROM looks for it)
              dd if=${./rk1-bootloader-minimal.bin} of=$img conv=notrunc seek=64 bs=512

              echo "RK1 bootloader installation complete"

              # Verify the Rockchip bootloader signature is present
              echo "Verifying RKNS signature..."
              if hexdump -C -s 32768 -n 16 $img | grep -q "52 4b 4e 53"; then
                echo "✅ RKNS signature found at sector 64"
              else
                echo "❌ RKNS signature NOT found - bootloader installation failed"
                exit 1
              fi

              echo "Ready for flashing to RK1 eMMC storage"
            '';
          };
        }
      ];
    };

    # Build disk image for flashing to eMMC - available from any supported system
    packages = nixpkgs.lib.genAttrs supportedSystems (system: {
      image = self.nixosConfigurations.rk1.config.system.build.sdImage;
      default = self.packages.${system}.image;
    });
  };
}