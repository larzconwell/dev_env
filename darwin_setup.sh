#!/bin/bash
set -e
set -u

tmp="${TMPDIR:-/tmp}"
name="dev_env"
dir="${HOME}/Programming/${name}"
output="${tmp}/${name}_setup"

cyan="$(tput setaf 6)"
red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"

function message {
    echo "${*}$(tput sgr0)"
    echo "${*:2}" &>>"${output}"
}

function step {
    message $cyan "==> ${1}"
    ${*:2} &>>"${output}"
    message $green "--> Done"
}

function step_no_redirect {
    message $cyan "==> ${1}"
    ${*:2}
    message $green "--> Done"
}

message $yellow "!!! Detailed command output is being written to ${output}"

function brew_step {
    if [[ ! -f "$(which brew 2>/dev/null)" ]]; then
        curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/master/install.sh" | bash

        brew analytics off
        brew tap homebrew/cask-versions
        brew tap homebrew/cask-fonts

        export PATH="/usr/local/bin:${PATH}"
    fi
}
step "Installing brew" brew_step

function git_step {
    brew install git
}
step "Installing git" git_step

function clone_step {
    if [[ -d "${dir}" ]]; then
        rm -rf "${dir}"
    fi

    git clone "git@github.com:larzconwell/${name}.git" "${dir}"
}
step "Cloning ${name}" clone_step

function link_step {
    "${dir}/scripts/link_files.sh" "${dir}/dotfiles/unix" "${HOME}"
    "${dir}/scripts/link_files.sh" "${dir}/dotfiles/darwin" "${HOME}"
}
step "Linking dotfiles" link_step

function fonts_step {
    brew cask install font-jetbrains-mono --fontdir=/Library/Fonts
}
step "Installing fonts" fonts_step

function packages_step {
    brew cask install google-chrome docker kitty spectacle \
        postgres firefox 1password dropbox intellij-idea-ce \
        adoptopenjdk8 zoomus slack keybase phantomjs tuple \
        notion tunnelblick browserstacklocal

    brew tap movableink/formulas
    brew tap beeftornado/rmtree

    brew install beeftornado/rmtree/brew-rmtree \
        rsync wget curl p7zip openssh openssl \
        imagemagick cmake zsh gdb go \
        golangci/tap/golangci-lint rust python \
        clang-format vim ack graphviz jq icu4c libxslt \
        maven sbt geoip cassandra redis s3cmd hub node \
        scala@2.11 movableink/formulas/nsqlookupd \
        movableink/formulas/nsqd movableink/formulas/nsqadmin \
        movableink/formulas/nsqutils movableink/formulas/qt \
        movableink/formulas/qtwebkit movableink/formulas/apache-spark

    sudo pip3 install awscli

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    source "${HOME}/.nvm/nvm.sh"

    nvm install 10.19.0
    nvm alias default 10.19.0

    set +u
    curl -sSL https://get.rvm.io | bash -s stable
    source "${HOME}/.rvm/scripts/rvm"

    rvm install 2.6.5
    rvm --default use 2.6.5
    set -u

    gem install lunchy depl

    go get \
        "github.com/nsf/gocode" \
        "golang.org/x/tools/cmd/goimports" \
        "github.com/google/gops"
}
step "Installing packages" packages_step

function shell_step {
    chsh -s "$(which zsh)"
    sudo chsh -s "$(which zsh)"
}
step_no_redirect "Configuring default shell" shell_step

function root_passwd_step {
    sudo passwd -q
}
step_no_redirect "Configuring root password" root_passwd_step

message $green "==> Setup complete, a restart is advised"
message $green "==> Additional manual steps should be taken:"
message $green "-->   Set the systems monospace font to JetBrains Mono NL"
