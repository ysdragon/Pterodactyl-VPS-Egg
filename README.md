<div align="center">

# Pterodactyl VPS Egg

[![License](https://img.shields.io/github/license/ysdragon/Pterodactyl-VPS-Egg)](https://github.com/ysdragon/Pterodactyl-VPS-Egg/blob/main/LICENSE)
[![CodeFactor](https://www.codefactor.io/repository/github/ysdragon/pterodactyl-vps-egg/badge)](https://www.codefactor.io/repository/github/ysdragon/pterodactyl-vps-egg)

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

## <img width="20" height="20" src="https://www.kernel.org/theme/images/logos/favicon.png" /> Available Linux Distributions

### Enterprise Linux
- <img width="16" height="16" src="https://rockylinux.org/favicon.png" /> Rocky Linux
- <img width="16" height="16" src="https://almalinux.org/fav/favicon.ico" /> AlmaLinux
- <img width="16" height="16" src="https://www.centos.org/assets/img/favicon.png" /> CentOS
- <img width="16" height="16" src="https://www.oracle.com/asset/web/favicons/favicon-32.png" /> Oracle Linux

### Debian-based
- <img width="16" height="16" src="https://netplan.readthedocs.io/en/latest/_static/favicon.png" /> Ubuntu
- <img width="16" height="16" src="https://www.debian.org/favicon.ico" /> Debian
- <img width="16" height="16" src="https://github.com/bin456789/reinstall/assets/7548515/f74b3d5b-085f-4df3-bcc9-8a9bd80bb16d" /> Kali Linux
- <img width="16" height="16" src="https://www.devuan.org/ui/img/favicon.ico" /> Devuan Linux

### Other Distributions
- <img width="16" height="16" src="https://www.alpinelinux.org/alpine-logo.ico" /> Alpine Linux
- <img width="16" height="16" src="https://archlinux.org/static/favicon.png" /> Arch Linux
- <img width="16" height="16" src="https://www.gentoo.org/assets/img/logo/gentoo-g.png" /> Gentoo Linux
- <img width="16" height="16" src="https://voidlinux.org/assets/img/favicon.png" /> Void Linux
- <img width="16" height="16" src="http://www.slackware.com/favicon.ico" /> Slackware Linux
- <img width="16" height="16" src="https://static.opensuse.org/favicon.ico" /> openSUSE
- <img width="16" height="16" src="https://fedoraproject.org/favicon.ico" /> Fedora
- <img width="16" height="16" src="https://chimera-linux.org/assets/icons/favicon48.png" /> Chimera Linux
- <img width="16" height="16" src="https://djeqr6to3dedg.cloudfront.net/repo-logos/library/amazonlinux/live/logo-1720462149317.png" /> Amazon Linux
- <img width="16" height="16" src="https://www.plamolinux.org/images/garland_logo.jpg" /> Plamo Linux
- <img width="16" height="16" src="https://linuxmint.com/web/img/favicon.ico" /> Linux Mint
- <img width="16" height="16" src="https://en.altlinux.org/favicon.svg" /> Alt Linux
- <img width="16" height="16" src="https://www.openeuler.org/favicon.ico" /> openEuler

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