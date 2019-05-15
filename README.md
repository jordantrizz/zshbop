<!--ts-->
   * [jordantrizz/ZSH](#jordantrizzzsh)
   * [Quick Install](#quick-install)
   * [Advanced Install](#advanced-install)
   * [Commands](#commands)
      * [General](#general)
      * [Web](#web)
      * [Ubuntu/Debian](#ubuntudebian)
   * [ToDo](#todo)

<!-- Added by: jtrask, at: Thu  9 May 2019 09:05:23 PDT -->

<!--te-->
# jordantrizz/ZSH
This is my custom ZSH configuration. It uses antigen to install ZSH plugins.

# Quick Install
Simply run the following in your home directory
```git clone https://github.com/jordantrizz/zsh.git;zsh/install```
# Advanced Install
If you don't want to have zsh within your home directory, then use the following.

1. Ensure you have zsh shell
```apt-get install zsh```
2. Clone repository to the directory of your choise
```git clone https://github.com/jordantrizz/zsh```
3. Copy .zshrc_install to ~/.zshrc or $HOME/.zshrc
```cp zsh/.zshrc_install ~/.zshrc```
4. Edit $GIT_ROOT variable in your new ~/.zshrc to the path to the git cloned repository
***WARNING: don't use ~ use $HOME instead, as tilde doesn't work with zsh***
```sed -i 's/CHANGEME/zsh/g' .zshrc```
5. Restart your terminal/shell

# Commands/Aliases
## General
Command | Description|
 --- | --- |
update | Update this repository an pull down any updates from sub-modules.
setup_environment | Installed the necessary packages.
## Coding
Command | Description|
 --- | --- |
toc | Runs patched gh-md-toc with --nobackup-insert on current directories README.md
## Web
Command | Description|
 --- | --- |
ttfb | Time To First Byte, uses curl.
error_log | Recursively look for error_log files and tail.
rm_error_log | Recursively look for error_log and prompt to delete.
phpinfo | Generate a phpinfo.php file with phpinfo();
dhparam | Generate Diffie-Hellman key exchange.
## Ubuntu/Debian
Command | Description|
 --- | --- |
apt-select | Get fastest Ubuntu/Debian mirror.

# ToDo
- Figure out FZF wget https://github.com/junegunn/fzf-bin/releases/download/0.17.4/fzf-0.17.4-linux_amd64.tgz
- Look into diff so fancy wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
- git submodule add https://github.com/skx/sysadmin-util.git
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
