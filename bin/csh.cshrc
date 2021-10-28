#-----------------------------------------------------------------------------
#
# Simon's happy .cshrc file, revision 1.0.
#
# If you're boring and think colours are for weird people, please make
# your own ~/.cshrc.yourusername and your life will be boring again.
#
# If you want to make some changes to my setup, you can create
# ~/.cshrc.pre to make changes before mine, and
# ~/.cshrc.post to make changes after mine.
#
# For machine-specific aliases and other settings, please make changes
# to .login (I don't overwrite/distribute that file).
#
#-----------------------------------------------------------------------------

if (-f ~/.cshrc."$USER") then
   source ~/.cshrc."$USER"
else

if (-f ~/.cshrc."$USER".pre) then
   source ~/.cshrc."$USER".pre
endif

if ("$SHLVL" == 1 && $?term && $?tty && "$tty" != "") then
   echo -n 'Parsing ".cshrc"...'
endif

umask 022

set path=(/bin /usr/bin /usr/local/bin /usr/local/bin/sim /sbin /usr/sbin /usr/local/sbin /usr/X11/bin /usr/games . $HOME/bin)
set cdpath=(/var/spool /home /usr/local /usr/src /)
set addsuffix autocorrect autoexpand autolist nobeep
unset autologout backslash_quote correct fignore listlinks
set history = 10000
set savehist = (1000 merge)
set listjobs
set echo_style=both
set cprompt='%{\015\033[0;1;35m%}[%{\033[1;36m%}%n%{\033[0;30m%}@%{\033[1;32m%}%m%{\033[1;34m%}:%{\033[1;33m%}%/%{\033[0;1;35m%}]%{\033[1;31m%}%#%{\033[0m%} '
set cprompt2='%{\015\033[0;1;35m%}[%{\033[1;36m%}%n%{\033[0;30m%}@%{\033[1;32m%}%m%{\033[1;34m%}:%{\033[1;33m%}(%R)%{\033[0;1;35m%}]%{\033[1;31m%}%#%{\033[0m%} '
set cprompt3='%{\015\033[0;1;35m%}[%{\033[1;36m%}%n%{\033[0;30m%}@%{\033[1;32m%}%m%{\033[1;34m%}:%{\033[1;33m%}(%R)%{\033[0;1;35m%}]%{\033[1;31m%}%#%{\033[0m%} '
set nprompt='[%n@%m:%/]%# '
set prompt="$cprompt" prompt2="$cprompt2" prompt3="$cprompt3"
set mail = ( 5 ${HOME}/mail/inbox /var/mail/${USER} /var/spool/mail/${USER} )

if (-x /bin/dircolors) eval `/bin/dircolors -c`
#if (-x /usr/bin/dircolors) eval `/usr/bin/dircolors -c`
#if (! $?LS_COLORS) 
setenv LS_COLORS 'no=00:fi=00:di=01;35:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.png=01;35:*.mpg=01;35:*.avi=01;35:*.gl=01;35:*.dl=01;35:'
if (! $?LS_OPTIONS) setenv LS_OPTIONS '--color=auto -F -T 0'

setenv PAGER            'less -Q -j16'
setenv EDITOR           'joe' 
setenv BLOCKSIZE        'K'
setenv TERM             'xterm'

