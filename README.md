# zshbop
This is my custom ZSH configuration. It uses antigen to install ZSH plugins.

<a href="https://jordantrask.com/coffee" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

<!--ts-->
* [zshbop](#zshbop)
* [Installation](#installation)
   * [Quick Installation](#quick-installation)
   * [Quick Install Development](#quick-install-development)
   * [Advanced Install](#advanced-install)
* [Custom Configuration File](#custom-configuration-file)
   * [Custom Configuration Examples](#custom-configuration-examples)
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
      * [Script Install - Broken](#script-install---broken)
   * [ZSH Installation Issues](#zsh-installation-issues)
      * [CentOS 7 + zsh 5.1.1](#centos-7--zsh-511)
* [ToDo](#todo)
   * [Current Todo](#current-todo)
   * [Random Notes](#random-notes)

<!-- Added by: jtrask, at: Thu 18 Nov 2021 09:40:38 AM EST -->

<!--te-->

# Installation
## Quick Installation
```
bash <(curl -sL https://zshrc.pl)
```

## Quick Install Development
```
bash <(curl -sL https://raw.githubusercontent.com/jordantrizz/zshbop/develop/install)
```

## Advanced Install
<details><summary>Click to Reveal Advanced Install</summary>
<p>
If you don't want to have zsh within your home directory, then use the following.
1. Ensure you have zsh shell
```apt-get install zsh```
2. Clone repository to the directory of your choise
```git clone https://github.com/jordantrizz/zshbop```
3. Copy .zshrc_install to ~/.zshrc or $HOME/.zshrc
```cp zsh/.zshrc_install ~/.zshrc```
4. Edit $ZSH_ROOT variable in your new ~/.zshrc to the path to the git cloned repository
***WARNING: don't use ~ use $HOME instead, as tilde doesn't work with zsh***
```sed -i 's/CHANGEME/zshbop/g' .zshrc```
5. Restart your terminal/shell
</p>
</details>

# Custom Configuration File
If you have any custom variables, functions or zshbop specific configuration. You can add it to the .zshbop

## Custom Configuration Examples
There is a wrapper for exbin, if you specify the following variables in onof the custom configuration files.

| Variable        	| Description                                                                                           | Values                     	| Default     	|
|-----------------	|------------------------------------------------------------------------------------------------------ |----------------------------	|-------------	|
| `EXBIN_TYPE`          | Choose either `netcat` or `api` for exbin posting.                                            | String                     	| `netcat`      	|
| `EXBIN_HOST`        	| Exbin host, for netcat just the hostname and for api the full URL.                                    | String                  	| `exbin.call-cc.be` 	|
| `EXBIN_PORT`		| If you don't use the standard 9999 port for exbin.							| Number			| `9999`		|

```
EXBIN="https://exbin.call-cc.be/"
```

# Commands/Aliases
You can start by typeing ```help``` which will give you some top level commands.
You can also review [help/commands.md](Commands)

# Installation Notes
## macOS Installation Notes
Nothing at this time!

## Windows Installation Notes
### WSL 1 vs WSL 2
Don't know much now. But I needed to upgrade and this is the way to do it!

Open a command prompt on Windows 10 and run the following command to confirm what version of WSL you're running.
```
wsl --list --verbose
```
### Upgrade WSL 1 to WSL 2
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
### WSL Subsystem
You'll need the WSL Subsystem installed.
* Open PowerShell as Administrator and run
```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```
### Windows Terminal
Windows Terminal is a means to manage the various terminals installed in Windows.

* WSL
* Command Prompt
* Powershell
* Custom Powershell (Azure + Exchange)

It's a great and I suggest you install it!

### VcXsrv (WSL Gui)
If you want to run Xserver for a GUI under WSL, this guide will help.

* https://medium.com/@dhanar.santika/installing-wsl-with-gui-using-vcxsrv-6f307e96fac0

## Font Installation Notes
So if you've used Powerlevel9k, you'd need the powerline fonts. With Powerline10k you need patched font files. The patch font files are "MesloLGS NF" and are located on the following Github repository.

* https://github.com/romkatv/powerlevel10k/blob/master/font.md

### Automatic Font Install
As per the font.md file above.

>Automatic font installation
>If you are using iTerm2 or Termux, `p10k configure` can install the recommended font for you. Simply answer Yes when asked whether to install Meslo Nerd Font.


### Manual Font Install

### macOS
```
cp fonts/* ~/Library/fonts
```

### Windows
Todo
```
```

## Windows Terminal
Then use the ```windows_terminal.json``` in this repository.

### Script Install - Broken
There is an issue with some of the Powerline fonts I downloaded and installed in windows. So I opted for this set of fonts using a script in a GIST https://gist.github.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b

You can simply run this command within WSL

```
bash -c "$(curl -fsSL https://gist.githubusercontent.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b/raw/install_meslo_wsl.sh)"
```

## ZSH Installation Issues
### CentOS 7 + zsh 5.1.1
```
sudo yum update -y
sudo yum install -y git make ncurses-devel gcc autoconf man yodl
git clone -b zsh-5.7.1 https://github.com/zsh-users/zsh.git /tmp/zsh
cd /tmp/zsh
./Util/preconfig
./configure
sudo make -j 20 install
```

# ToDo
* https://github.com/picatz/hunter

## Current Todo
* Place all included files into directory inc
* Check for ssh-key id_rsa if chmod 600 and if not ask to do it.
* If any packages aren't installed ask to install them.
* Flight check command to confirm what's setup and isn't, check packacges installed.
* Borrow or steal https://github.com/ohmyzsh/ohmyzsh/blob/master/tools/upgrade.sh

## Random Notes
- Figure out FZF wget https://github.com/junegunn/fzf-bin/releases/download/0.17.4/fzf-0.17.4-linux_amd64.tgz
- Look into diff so fancy wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
- git submodule add https://github.com/skx/sysadmin-util.git

```
antigen bundle wfxr/forgit
antigen bundle djui/alias-tips
antigen bundle desyncr/auto-ls
antigen bundle MikeDacre/careful_rm
antigen bundle viasite-ansible/zsh-ansible-server
antigen bundle micha/resty

cd $ZSH_CUSTOM/; git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
cp .fzf/shell/key-bindings.zsh $ZSH_CUSTOM//.fzf-key-bindings.zsh
cd /usr/local/sbin; wget https://github.com/junegunn/fzf-bin/releases/download/0.17.4/fzf-0.17.4-linux_amd64.tgz
cd $ZSH_CUSTOM/plugins; git clone https://github.com/horosgrisa/mysql-colorize
cd $ZSH_CSUTOM/plguins; git clone https://github.com/thetic/extract.git
```
