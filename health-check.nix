{ lib
, writeShellScriptBin
, nmap
, curl
, gnugrep
, attestation ? {
    nmap = [ ];
    curl = [ ];
  }
, ...
}:
let
  curlList = attestation.curl;
  nmapList = attestation.nmap;
  nmapPorts =
    lib.unique (map (v: v.port) nmapList);

  contents =
    if (attestation != [ ]) then
      lib.concatStringsSep "\n"
        ([
          ''
            GREEN="\e[32;1m"
            RED="\e[31;1m"
            function colorText {
              if [[ $COLOR -eq 1 ]];
                then echo -e -n "$1"
              fi
              echo -n "$2"
              if [[ $COLOR -eq 1 ]]; then
                echo -e -n "\e[0m"
              fi
            }

            function tryCmd {
              "$@" > /dev/null
              local status=$?
              if (( status != 0 )); then
                colorText $RED "[!!]: "
                echo "$@"
              else
                colorText $GREEN "[OK]: "
                echo "$@"
              fi
              return $status
            }

            tfile=$(tempfile)
            ${nmap}/bin/nmap -Pn -sV -oG $tfile \
                -p ${lib.concatStringsSep "," (map builtins.toString nmapPorts)} \
                ${lib.concatStringsSep " " (map (v: v.host) nmapList)}
          ''
        ]
        ++ (
          map (v: "tryCmd ${gnugrep}/bin/grep $tfile -E '${v.host}.+${toString v.port}/open.+${v.expected}")
            nmapList
        )
        ++ (
          map (v: "tryCmd ${curl}/bin/curl ${lib.concatStringsSep " " v.args} ${v.protocol}://${v.host}${v.resource} | grep '${v.expected}'") curlList
        ))

    else "echo No Definitions";
in
writeShellScriptBin
  "health-check"
  contents
