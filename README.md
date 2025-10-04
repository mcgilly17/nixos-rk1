# NixOS RK1 Image Builder

Builds working NixOS images for Turing Pi RK1 compute modules with embedded Rockchip bootloader.

## What This Solves

- Standard NixOS ARM images don't boot on RK1 (missing Rockchip bootloader)
- Manual bootloader surgery is tedious and error-prone
- Need generic images that work across multiple RK1 nodes

## Usage

```bash
# Clone and build
git clone https://github.com/youruser/nixos-rk1-imagebuilder
cd nixos-rk1-imagebuilder
nix build

# Flash to RK1 module using Turing Pi tools
tpi flash -n 1 -i result/sd-image/nixos-rk1-aarch64-linux.img
```

## What You Get

- NixOS with latest kernel (6.11+) and RK3588 drivers
- SSH enabled with root access (password: `nixos123`)
- Container support (Podman) for Kubernetes
- Hardware monitoring and thermal management
- Generic hostname (set unique names after deployment)

## Building Requirements

- Nix with flakes enabled
- ARM64 system recommended (builds much faster than cross-compilation)
- At least 8GB free disk space

## Flashing Requirements

- Turing Pi 2 board with BMC access
- `tpi` command line tool installed

## After Flashing

1. Power on the RK1 module: `tpi power on --node 1`
2. SSH in: `ssh root@<ip-address>` (password: `nixos123`)
3. Set unique hostname: `hostnamectl set-hostname rk1-node1`
4. Apply your own configuration management

## Technical Details

- Uses extracted Rockchip bootloader from Turing Pi Ubuntu image
- Bootloader automatically injected at sector 64 during build
- Verified with RKNS signature check
- Based on NixOS unstable with RK3588 optimizations

## Files

- `flake.nix` - Build configuration with automated bootloader injection
- `configuration.nix` - NixOS system configuration for RK3588
- `rk1-bootloader-minimal.bin` - Working Rockchip bootloader (9.2MB)

## Troubleshooting

**Build fails on macOS/x86**: Use an ARM64 system or enable Rosetta emulation.

**Image won't boot**: Verify the RKNS signature is present:
```bash
hexdump -C -s 32768 -n 16 result/sd-image/nixos-rk1-aarch64-linux.img | grep "52 4b 4e 53"
```

**Can't SSH**: Check network connection and try the module's IP address.