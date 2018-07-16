{ fetchPypi
, lib
, stdenv
, darwin
, openglSupport ? true
, libX11
, wxGTK
, wxmac
, pkgconfig
, buildPythonPackage
, pyopengl
# , isPy3k
# , isPyPy
, python
, cairo
, pango
, gnome3
}:

assert wxGTK.unicode;

buildPythonPackage rec {
  pname = "wxPython";
  version = "4.0.3";

  # disabled = isPy3k || isPyPy;
  # doCheck = false;

  src = fetchPypi {
    inherit pname version;
    sha256 = "0xcynlqr1j76pmblmg6m17l74qw2q9ff6xfm0374jiy28q0zq3cd";
  };

  hardeningDisable = [ "format" ];

  propagatedBuildInputs = [ pkgconfig ]
    ++ (lib.optional openglSupport pyopengl)
    ++ (lib.optionals (!stdenv.isDarwin) [ wxGTK (gnome3.gtk) libX11 ])
    ++ (lib.optionals stdenv.isDarwin [ wxmac darwin.apple_sdk.frameworks.Cocoa ])
    ;
  preConfigure = ''
    # remove wxPython's darwin hack that interference with python-2.7-distutils-C++.patch
    # substituteInPlace buildtools/distutils_hacks.py \
    #   --replace "distutils.unixccompiler.UnixCCompiler = MyUnixCCompiler" ""

    # set the WXPREFIX to $out instead of the storepath of wxwidgets
    substituteInPlace buildtools/config.py \
      --replace "WXPREFIX   = self.getWxConfigValue('--prefix')" "WXPREFIX   = '$out'"

    # this check is supposed to only return false on older systems running non-framework python
    # substituteInPlace src/osx_cocoa/_core_wrap.cpp \
    #   --replace "return wxPyTestDisplayAvailable();" "return true;"
  '' + lib.optionalString (!stdenv.isDarwin) ''
    substituteInPlace wx/lib/wxcairo/wx_pycairo.py \
      --replace 'cairoLib = None' 'cairoLib = ctypes.CDLL("${cairo}/lib/libcairo.so")'

    substituteInPlace wx/lib/wxcairo/wx_pycairo.py \
      --replace '_dlls = dict()' '_dlls = {k: ctypes.CDLL(v) for k, v in [
        ("gdk",        "${gnome3.gtk}/lib/libgtk-x11-2.0.so"),
        ("pangocairo", "${pango.out}/lib/libpangocairo-1.0.so"),
        ("appsvc",     None)
      ]}'
  '' + lib.optionalString (stdenv.isDarwin) ''
    substituteInPlace buildtools/config.py \
      --replace "WXPORT = 'gtk3'" "WXPORT = 'osx_cocoa'"
  '';

  NIX_LDFLAGS = lib.optionalString (!stdenv.isDarwin) "-lX11 -lgdk-x11-2.0";

  buildPhase = "";

  installPhase = ''
    ${python.interpreter} setup.py install --prefix=$out
    wrapPythonPrograms
  '';

  passthru = { inherit wxGTK openglSupport gnome3; };
}
