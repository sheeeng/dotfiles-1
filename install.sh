#!/bin/bash

BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
GREEN=$(tput setaf 2)
STD=$(tput sgr0)

# This is a general-purpose function to ask Yes/No questions in Bash, either
# with or without a default answer. It keeps repeating the question until it
# gets a valid answer.

ask() {
    # http://djm.me/ask
    while true; do

        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo
        echo -n "    $1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read REPLY </dev/tty

        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

# Prints out the relative path between to absolute paths. Trivial.
#
# Parameters:
# $1 = first path
# $2 = second path
#
# Output: the relative path between 1st and 2nd paths
relpath() {
    local pos="${1%%/}" ref="${2%%/}" down=''

    while :; do
        test "$pos" = '/' && break
        case "$ref" in $pos/*) break;; esac
        down="../$down"
        pos=${pos%/*}
    done

    echo "$down${ref##$pos/}"
}

install_symlink () {
    if [ -z "$3" ]; then
        LINK_NAME=$2
    else
        LINK_NAME=$3
    fi

    if [ ! -e $HOME/$LINK_NAME ] && [ ! -d $HOME/$LINK_NAME ]; then
        cd $HOME
        ln -s "$(relpath "$PWD" "$1")"/$2 $3
        cd -
        echo "    ${GREEN}Installed symlink for $2${STD}";
    else
        echo "    ${YELLOW}Symlink for $2 already exists${STD}";
    fi
}

install_tmux () {
    if [ ! -e $HOME/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi
    install_symlink $PWD .tmux.conf
    install_symlink $PWD .tmuxline
}

is_tmux_installed () {
    if [ -e $HOME/.tmux.conf ] || [ -d $HOME/.tmux.conf ]; then
        echo "installed"
    fi
}

install_vim () {
    install_symlink $PWD .vimrc
}

is_vim_installed () {
    if [ -e $HOME/.vimrc ] || [ -d $HOME/.vimrc ]; then
        echo "installed"
    fi
}

install_git () {
    CHANGE_SETTINGS=0
    if [[ -z $is_git_installed ]]; then
        if ! ask "Do you like to change your git settings?" N; then
            CHANGE_SETTINGS=1
        fi
    fi
    if [[ $CHANGE_SETTINGS -eq 0 ]]; then
        echo
        echo "    Please enter your git user name and email address!"
        echo
        read -p "    ${BLUE}Name:${STD} " gitname
        read -p "    ${BLUE}Email:${STD} " gitemail
        echo
        sed -i "s/\(name\ =\ \).*$/\1$gitname/g" .gitconfig
        sed -i "s/\(email\ =\ \).*$/\1$gitemail/g" .gitconfig
        echo "    Replaced git name and email in .gitconfig"
    fi
    install_symlink $PWD .gitconfig
}

is_git_installed () {
    if [ -e $HOME/.gitconfig ] || [ -d $HOME/.gitconfig ]; then
        echo "installed"
    fi
}

install_bash () {
    install_symlink $PWD .bashrc
    install_symlink $PWD .liquidpromptrc
    install_symlink $PWD .lesspipe.sh
    install_symlink $PWD .LESS_TERMCAP
    git submodule update --init --remote
    install_symlink $PWD liquidprompt/liquidprompt .liquidprompt
    if ask "Do you like to install source highlighting in less and grep? [requires sudo]" Y; then
        if ! type "source-highlight" >/dev/null 2>&1; then
            if type "apt-get" >/dev/null 2>&1; then
                echo "    Insert your password to install source-highlight for less:"
                sudo apt-get --assume-yes install source-highlight 2>&1 >/dev/null
                echo "    Installed source-highlight for less"
            fi
            if type "pacman" >/dev/null 2>&1; then
                echo "    Insert your password to install source-highlight for less:"
                sudo pacman -S --noconfirm source-highlight 2>&1 >/dev/null
                echo "    Installed source-highlight for less"
            fi
        fi
    fi
}

is_bash_installed () {
    if [ -e $HOME/.bashrc ] &&
       [ -e $HOME/.liquidpromptrc ] &&
       [ -e $HOME/.lesspipe.sh ] &&
       [ -e $HOME/.LESS_TERMCAP ]; then
        echo "installed"
    fi
}

while :
do
    clear
    cat<<EOF
    =====================================
    Sappo's dotfile installer
    -------------------------------------
    Please enter which dotfile to install

    all         ${BLUE}(1)${STD}
    bashrc      ${BLUE}(2)${STD} - ${GREEN}$(is_bash_installed)${STD}
    gitconfig   ${BLUE}(3)${STD} - ${GREEN}$(is_git_installed)${STD}
    vimrc       ${BLUE}(4)${STD} - ${GREEN}$(is_vim_installed)${STD}
    tmux        ${BLUE}(5)${STD} - ${GREEN}$(is_tmux_installed)${STD}
                ${BLUE}(Q)uit${STD}
    -------------------------------------
EOF
    read -n1 -s
    case "$REPLY" in
    "1")
        install_tmux
        install_git
        install_vim
        install_bash
        ;;
    "2")
        install_bash
        ;;
    "3")
        install_git
        ;;
    "4")
        install_vim
        ;;
    "5")
        install_tmux
        ;;
    "q")  exit                      ;;
    "Q")  exit                      ;;
     * )  echo -e "    ${RED}Invalid option...${STD}";;
    esac
    echo
    read -p "    Press ${BLUE}[Enter]${STD} key to continue..." fackEnterKey
done
