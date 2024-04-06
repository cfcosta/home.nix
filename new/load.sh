#!/usr/bin/env bash

set -e

rm -f prompt.md

echo -e "<response-format>Respond with ONLY the changed files, with instructions to add or remove new ones if necessary.</response-format>\n" >> prompt.md

find . -type f | grep -v ".sh" | grep -v ".md" | grep -v ".lock" | while read file; do
  echo "<file path=\"$file\">"
  cat "$file"
  echo "</file>"
  echo
done >> prompt.md

echo "Done, generated prompt.md."
