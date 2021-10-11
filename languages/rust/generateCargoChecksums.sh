#! /usr/bin/env bash

generateCargoChecksums() {
  echo "  🖨 generating checksums for ${name:-}."
  for crate in "${out:-}"/src/rust/*; do
    if [ ! -f "$crate/.cargo-checksum.json" ]; then
      (cd "$crate" || return 1; find . -type f -exec sha256sum {} \; | \
        jq -Rn '{files: (reduce inputs as $val ({}; . + ($val | split("\\s+"; "")  | {(.[1]): (.[0])})))}' > \
        ../.cargo-checksum.json; mv ../.cargo-checksum.json .)
    fi
  done
  echo "  🖨 checksums generated!"
}

fixupOutputHooks+=(generateCargoChecksums)
