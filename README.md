<!-- Top Image -->
<p align="center"><img src="https://user-images.githubusercontent.com/345869/228565610-dbd52f13-ee2a-454a-84f8-9d3e0b2438c7.png" alt="ZSHBOP"></p>

This is my custom ZSH configuration. It uses antidote to install ZSH plugins.

<a href="https://jordantrask.com/coffee" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>
<!-- Top Image -->


<!--ts-->
Table of Contents
=================

* [zshbop](#zshbop)
* [Installation](#installation)
    * [Advanced Install](#advanced-install)
* [Custom Configuration File](#custom-configuration-file)
    * [Custom Configuration Examples](#custom-configuration-examples)
        * [zshbop Overrides](#zshbop-overrides)
        * [Exbin](#exbin)
* [Commands/Aliases](#commandsaliases)
* [Installation Notes](#installation-notes)
    * [macOS Installation Notes](#macos-installation-notes)
    * [Windows Installation Notes](#windows-installation-notes)
        * [WSL 1 vs WSL 2](#wsl-1-vs-wsl-2)
        * [Upgrade WSL 1 to WSL 2](#upgrade-wsl-1-to-wsl-2)
        * [WSL Subsystem](#wsl-subsystem)
        * [Windows Terminal](#windows-terminal)
        * [VcXsrv (WSL Gui)](#vcxsrv-wsl-gui)
* [Font Installation Notes](#font-installation-notes)
    * [Automatic Font Install](#automatic-font-install)
    * [Manual Font Install](#manual-font-install)
        * [macOS](#macos)
        * [Windows](#windows)
            * [Windows Terminal](#windows-terminal-1)
            * [WSL Script Install - Broken](#wsl-script-install---broken)
* [ZSH Installation Issues](#zsh-installation-issues)
    * [CentOS 7 + zsh 5.1.1](#centos-7--zsh-511)
* [Issues](#issues)
* [ToDo](#todo)
  Found markers

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

<!-- Added by: jtrask, at: Thu 06 Oct 2022 11:54:52 AM EDT -->

<!--te-->

# zshbop
zshbop is a frankenstien project to improve my own workflow. It utilizes a number of third party software an scripts. At the core the following are used.

* Oh My ZSH
* Antidote
* Antigen
* Powerlevel10k

## Features

* Customized Powerlevel10k prompt
* A knowledge base of common topics
* Boot time tracking with microsecond precision (see [doc/BOOT_TIMING.md](doc/BOOT_TIMING.md))
* A library of alises, functions for common tasks for various workflows around the following.
    * Cloudflare
    * Docker
    * Git
    * WordPress
    * Linux
    * AWS
    * curl
    * php
    
## Branches

* main - production releases, fully functional.
* next-release - Next release branch, may be broken.

## Commands
Ive designed zshbop to have a number of commands
### Core Commands
These commands are available as just commands in the shell

* `help` - zshbop help screen
* `init` - Initialize zshbop
* `kb` - Knowledge Base
* `motd` - Print out motd
* `os` - Return OS
* `report` - Print out errors and warnings
* `repos` - Install popular github.com repositories.

### zshbop Quick Commands
These commands are shortened aliases for zshbop commands

* `zb` - zshbop main command and list of commands
* `zbd` - Change directory to $ZBR
* `zbqr` - Quick reload zshbop
* `zbr` - Reload zshbop
* `zbu` - Update zshbop
* `zbuf` - Update and reset zshbop
* `zbuqr` - Update and quick reload zshbop
* `zbur` - Update and reload zshbop

### zshbop Commands
* `zb` - zshbop main command and list of commands
* `zb branch` - Switch between main and next-release branch
* `zb cache-clear` - Clear cache for antigen + more
* `zb cache-clear-super` - Clear everything, including zsh autocompletion
* `zb check` - Check environment for installed software and tools
* `zb check-system` - Print out errors and warnings
* `zb check-updates` - Check for zshbop update, not completed yet
* `zb cleanup` - Cleanup old things
* `zb custom` - Custom zshbop configuration
* `zb custom-load` - Load zshbop custom config
* `zb debug` - Turn debug on and off
* `zb formatting` - List variables for using color
* `zb help` - zshbop help screen
* `zb install-env` - Install environment tools
* `zb issue` - Create zshbop issue on Github
* `zb reload` - Reload zshbop
* `zb report` - Print out errors and warnings
* `zb update` - Update zshbop
* `zb version` - Get version information


# Installation

## Install Guided

 There is an included install.sh bash script that will guide you through the installation process. It will ask you questions and install the required packages, such as zsh which is a requirement.

| Install Method      | Command       |
|---------------------|---------------|
| Quick Install       | ```bash <(curl -sL https://zshrc.pl)``` |
| Fallback Install    | ```bash <(curl -sL https://raw.githubusercontent.com/jordantrizz/zshbop/master/install.sh)```  |
| Next Release Install | ```bash <(curl -sL https://raw.githubusercontent.com/jordantrizz/zshbop/next-release/install.sh)``` |

## Install Usage
```
Usage: install -h|-s (clean|skipdeps|default|home|git|)|(custom <branch> <location>)

  Options
    -h          - This help screen
    -s          - Skip all dependencies
    -o          - Skip optional software check
    -d          - Debug mode

  Commands

    clean                         - Remove zshbop
    default                       - Default install
    home                          - Install in home directory
    git                           - Install in ~/git with dev branch
    custom <branch> <location>    - Custom install
    
  Custom Install: * Note: Custom install skips optional software check
    branch (main|next-release)
    location (home|system|git) 
        - home = $HOME/zshbop
        - systen = /usr/local/sbin/zshbop
        - git = $HOME/git/zshbop
```
## Install Examples
### Install main branc into home directory
```
bash <(curl -sL https://zshrc.pl) custom main home
```
### Install next-release branch into system directory /usr/local/sbin
```
bash <(curl -sL https://zshrc.pl) custom next-release system
```
### Install main branch into git directory ~/git
```
bash <(curl -sL https://zshrc.pl) custom main git
```
### Install next-release branch into system and skip optional software check
```
bash <(curl -sL https://zshrc.pl) -o custom next-release system
```

# Font Installation Notes
The most important part of zshbop is the powerlevel10k prompt, which requires a specific font. With Powerline10k you need patched font files. The patch font files are "MesloLGS NF" and are located on the following Github repository.

* https://github.com/romkatv/powerlevel10k/blob/master/font.md

## Automatic Font Install
As per the font.md file above.

>Automatic font installation
>If you are using iTerm2 or Termux, `p10k configure` can install the recommended font for you. Simply answer Yes when asked whether to install Meslo Nerd Font.

## Manual Font Install

### macOS
```
cp fonts/* ~/Library/fonts
```

### Windows
N/A

#### Windows Terminal
Then use the ```windows_terminal.json``` in this repository.

#### WSL Script Install - Broken
There is an issue with some of the Powerline fonts I downloaded and installed in windows. So I opted for this set of fonts using a script in a GIST https://gist.github.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b

You can simply run this command within WSL

```
bash -c "$(curl -fsSL https://gist.githubusercontent.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b/raw/install_meslo_wsl.sh)"
```

# Configuration and Customization
You can create a custom configuration file to override zshbop settings and variables. This is useful if you want to use a different plugin manager or override zshbop settings.
## Using zshbop Configuration File
Copy ```.zshbop.config.example``` to ```$HOME/.zshbop.config``` and modify as needed.

### Configuration Options
| Variable        	| Description                                                | Values                     	| Default     	 |
|----------------	|------------------------------------------------------------|-------	|---------------|
| `ZSHBOP_ROOT`| Location of zshbop installation                            | String | Detected      |
| `ZSHBOP_CUSTOM_SSHKEY` | Set a custom SSH key to be loaded | String | Detected |
| `ZSHBOP_PLUGIN_MANAGER` | Override plugin manager, can be init_antidote or init_anitgen | String | init_antidote |
| `ZSHBOP_GIT_CHECK` | zshbop git check on logout, this will run and will $GIT_HOME for any repositories that have uncommited code. | Number | 1 |
| `GIT_HOME` | A location where you have all your git repositories. | String | $HOME/git |
| `ZSHBOP_UPDATE_GIT` | Git Repositores to update when running zshbop update | Array | ${HOME}/git/cloudflare-cli ${GIT_HOME}/plik |
| `ZSH_IP_PROVIDER` | IP Provider for zshbop | String | eg. ipinfo.io |
| `ZSH_IP_API_KEY` | API Key for ip-info commmand | String | |

### Exbin
* Exbin https://exbin.call-cc.be

| Variable | Description                                                      | Values                     	| Default     	|
|-----------------	|------------------------------------------------------------------|---------------------	|---------	|
| `EXBIN_TYPE`| Choose either `netcat` or `api` for exbin posting.| String | `netcat`|
| `EXBIN_HOST`| Exbin host, for netcat just the hostname and for api the full URL.| String| `exbin.call-cc.be`|
| `EXBIN_PORT`|  If you don't use the standard 9999 port for exbin.| Number| `9999`|

##  Custom Startup Scripts
You can create a custom startup script to run when zshbop starts. This is useful if you want to run a script that's not included in zshbop.

Uncomment the following in ```$HOME/.zshbop.config```

```
function init_custom_startup () {

}
```

# Installation Notes
## Operating System Installation Notes
### macOS Installation Notes
Nothing at this time!

### Windows Installation Notes
#### Windows Terminal
Windows Terminal is a means to manage the various terminals installed in Windows.

* WSL
* Command Prompt
* Powershell
* Custom Powershell (Azure + Exchange)

#### WSL Subsystem
You'll need the WSL Subsystem installed.
* Open PowerShell as Administrator and run
```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

#### WSL 1 vs WSL 2
Open a command prompt on Windows 10 and run the following command to confirm what version of WSL you're running.
```
wsl --list --verbose
```
#### Upgrade WSL 1 to WSL 2
I used this guide https://www.tenforums.com/tutorials/164301-how-update-wsl-wsl-2-windows-10-a.html

1.  Upgrade WSL via elevated PowerShell 
    ```dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart```
2. Install VMP via elevated PowerShell. The following enables the Virtual Machine Platform. This is important for WSL 2 for some reason. https://docs.microsoft.com/en-us/windows/wsl/faq#does-wsl-2-use-hyper-v--will-it-be-available-on-windows-10-home-
    ```dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart```
3. Restart your Computer
4. Set WSL to version 2
    ```wsl --set-default-version 2```
5. Convert your existing linux distro from WSL 1 to 2
    ``` wsl --set-version <distro_name> 2```
Note: If you have an error converting your distro, look at this thread https://github.com/microsoft/WSL/issues/4929

#### VcXsrv (WSL Gui)
If you want to run Xserver for a GUI under WSL, this guide will help.

* https://medium.com/@dhanar.santika/installing-wsl-with-gui-using-vcxsrv-6f307e96fac0

# ZSH Installation Issues
## CentOS 7 + zsh 5.1.1
```
sudo yum update -y
sudo yum install -y git make ncurses-devel gcc autoconf man yodl
git clone -b zsh-5.7.1 https://github.com/zsh-users/zsh.git /tmp/zsh
cd /tmp/zsh
./Util/preconfig
./configure
sudo make -j 20 install
```

# Issues
All issues are makred with ```@@ISSUE``` and need to be addressed.

# ToDo

* Place all included files into directory inc
* Check for ssh-key id_rsa if chmod 600 and if not ask to do it.
* If any packages aren't installed ask to install them.
* Flight check command to confirm what's setup and isn't, check packacges installed.
* Borrow or steal https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/upgrade.sh
* Install jq and md5sum via brew for macos
* Figure out FZF wget https://github.com/junegunn/fzf-bin/releases/download/0.17.4/fzf-0.17.4-linux_amd64.tgz
* Look into diff so fancy wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
* Add https://github.com/skx/sysadmin-util.git
* Devise method to override antidote and antigen plugins.
* Look into these plugins
```
antigen bundle wfxr/forgit
antigen bundle djui/alias-tips
antigen bundle desyncr/auto-ls
antigen bundle MikeDacre/careful_rm
antigen bundle viasite-ansible/zsh-ansible-server
antigen bundle micha/resty
https://github.com/horosgrisa/mysql-colorize
https://github.com/thetic/extract.git
https://github.com/picatz/hunter
https://github.com/ExplainDev/kmdr-cli
https://github.com/daveearley/cli.fyi
https://github.com/tldr-pages/tldr
https://github.com/isacikgoz/tldr
```
