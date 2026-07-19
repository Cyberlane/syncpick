#!/bin/sh
set -eu

test "$(zsh ./syncpick --version)" = "syncpick 0.1.0"
zsh ./syncpick --help >/dev/null
zsh ./install --help >/dev/null
test "$(zsh -c 'selected=$'"'"'media-server\t(last used)'"'"'; print -r -- "${selected%%$'"'"'\t'"'"'*}"')" = "media-server"
test "$(zsh -c 'sources=("/srv/anime" "/srv/tv"); command="find"; for source in "${sources[@]}"; do command+=" ${(q)source}"; done; print -r -- "$command"')" = "find /srv/anime /srv/tv"
test "$(zsh -c 'print -rl -- "Add profile" "Edit profile" | wc -l | tr -d " "')" = "2"
test "$(zsh -c 'printf "%-28s  %s\\t%s\\n" "Edit connection" host edit_connection | cut -f1')" = "Edit connection               host"
test "$(zsh -c 'row=$'"'"'/srv/media/show\t[folder] /srv/media/show'"'"'; print -r -- "${row%%$'"'"'\t'"'"'*}"')" = "/srv/media/show"
test "$(zsh -c 'path="/srv/media/show"; print -r -- "${path%/*}/|${path##*/}"')" = "/srv/media/|show"
test "$(zsh -c 'path="/srv/media/show"; parent="${path%/*}"; print -r -- "…/${parent##*/}/${path##*/}"')" = "…/media/show"
test "$(zsh -c 'path="/show"; parent="${path%/*}"; if [[ -z "$parent" || "$parent" == "/" ]]; then print -r -- "$path"; else print -r -- "…/${parent##*/}/${path##*/}"; fi')" = "/show"
test "$(zsh -c 'mode=short; case "$mode" in full) print full ;; short) print shortened ;; name) print name ;; esac')" = "shortened"
echo "tests: OK"
