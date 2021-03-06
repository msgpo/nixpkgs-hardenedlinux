{ stdenv
, python3Packages
, python3
}:
with python3.pkgs;
python3Packages.buildPythonPackage rec {
   pname = "jupyter_server";
    version = "0.1.1";
    src = fetchPypi {
      inherit pname version;
      sha256 = "121q60ilx0i8fh0ixzj835cv1naaakivckwmvw9mxnmqrb6fdf1y";
    };
    doCheck = false;
    propagatedBuildInputs = with python3Packages; [ nbformat
                                                    tornado
                                                    ipykernel
                                                    jinja2
                                                    nbconvert
                                                    bleach
                                                    (python3Packages.buildPythonPackage rec {
                                                      pname = "Send2Trash";
                                                      version = "1.5.0";
                                                      src = python3Packages.fetchPypi {
                                                        inherit pname version;
                                                          sha256 = "1ci8vcwjmjlp11ljj1ckrfmml9fkq1mclx2gr53y4zvhgp01q030";
                                                      };
                                                      doCheck = false;
                                                      propagatedBuildInputs = with python3Packages; [  ];
                                                    })
                                                    pygments
                                                    (python3Packages.buildPythonPackage rec {
                                                      pname = "jupyterlab_pygments";
                                                      version = "0.1.0";
                                                      src = python3Packages.fetchPypi {
                                                        inherit pname version;
                                                        sha256 = "1id54fff3hhg4ya1qp7k9hnyy15ak5hrziv40wci9c0ipmsxmpii";
                                                      };
                                                      doCheck = false;
                                                      propagatedBuildInputs = with python3Packages; [ pygments ];
                                                    })
                                                    terminado
                                                    prometheus_client
                                                    jupyter_client
                                                    pytest
                                                  ];

    postPatch = ''
    substituteInPlace setup.py \
    --replace "nbconvert" "pytest"
    '';

}
