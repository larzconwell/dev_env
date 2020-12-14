#!/bin/bash
set -e
set -u

function list_contains {
    local list="${1}"
    local item="${2}"

    for list_item in ${list}; do
        if [[ "${list_item}" == "${item}" ]]; then
            echo "${item}"
            break
        fi
    done
}

function link_dir {
    local src="${1}"
    local dest="${2}"
    local ignores="${3}"
    local name

    for path in "${src}/"*; do
        name="$(basename "${path}")"
        local link="${dest}/.${name}"

        if [[ "$(list_contains "${ignores}" "${name}")" != "" ]]; then
            continue
        fi

        if [[ "${name}" == "config" ]]; then
            mkdir -p "${link}"

            for path in "${path}/"*; do
                name="$(basename "${path}")"
                local link="${link}/${name}"

                rm -rf "${link}"
                ln -s "${path}" "${link}"
            done
        else
            rm -rf "${link}"
            ln -s "${path}" "${link}"
        fi
    done
}

src="${1}"
dest="${2}"

if [[ -d "${src}" ]]; then
    link_dir "${src}" "${dest}" ""
fi
