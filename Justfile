default := "build"
set dotenv-load := true

build:
  swift build

run:
  swift run

test:
  swift test

clean:
  rm -rf .build

config-dir:
  echo "$HOME/Library/Application Support/Poof"

import-raycast FILE OUTPUT_DIR='':
  bash -lc 'set -euo pipefail; if [ -n "{{OUTPUT_DIR}}" ]; then bin/import-raycast-snippets "{{FILE}}" "{{OUTPUT_DIR}}"; else bin/import-raycast-snippets "{{FILE}}"; fi'
