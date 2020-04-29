# jordantrizz/ZSH
This is my custom ZSH configuration. It uses antigen to install ZSH plugins.

<a href="https://www.buymeacoffee.com/jordantrask" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" style="height: 51px !important;width: 217px !important;" ></a>

<!--ts-->
   * [jordantrizz/ZSH](README.md#jordantrizzzsh)
   * [Quick Install](README.md#quick-install)
   * [Advanced Install](README.md#advanced-install)
   * [Notes](README.md#notes)
      * [Windows Terminal](README.md#windows-terminal)
   * [Commands/Aliases](README.md#commandsaliases)
      * [Core](README.md#core)
      * [General](README.md#general)
      * [Coding](README.md#coding)
      * [Web](README.md#web)
      * [Ubuntu/Debian Specific](README.md#ubuntudebian-specific)
      * [Exim](README.md#exim)
      * [WSL](README.md#wsl)
   * [ToDo](README.md#todo)

<!-- Added by: jtrask, at: Wed Apr 29 08:59:02 PDT 2020 -->

<!--te-->

# Quick Install
```
bash <(wget -qO- https://raw.githubusercontent.com/jordantrizz/zsh/master/install)
```

# Advanced Install
<details><summary>Click to Reveal Advanced Install</summary>
<p>

If you don't want to have zsh within your home directory, then use the following.
1. Ensure you have zsh shell
```apt-get install zsh```
2. Clone repository to the directory of your choise
```git clone https://github.com/jordantrizz/zsh```
3. Copy .zshrc_install to ~/.zshrc or $HOME/.zshrc
```cp zsh/.zshrc_install ~/.zshrc```
4. Edit $ZSH_ROOT variable in your new ~/.zshrc to the path to the git cloned repository
***WARNING: don't use ~ use $HOME instead, as tilde doesn't work with zsh***
```sed -i 's/CHANGEME/zsh/g' .zshrc```
5. Restart your terminal/shell
</p>
</details>

# Notes

## Windows Terminal
There is an issue with some of the Powerline fonts I downloaded and installed in windows. So I opted for this set of fonts using a script in a GIST https://gist.github.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b

You can simply run this command within WSL

```
bash -c "$(curl -fsSL https://gist.githubusercontent.com/romkatv/aa7a70fe656d8b655e3c324eb10f6a8b/raw/install_meslo_wsl.sh)"
```

# Commands/Aliases
Type `commands` or `aliases` to get a list of commands and aliases. Doesn't work yet.
## Core
Alias | Description|
 --- | --- |
update | Update this repository an pull down any updates from sub-modules.
setup_environment | Installed the necessary packages.
pk | Print out all public keys in ".ssh" folder

## General 
Alias | Description|
 --- | --- |
fdcount | Count of files and directories in current directory.
update | Update this repository an pull down any updates from sub-modules.
setup_environment | Installed the necessary packages.
whatismyip | Checks opendns and tells you what your external IP address is.
listen | What's listening on what port.

## Coding
Command | Description|
 --- | --- |
toc | Runs patched gh-md-toc with --nobackup-insert on current directories README.md

## Web
Command | Description|
 --- | --- |
ttfb | Time To First Byte, uses curl. |
error_log | Recursively look for error_log files and tail. |
rm_error_log | Recursively look for error_log and prompt to delete. |
phpinfo | Generate a phpinfo.php file with phpinfo(); |
dhparam | Generate Diffie-Hellman key exchange. |
msds | MySQL Dump Search

## Ubuntu/Debian Specific
Command | Description|
 --- | --- |
apt-select | Get fastest Ubuntu/Debian mirror.
setup-cloud | Updates hostname, address cloud.cfg hostname peserve and fixes resolv.conf bug. Made in bash.

## Exim
Command | Description |
 --- | --- |
eximcq | Clears Exim queue of messages.

## WSL
Command | Description |
 --- | --- |
wsl-screen | Fixes screen error "Cannot make directory '/var/run/screen': Permission denied" when rebooting your system


# ToDo
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
