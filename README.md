<div align="center">

# Pterodactyl VPS Egg

[![PRs Welcome](https://img.shields.io/github/license/ysdragon/Pterodactyl-VPS-Egg)](https://github.com/ysdragon/Pterodactyl-VPS-Egg/blob/main/LICENSE)

A powerful and lightweight Virtual Private Server (VPS) egg for Pterodactyl Panel, supporting multiple architectures and operating systems.
</div>

## ✨ Features

- 🚀 Easy deployment and management
- 🔧 Customizable configurations
- 🔄 Multiple architecture support
- 🖥️ Wide range of operating systems
- 🔌 Multiple port support (TCP/UDP)
   - Dynamic port mapping

## 🏗️ Supported Architectures

| Architecture | Status | Notes |
|-------------|--------|-------|
| amd64 | ✅ Full Support | Recommended for most users |
| arm64 | ✅ Full Support | Ideal for ARM-based servers |
| riscv64 | ⚠️ Limited Support | Requires custom rootfs images |

> [!IMPORTANT]
> For `riscv64` architecture, you must provide or host your own rootfs images. Currently, only Chimera Linux offers native support for riscv64 in this egg.

## 💻 Supported Operating Systems

### Enterprise Linux
- Rocky Linux
- AlmaLinux
- CentOS

### Debian-based
- Ubuntu
- Debian
- Kali Linux
- Devuan Linux

### Other Distributions
- Alpine Linux
- Arch Linux
- Gentoo Linux
- Void Linux
- Slackware Linux
- openSUSE
- Fedora
- Chimera Linux

## 🚀 Quick Start

1. **Download the Egg**
   - Download the `egg-vps.json` configuration file to your local machine.
2. **Import to Pterodactyl**
   - Navigate to the Admin Panel
   - Go to Nests > Import Egg
   - Upload the `egg-vps.json` file
   - Configure as needed

3. **Deploy Your VPS**
   - Create a new server using the VPS egg
   - Configure resources
   - Start your instance

## Contributing

Contributions are welcome. If you have any suggestions, improvements, or bug fixes, feel free to submit a pull request.

## License
This project is open-source and available under the MIT License. See the [LICENSE](https://github.com/ysdragon/Pterodactyl-VPS-Egg/blob/main/LICENSE) file for more details.