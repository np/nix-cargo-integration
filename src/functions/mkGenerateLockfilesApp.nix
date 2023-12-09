{
  pkgs,
  lib,
  projects,
  buildToolchain,
  source,
}: let
  l = lib // builtins;
in
  pkgs.writeScript "generate-lockfiles" ''
    #!/usr/bin/env bash
    function addToGit() {
      if [ ! -e "$1" ]; then
        echo "Missing generated file $1"
        exit 1
      fi
      if [ -d ".git" ]; then
        git add $1
      fi
    }
    ${
      l.concatMapStringsSep
      "\n"
      (
        project: let
          relPath = l.removePrefix (toString source) (toString project.path);
          trimSlashes = str: l.removePrefix "/" (l.removeSuffix "/" str);
          cargoTomlPath = trimSlashes "${relPath}/Cargo.toml";
          cargoLockPath = trimSlashes "${relPath}/Cargo.lock";
        in ''
          [ ! -e Cargo.lock ] || mv Cargo.lock Cargo.lock.bak
          ${buildToolchain}/bin/cargo generate-lockfile --manifest-path ${cargoTomlPath}
          mv Cargo.lock ${cargoLockPath}
          [ ! -e Cargo.lock.bak ] || mv Cargo.lock.bak Cargo.lock
          addToGit ${cargoLockPath}
        ''
      )
      (l.attrValues projects)
    }
  ''
