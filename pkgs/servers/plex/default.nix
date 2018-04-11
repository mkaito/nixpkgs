{ stdenv, fetchurl, buildFHSUserEnv, writeScript, rpmextract }:

let
  name = "plexmediaserver-${version}";
  version = "1.9.6.4429-23901a099";

  rpm = fetchurl {
    url = "https://downloads.plex.tv/plex-media-server/${version}/${name}.x86_64.rpm";
    sha256 = "0bmqf8b2d9h2h5q3n4ahs8y6a9aihj63rch7wd82rcr1l9xnqk9d";
  };

  env = stdenv.mkDerivation {
    inherit name;
    nativeBuildInputs = [ rpmextract ];
    buildCommand = ''
      mkdir -p $out.tmp && cd $_
      rpmextract ${rpm} && mv usr $out

      for f in $out/lib/plexmediaserver/Resources/com.plexapp.plugins.library.db; do
        mv $f $f.ro
        ln -s /$(basename $f).rw $f
      done
    '';
  };
in

buildFHSUserEnv {
  name = "plexmediaserver";

  targetPkgs = pkgs: with pkgs; [ env ];
  runScript = writeScript "run" ''
    #!${stdenv.shell}
    root=/usr/lib/plexmediaserver
    db=$root/Resources/com.plexapp.plugins.library.db
    cp $db.ro /$(basename $db).rw && chmod 755 $_
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$root $root/Plex\ Media\ Server
  '';

  meta = with stdenv.lib; {
    homepage = http://plex.tv/;
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with stdenv.lib.maintainers; [
      colemickens
      forkk
      lnl7
      pjones
      thoughtpolice
    ];
    description = "Media / DLNA server";
    longDescription = ''
      Plex is a media server which allows you to store your media and play it
      back across many different devices.
    '';
  };
}
