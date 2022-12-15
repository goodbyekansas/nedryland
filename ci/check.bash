#! @bash@
# shellcheck shell=bash

set -uo pipefail
shopt -s nullglob
shopt -s extglob

export NEDRYLAND_CHECK_COLOR=1
emoji_index=0
emojis=("🧶" "🏫" "🥥" "🐚" "🥚" "🦪")
for file in "$(dirname "${BASH_SOURCE[0]}")"/!(check); do
    echo -e "Running \e[032m$(basename "$file")\e[0m..."
    $file 2>&1 | @sed@ "s,^,  [ ${emojis[$emoji_index]} $(basename "$file") ] ,"
    emoji_index=$(( (emoji_index+1)%${#emojis[@]} ))
done
