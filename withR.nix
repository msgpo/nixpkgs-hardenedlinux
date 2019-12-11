let
  pkgs = {
    ihaskell = builtins.fetchTarball {
      url = "https://github.com/gibiansky/IHaskell/tarball/bb2500c448c35ca79bddaac30b799d42947e8774";
      sha256 = "1n4yqxaf2xcnjfq0r1v7mzjhrizx7z5b2n6gj1kdk2yi37z672py";
    };

    #ghc864
    nixpkgs = builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs-channels/tarball/49dc8087a20e0d742d38be5f13333a03d171006a";
      sha256 = "1fdnqm4vyj50jb2ydcc0nldxwn6wm7qakxfhmpf72pz2y2ld55i6";
    };

  };

  ownpkgs = (import ~/.config/nixpkgs/nixos/channel/nixpkgs) { };
  rOverlay = rself: rsuper: {
    myR = rsuper.rWrapper.override {
      packages = with rsuper.rPackages; [ ggplot2 dplyr xts purrr cmaes cubature];
    };
  };

  foo = self: super: {
    haskell = super.haskell // { packageOverrides =
	    hself: hsuper: {
        my-random-fu-multivariate = hself.callPackage ./pkgs/random-fu-multivariate { };
      };
    };
  };
  nixpkgs  = import pkgs.nixpkgs { overlays = [ rOverlay foo]; };

  r-libs-site = nixpkgs.runCommand "r-libs-site" {
    buildInputs = with nixpkgs; [ R
                                   rPackages.ggplot2 rPackages.dplyr rPackages.xts rPackages.purrr rPackages.cmaes rPackages.cubature
                                  rPackages.reshape2
                                 ];
  } ''echo $R_LIBS_SITE > $out'';

  ihaskellEnv = (import "${pkgs.ihaskell}/release.nix" {
    compiler = "ghc864";
    nixpkgs  = nixpkgs;
  packages = self: [
    self.inline-r
    self.hmatrix
    # we can re-introduce this when it gets fixed
    # self.hmatrix-sundials
    self.random-fu
    self.my-random-fu-multivariate
  ];
  }).passthru.ihaskellEnv;

  systemPackages = self: [ self.myR ];


  vast = ownpkgs.callPackages ./pkgs/vast {};
  zat = nixpkgs.callPackages ./pkgs/python/zat {};
  editdistance = nixpkgs.callPackages ./pkgs/python/editdistance {};
  IPy = nixpkgs.callPackages ./pkgs/python/IPy {};
  networkx = nixpkgs.callPackages ./pkgs/python/networkx {};
  netaddr = nixpkgs.callPackages ./pkgs/python/netaddr {};
  tldextract = nixpkgs.callPackages ./pkgs/python/tldextract {};
  
  jupyterlab=nixpkgs.python3.withPackages (ps: [ ps.jupyterlab
                                                 ps.pandas
                                                 ps.matplotlib
                                                 ps.numpy
                                                 ps.scikitlearn
                                                 ps.setuptools
                                                 ps.sqlalchemy
                                                 networkx
                                                 zat
                                                 netaddr
                                                 editdistance
                                                 IPy
                                                 tldextract
                                               ]);
  rtsopts = "-M3g -N2";

  ihaskellJupyterCmdSh = cmd: extraArgs: nixpkgs.writeScriptBin "ihaskell-${cmd}" ''
    #! ${nixpkgs.stdenv.shell}
    export GHC_PACKAGE_PATH="$(echo ${ihaskellEnv}/lib/*/package.conf.d| tr ' ' ':'):$GHC_PACKAGE_PATH"
    export R_LIBS_SITE=${builtins.readFile r-libs-site}
    export PATH="${nixpkgs.stdenv.lib.makeBinPath ([ ihaskellEnv jupyterlab ] ++ systemPackages nixpkgs)}''${PATH:+:}$PATH"
    ${ihaskellEnv}/bin/ihaskell install \
      -l $(${ihaskellEnv}/bin/ghc --print-libdir) \
      --use-rtsopts="${rtsopts}" \
      && ${jupyterlab}/bin/jupyter ${cmd} ${extraArgs} "$@"
  '';
 gcc = nixpkgs.gcc8;
in
nixpkgs.buildEnv {
  name = "ihaskell-with-packages";
  buildInputs = [ nixpkgs.makeWrapper vast ];
  paths = [ ihaskellEnv jupyterlab ];
  postBuild = ''
    ln -s ${ihaskellJupyterCmdSh "lab" ""}/bin/ihaskell-lab $out/bin/
    ln -s ${ihaskellJupyterCmdSh "notebook" ""}/bin/ihaskell-notebook $out/bin/
    ln -s ${ihaskellJupyterCmdSh "nbconvert" ""}/bin/ihaskell-nbconvert $out/bin/
    ln -s ${ihaskellJupyterCmdSh "console" "--kernel=haskell"}/bin/ihaskell-console $out/bin/
    for prg in $out/bin"/"*;do
      if [[ -f $prg && -x $prg ]]; then
        wrapProgram $prg --set PYTHONPATH "$(echo ${jupyterlab}/lib/*/site-packages)"
      fi
    done
  '';
}