bindkey "\e[1~" beginning-of-line       # Home
bindkey "\e[2~" overwrite-mode          # Ins
bindkey "\e[3~" delete-char             # Delete
bindkey "\e[4~" end-of-line             # End
bindkey ^[^J spell-line
bindkey ^W i-search-back

complete {cd,chdir,rmdir,mkdir} 'n/*/d/'
complete {zcat,zgrep} 'n/*/f:*.{Z,gz,bz,bz2}/'
complete gunzip 'n/*/f:*.{Z,gz,tgz}/'
complete bunzip 'n/*/f:*.bz/'
complete bunzip2 'n/*/f:*.bz2/'
complete {exec,strace} 'p/1/c/'
complete {which,where} 'n/*/c/'
complete {edithost,delhost,sm,whois} 'p@1@`cat /g/lib/domainlist`@'
complete {host,ping,traceroute,rtrace,mtr} 'p@1@`cat /g/lib/domainlist;echo $hosts $classcs`@'
complete newip 'p@1@`cat /g/lib/domainlist`@' 'p/2/$hosts/.'
complete lynx 'C@[./]*@f@' 'c@*/@(mkstats server-status)@' 'n@*@`cat /g/lib/domainlist;echo $hosts`@/'
complete addhost 'p@1@`cat /g/lib/domainlist`@' 'p/2/`echo $hosts $classcs`/.'
complete {add?*,del?*} 'p@1@`cat /g/lib/domainlist`@'
complete {grepmail,queuestats*,zonedit,accttype,testfp} 'n@*@`cat /g/lib/domainlist`@'
complete {er,vr} 'p@1@(domainaliases exploders)@' 'p@2@`cat /g/lib/domainlist`@'
complete distro 'p@2-@$hosts@'
complete finger 'c/*@/$hosts/' 'n/*/u/@'
complete arp 'p@*@`cat /g/lib/domainlist;echo $hosts`@'
complete pinef 'p@1@`ls -1 /var/spool/mail/`@'
complete killall 'n@*@`grep Name: /proc/[0-9]*/status | cut -f2 | sort | uniq`@'

complete chown 'p/2-/f/' 'c/?*[.:]/g/' 'p/1/u/:'
complete chgrp 'p/1/g/'
complete scp 'C@./*@f@' 'c/*:/f/'
complete ssh 'p/1/$hosts/'
complete look 'p@1@`look '"'"'$:1'"'"' $:2`@'
complete make 'n@*@`egrep -h "^[^:/ ]*:" [Mm]akefile | sed "s/:.*//" | sort | uniq`@'
complete co 'n@*@`\ls -1 RCS/ | egrep ,v | rev | cut -c3- | rev`@'

complete complete 'p/1/X/'
complete uncomplete 'n/*/X/'
complete set 'c/*=/f/' 'p/1/s/=' 'n/=/f/'
complete unset 'n/*/s/'
complete setenv 'c/*=/f/' 'n/*/e/'
complete unsetenv 'n/*/e/'
complete which 'n/*/c/'

complete '/etc/init.d/*' 'n/*/(restart start stop)/'

alias add 'perl -lpe '"'"'$x+=$_}{$_=$x'"'"
alias backwards 'perl -pe '"'"'unshift(@x,$_)}{map{print}@x'"'"
alias beep 'echo -n "\033[10;562]\007\033[10]"'
alias bz2gz 'set a="\!^";set b="$a:r";bzip2 -dc "$a" | gzip -n9 -> "$b.gz" && rm -f -- "$a";unset a b'
alias cascii "echo 'x(Ux)U' | tr x '\033'"
alias cd- 'cd -'
alias cd.. 'cd ..'
alias cdc 'cd `pwd`'
alias cp cp -v
alias cpoff 'set prompt="$nprompt"'
alias cpon 'set prompt="$cprompt"'
alias df df --no-sync
alias d 'dig'
alias dir ls -al
alias dorsync 'rsync -e ssh -z'
alias dupd 'mkdir _tmpdupd.$$ && \cp -a \!^ _tmpdupd.$$ && mv _tmpdupd.$$/\!^ ./\!$ && rmdir _tmpdupd.$$'
alias gzbz2 'set a="\!^";set b="$a:r";gzip -dc -- "$a" | bzip2 -9 -> "$b.bz2" && rm -f -- "$a";unset a b'
alias h 'host'
alias hup kill -1
alias hupall killall -1
alias j 'jobs'
alias l ls -al
alias less $PAGER
alias ls 'ls $LS_OPTIONS'
alias lsd ls -altr --full-time
alias lss ls -alsr --sort=size
alias ma 'cd /;umount /a;mount /a;cd /a'
alias mcd 'mkdir -- \!*;cd \!$'
alias md mkdir
alias mountcd 'mount -t iso9660 -o ro /dev/cdrom /cdrom'
alias mtr 'mtr -t $1'
alias mycursor 'echo "\033[?17;95;255c"'
alias nano 'nano -w'
alias ncftp ncftp -L
alias osdefs ':|gcc -E -dM -'
alias pico pico -w -z
alias pine pine -feature-list=enable-bounce-cmd,enable-full-header-cmd,enable-suspend,enable-tab-completion,signature-at-bottom,enable-alternate-editor-cmd,delete-skips-deleted,save-will-advance,include-attachments-in-reply,enable-background-sending,quell-status-message-beeping,enable-unix-pipe-cmd,enable-aggregate-command-set,auto-open-next-unread,enable-flag-cmd,enable-goto-in-file-browser,enable-jump-shortcut,enable-mail-check-cue,reply-always-uses-reply-to,expunge-without-confirm
alias pinef 'pine -I i -f ../../../var/spool/mail/\!*'
alias pines 'pine -i -sort subject -f support'
alias rc "echo perl -pi -e 's/\r\n/\n/'"
alias regz 'gzip -dc -- \!^ | gzip -n9 -> \!^.$$ && mv -- \!^.$$ \!$'
alias remount 'umount \!* && mount \!*'
alias rmcd 'set a=`pwd` && cd .. && rmdir -- "$a";unset a'
alias rxvt 'rxvt -bg black -fg white -sl 1024'
alias scpf 'scp -o "Compression no" -c arcfour'
alias simindent 'indent -bap -sob -npcs -br -ce -lp -ci1 -i3 -l76 -ts0 -d0 -ip0'
alias staff 'echo 204.174.223.110;echo 216.139.254.194'
alias t 'telnet'
alias uma 'cd /;umount /a'
alias umcd 'set a=`pwd` && cd .. && umount "$a";unset a'
alias uncpio cpio --extract --preserve-modification-time --make-directories
alias untar 'set a="\!^";set b="$a:e:s/tgz/gz/:s/z/zip/";$b -dc "$a" | tar xf -'
alias untarv 'set a="\!^";set b="$a:e:s/tgz/gz/:s/z/zip/";$b -dc "$a" | tar xvf -'
alias joe 'joe --wordwrap -nobackups'

echo "#if (__GNUC__ > 2) || (__GNUC__ == 2 && __GNUC_MINOR__ >= 95)\n#define NEW_GCC_VER\n#endif" | gcc -E -dM - | fgrep -q NEW_GCC_VER
if ("$?" == 1) then
 # Older (< 2.95) GCC
 alias setcflags 'setenv CFLAGS "-s -O2 -m486 -malign-loops=2 -malign-jumps=2 -malign-functions=2 -fomit-frame-pointer \!*"'
 alias setoldcflags 'setenv CFLAGS "-s -O2 -m486 -malign-loops=2 -malign-jumps=2 -malign-functions=2 -fomit-frame-pointer \!*"'
 alias setdebugcflags 'setenv CFLAGS "-g3 -O2 -m486 -malign-loops=2 -malign-jumps=2 -malign-functions=2 \!*"'
 alias setsmallcflags 'setenv CFLAGS "-s -O1 -m486 -malign-loops=1 -malign-jumps=1 -malign-functions=1 -fomit-frame-pointer \!*"'
else
 # Newer (>= 2.95) GCC
 alias setcflags 'setenv CFLAGS "-s -O2 -march=i686 -fomit-frame-pointer -fno-strict-aliasing -mpreferred-stack-boundary=2 \!*"'
 alias setoldcflags 'setenv CFLAGS "-s -O2 -m486 -malign-loops=2 -malign-jumps=2 -malign-functions=2 -fomit-frame-pointer \!*"'
 alias setdebugcflags 'setenv CFLAGS "-g3 -O2 -m486 -malign-loops=2 -malign-jumps=2 -malign-functions=2 -fno-strict-aliasing \!*"'
 alias setsmallcflags 'setenv CFLAGS "-s -O1 -m486 -malign-loops=1 -malign-jumps=1 -malign-functions=1 -fomit-frame-pointer -fno-strict-aliasing \!*"'
endif

alias rcsedit '(set a=(`find . -maxdepth 1 -name "\!^" -printf "%m %u %g %p "`); rcs -l ${a[4]:q} ; chown ${a[2]:q}:${a[3]:q} ${a[4]:q}; chmod u+w ${a[4]:q}; $EDITOR:q ${a[4]:q}; ci -u ${a[4]:q}; chown ${a[2]:q}:${a[3]:q} ${a[4]:q}; chmod ${a[1]:q} ${a[4]:q})'

# Enable colourized 'w' if available
w -cshuf >&/dev/null && alias w 'w -c'

alias precmd 'echo -n "\033[1;35m";jobs;echo -n "\033[0m"'

alias sa 'rm -f ~/.ssh-agent.env.$USER ; ( umask 077 ; ssh-agent > ~/.ssh-agent.env.$USER ) && source ~/.ssh-agent.env.$USER ; ssh-add'
alias aa 'source ~/.ssh-agent.env.$USER'
alias ka 'source ~/.ssh-agent.env.$USER ; ( umask 077 ; ssh-agent -k > ~/.ssh-agent.env.$USER ) ; source ~/.ssh-agent.env.$USER ; rm -f ~/.ssh-agent.env.$USER'

alias npc 'rm -f ~/.local-notepad'
alias npi 'cat >> ~/.local-notepad'
alias npo 'cat ~/.local-notepad'

setcflags

if ("$SHLVL" == 1 && $?term && $?tty && "$tty" != "") then
   echo -n '\r'
   if ("$?USER" && "$USER" != croot && "$USER" != nop) then
      echo "\033[1;34mUser \033[33m$user \033[30m(\033[31m$uid\033[30m)\033[34m logged in on \033[33m$tty \033[30m(\033[31m$term\033[30m)\033[34m at \033[33m`date`\033[34m.\033[35m"
      uptime
   endif
   if (-e ~/.ssh-agent.env.$USER) then
      echo -n "\033[1;36m"
      source ~/.ssh-agent.env.$USER
      echo -n "\033[m"
   endif
endif

if (-f ~/.cshrc."$USER".post) then
   source ~/.cshrc."$USER".post
endif

endif

:
