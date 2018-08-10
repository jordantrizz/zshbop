This is my custom ZSH configuration.

Base is 
˚
git submodule add https://github.com/zsh-users/antigen.git
# Mabye, still need to figure this out ? wget https://github.com/junegunn/fzf-bin/releases/download/0.17.4/fzf-0.17.4-linux_amd64.tgz
# wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy
git submodule add https://github.com/skx/sysadmin-util.git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle wfxr/forgit
antigen bundle fzf
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