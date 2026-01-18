#!/bin/sh
printf '\033c\033]0;%s\a' HyprRealm
base_path="$(dirname "$(realpath "$0")")"
"$base_path/HyprRealm.x86_64" "$@"
