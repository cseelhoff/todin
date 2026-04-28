{
  description = "TripleA Java→Odin port preparation toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "triplea-port-bootstrap";

          packages = with pkgs; [
            # JVM toolchain (TripleA needs JDK 21; ships javap for entity extraction)
            jdk21
            gradle

            # Odin compiler (Odin is the target language)
            odin

            # Glue scripting + database
            python3
            sqlite

            # Convenience
            git
            jq
            ripgrep
            unzip
          ];

          shellHook = ''
            export JAVA_HOME=${pkgs.jdk21.home}
            export PATH=$JAVA_HOME/bin:$PATH
            echo "triplea-port-bootstrap dev shell"
            echo "  JDK:    $(java -version 2>&1 | head -1)"
            echo "  Odin:   $(odin version 2>&1 | head -1)"
            echo "  Python: $(python3 --version)"
            echo "  SQLite: $(sqlite3 --version | awk '{print $1}')"
            echo ""
            echo "Run ./bootstrap.sh to build the full port-tracking database."
            echo "Or step through README.md one command at a time."
          '';
        };
      });
}
