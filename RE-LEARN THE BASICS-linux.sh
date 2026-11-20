#!/bin/sh
printf '\033c\033]0;%s\a' RE-LEARN THE BASICS
base_path="$(dirname "$(realpath "$0")")"
"$base_path/RE-LEARN THE BASICS-linux.x86_64" "$@"
