#!/bin/bash
set -e
set -u

tmp="${TMPDIR:-/tmp}"
name="dev_env"
dir="${HOME}/Programming/${name}"
output="${tmp}/${name}_setup"
apt_args="--no-install-recommends --yes"

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

message $yellow "!!! Detailed command output is being written to ${output}"

function system_step {
    sudo apt-get update ${apt_args}
    sudo apt-get upgrade ${apt_args}
}
step "Upgrading system" system_step

function git_step {
    sudo apt-get install ${apt_args} git build-essential
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
    "${dir}/scripts/link_files.sh" "${dir}/dotfiles/linux" "${HOME}"
}
step "Linking dotfiles" link_step

function fonts_step {
    local font_zip="${tmp}/font.zip"
    local tmp_font_dir="${tmp}/font"
    local font_dir="/usr/local/share/fonts/truetype/JetBrainsMono"

    mkdir -p "${tmp_font_dir}"
    sudo mkdir -p "${font_dir}"

    curl -sSfL "https://download.jetbrains.com/fonts/JetBrainsMono-2.001.zip" 1>"${font_zip}" 2>>"${output}"
    unzip -d "${tmp_font_dir}" "${font_zip}"

    sudo mv "${tmp_font_dir}/ttf/No ligatures/"* "${font_dir}"
    fc-cache -v

    rm -rf "${font_zip}" "${tmp_font_dir}"
}
step "Installing fonts" fonts_step

function packages_step {
    local chrome_deb="${tmp}/chrome.deb"

    curl -sSfL "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" 1>"${chrome_deb}" 2>>"${output}"

    sudo apt-get install ${apt_args} "${chrome_deb}" kitty \
        openssh-server vim-gtk p7zip xsel zsh clang-tidy \
        shellcheck cmake valgrind golang clang nasm \
        graphviz jq

    curl -sSfL "https://sh.rustup.rs" | sh -s -- -y --no-modify-path

    curl -sSfL "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" | sh -s -- -b "$(go env GOPATH)/bin" "v1.33.0"
    go get \
        "github.com/nsf/gocode" \
        "golang.org/x/tools/cmd/goimports" \
        "github.com/google/gops"

    rm "${chrome_deb}"
}
step "Installing packages" packages_step

function shell_step {
    chsh -s "$(which zsh)"
    sudo chsh -s "$(which zsh)"
}
step "Configuring default shell" shell_step

function root_passwd_step {
    sudo passwd
}
step "Configuring root password" root_passwd_step

function cleanup_step {
    sudo apt-get clean ${apt_args}
    sudo apt-get autoremove ${apt_args}
}
step "Cleaning up apt" cleanup_step

message $green "==> Setup complete, a restart is advised"
message $green "==> Additional manual steps should be taken:"
message $green "-->   Set the systems monospace font to JetBrains Mono NL"
message $green "-->   run `vimupdate`"
message $green "-->   run `:GoInstallBinaries` inside `vim`"
