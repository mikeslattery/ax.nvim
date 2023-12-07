#!/bin/bash

# Generate plugin help documentation
# Usage: doc/gendoc.sh <plugin-name>

set -euo pipefail

MODEL='gpt-4'
USERNAME='mikeslattery'
NAME="$1"

mdfile() {
  ext="$(echo -n "$1" | sed -E 's/^.*\.([^\.]*)$/\1/;')"
  echo -e '
File: '"$1"'

```'"${ext}"'
'"$(cat "$1")"'
```'
}

prompt() {
  examples='https://raw.githubusercontent.com/folke/lazy.nvim/main/lua/lazy/example.lua'

  echo "Here is example use of lazy.nvim package manager:"
  echo ''
  echo '```lua'
  curl -sSf "$examples"
  echo '```'
  echo ''

  echo "These files are for a Neovim plugin called ${NAME}:"
  for file in $(git ls-files | grep -E '.\.(lua|vim|txt)$|Makefile'); do
    mdfile "$file"
  done
  echo ''
  echo "The current date is $(date)."
  echo "The ${NAME} plugin repo is at https://github.com/$USERNAME/${NAME}.nvim"
  echo ''
  echo 'INSTRUCTION:'
  echo "Generate doc/${NAME}.txt for $NAME plugin, in raw vim help file format."
  echo "Any install instructions should be based on vim-plug and lazy.nvim package managers."
  echo "Include a copyright and mention of MIT license."
}

ai() {
  openai api chat.completions.create -m "$MODEL" -g user "$(cat)"
}

main() {
  echo "Generating doc/${NAME}.txt ..." >&2

  prompt | ai > "doc/${NAME}.txt"

  echo 'Finished.' >&2
}

main
