{stdenv, fetchgit, cmake, clang, python3, cudatoolkit}:

stdenv.mkDerivation rec {
  version = "master";
  name = "libclx";
  src = fetchgit {
    url = "https://github.com/rapidsai/clx";
    rev = "6cbe4830ac2a5f151445df1f33404d1949716bfd";
    sha256 = "0mnh57p4jc9bjczbkyqqzfy4mpzdqz1ypmam2lyh61p0xrgqrvsr";
  };
  preConfigure = ''
  cd cpp
  '';
    nativeBuildInputs = [ cmake cudatoolkit python3 clang];
  buildInputs = [ cmake ];

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "clx";
  };
}
