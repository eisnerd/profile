alias l='ls --color'
alias la='ls -A --color'
alias ll='ls -lH --color'
alias L='ls -lH --color'
alias La='ls -AlH --color'
alias lal='ls -AlH --color'

alias sed=ssed
alias cdr='cd `realpath .`'

alias s='cd ..'
alias d='cd $OLDPWD'
alias p=pushd
alias P=popd

fl()
{
        find "$@" -type l
}

alias ill='sudo aptitude install'
alias sch='aptitude search'
alias zch='apt-cache search'
alias rem='sudo aptitude remove' 
alias ge='q gedit'
alias o=sudo

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

. ~/bin/wrap_aliases
