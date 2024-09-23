{ stdenv
, clickhouse
}: 

stdenv.mkDerivation {
  name = "clickhouse-custom-config";

  unpackPhase = ":";
  buildPhase = ":";

  installPhase = ''
    mkdir -p $out
    cp -r ${clickhouse}/etc/clickhouse-server/config.xml $out
    cp -r ${clickhouse}/etc/clickhouse-server/users.xml $out
  '';
}
