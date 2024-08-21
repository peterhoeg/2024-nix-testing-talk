let
  nixpkgs = builtins.fetchTarball "https://github.com/nixOS/nixpkgs/archive/24.05.tar.gz";
  pkgs = import nixpkgs { };

  port = 12345;

  data = (pkgs.formats.json { }).generate "data.json" {
    test.status = "ok";
  };

  script = pkgs.writeShellScript "run-server.sh" ''
    export PATH=$PATH:${pkgs.lib.makeBinPath [ pkgs.nodePackages.json-server ]}

    json-server --port ${toString port} --watch ${data}
  '';

in
pkgs.nixosTest {
  name = "my-multi-server-test";

  nodes = {
    server = { ... }: {
      networking.firewall.allowedTCPPorts = [ port ];

      systemd.services.my-server = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = true;
          ExecStart = script;
        };
      };
    };

    client = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [ curl gnugrep jq ];
    };
  };

  testScript = ''
    import json

    start_all()

    expected = { "status": "ok" }

    server.wait_for_unit("my-server.service")
    server.wait_for_open_port(${toString port})

    client.succeed("curl http://server:${toString port}/test | grep status")

    actual = json.loads(client.succeed("curl http://server:${toString port}/test"))

    client.fail("curl http://server:${toString port}/foobar | grep status")

    assert expected == actual, "we got what we hoped for!"
  '';
}
