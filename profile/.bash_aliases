alias l='ls --color'
alias la='ls -A --color'
alias ll='ls -lhH --color'
alias L='ls -lhH --color'
alias La='ls -AlhH --color'
alias lal='ls -AlhH --color'

which ssed > /dev/null 2>&1 && alias sed=ssed
alias cdr='cd `realpath .`'

alias s='cd ..'
alias d='cd "$OLDPWD"'
alias p=pushd
alias P=popd

alias cm='cryptmount -m'
alias cum='cryptmount -u'

alias lc="cl"
cl() {
   if [ $# = 0 ]; then
      cd && ll
   else
      cd "$*" && ll
   fi
}

lgrep() {
   grep "$@" --color=always|less -R
}

foreach() {
	while read -r; do "$@" "$REPLY"; done
}
where() {
	export REPLY
	while read -r; do "$@" "$REPLY" && printenv REPLY; done
	export -n REPLY
}

alias md="mkdir -p"
function mc() {
  md "$*" && cd "$*" && pwd
}


fl() {
   find "$@" -type l
}
ff() {
   find "$@" -type f
}

id-copy () {
  [ -e ~/.ssh/id_rsa.pub ] && cat ~/.ssh/id_rsa.pub |ssh "$@" 'umask 077; test -d .ssh || mkdir .ssh ; cat >> .ssh/authorized_keys'
}

alias ill='sudo aptitude install'
alias sch='aptitude search'
alias zch='apt-cache search'
alias rem='sudo aptitude remove' 
alias shw='aptitude show' 
alias ge='q gedit'
alias o=sudo

source "`dirname \"${BASH_SOURCE[0]}\"`/.git_aliases"

#alias updb="doodle -bn -d /var/lib/doodle/doodle-locate.db -l libextractor_filename /"
#alias loc="doodle -d /var/lib/doodle/doodle-locate.db"
#ext()
#{
#	doodle -d /var/lib/doodle/doodle-locate.db .$1|grep \\.$1$
#}

alias updb="sudo doodle -bn -d /var/lib/doodle/doodle-locate.db -l libextractor_filename /home/eisd; sudo chgrp doodle /var/lib/doodle/doodle-locate.db; sudo doodle -bn -d /green/eisd/.doodle-locate.db -l libextractor_filename /green/eisd; sudo chgrp doodle /green/eisd/.doodle-locate.db; sudo doodle -b -d /green/eisd/.doodle.db /green/eisd/[^d]*; sudo chgrp doodle /green/eisd/.doodle.db"
alias updbd="sudo doodled -bn -d /var/lib/doodle/doodle-locate.db -l libextractor_filename /home/eisd & sudo doodled -bn -d /green/eisd/doodle-locate.db -l libextractor_filename /green/eisd & sudo doodled -b -d /green/eisd/.doodle.db /green/eisd/* &"
alias loc="doodle -d /var/lib/doodle/doodle-locate.db -d /green/eisd/.doodle-locate.db"
alias meta="doodle -d /green/eisd/.doodle.db"
ext()
{
	doodle -d /var/lib/doodle/doodle-locate.db -d /green/eisd/.doodle-locate.db .$1|grep \\.$1$
}

[ -f ~/bin/wrap_aliases ] && . ~/bin/wrap_aliases
[ -f ~/bin/profile/.git_aliases ] && . ~/bin/profile/.git_aliases
