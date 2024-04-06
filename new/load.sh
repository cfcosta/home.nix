#!/usr/bin/env bash

set -xe

TEMP="$(mktemp)"

echo -e "<instructions>Your task is to implement the user request on the given files, creating new ones if necessary, or asking questions before continuing if not clear enough. Respond with the changed files.</instructions>\n" | tee prompt.md

find . -type f | grep -v ".sh" | grep -v ".md" | while read file; do
  echo "<file path=\"$file\">"
  cat "$file"
  echo "</file>"
  echo
done | tee -a prompt.md

echo "Done, generated prompt.md."
