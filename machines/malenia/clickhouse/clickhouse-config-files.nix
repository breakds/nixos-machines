{ stdenv, clickhouse,
  workDir,
  httpPort,
  tcpPort,
}:

stdenv.mkDerivation {
  name = "clickhouse-config-files";

  src = ./.;

  unpackPhase = ":";
  buildPhase = ":";

  installPhase = ''
    mkdir -p $out
    cp ${clickhouse}/etc/clickhouse-server/config.xml $out
    cp ${clickhouse}/etc/clickhouse-server/users.xml $out

    # Port for HTTP API (ODBC/JDBC), e.g. for Dbeaver and other web interfaces
    substituteInPlace $out/config.xml \
        --replace "<http_port>8123</http_port>" \
        "<http_port>${toString httpPort}</http_port>"

    # Port for native protocols e.g. clickhouse-client
    substituteInPlace $out/config.xml \
        --replace "<tcp_port>9000</tcp_port>" \
        "<tcp_port>${toString tcpPort}</tcp_port>"

    # Disable support for mysql protocol
    substituteInPlace $out/config.xml \
        --replace "<mysql_port>9004</mysql_port>" ""

    # Disable support for postgresql protocol
    substituteInPlace $out/config.xml \
        --replace "<postgresql_port>9005</postgresql_port" ""

    # TODO(breakds): Support interserver communications between replicas.
    substituteInPlace $out/config.xml \
        --replace "<interserver_http_port>9009</interserver_http_port>" ""

    substituteInPlace $out/config.xml \
        --replace "/var/lib/clickhouse/" "${workDir}/"

    substituteInPlace $out/config.xml \
        --replace "<remove_backup_files_after_failure>true</remove_backup_files_after_failure>" ""
  '';
}
