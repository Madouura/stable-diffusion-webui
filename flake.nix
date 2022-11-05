{
  description = "Stable Diffusion WebUI";

  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; };

  outputs = {
    self,
    nixpkgs
  } @inputs: let
    supportedSystems = [ "x86_64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    nixpkgsFor = forAllSystems (system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    } );
  in {
    devShells = forAllSystems ( system: let
      pkgs = nixpkgsFor.${ system };
    in {
      default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          git
          stdenv.cc.cc.lib
          glib
          zlib
          libGL
          python3
          python3Packages.venvShellHook
        ];

        venvDir = "venv";

        postShellHook = ''
          export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.glib.out}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH"
          export TORCH_COMMAND="pip install torch torchvision --extra-index-url https://download.pytorch.org/whl/rocm5.1.1"
          pip install --upgrade pip wheel
          $TORCH_COMMAND
          git clone https://github.com/facebookresearch/xformers.git repositories/xformers > /dev/null 2>&1
          cd repositories/xformers
          git pull
          git submodule update --init --recursive
          pip install -r requirements.txt
          pip install -e .
          cd ../..
          python launch.py --xformers --no-half --precision full
          exit
        '';
      };
    } );
  };
}
