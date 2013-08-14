export EDITOR=vim
export LESS="-QRMWi -j4"

eval "$(dircolors -b ~/.dircolors)"

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

