# Values shared by the k8s-ai-hindsight files. Plain function, not a module:
# the aspect files import it with `import ./_hindsight/shared.nix { inherit lib; }`.
{ lib }:
let
  # Banks with their own token. One generated token per bank, so a holder of one
  # bank's token cannot use another gated bank. Writes always need it; gateReads
  # makes reads need it too. genie and genie-memory keep reads open because the
  # genie recall clients send no token (H2); den-law is the fleet's operating law.
  # `readers` get a token of their own that the gate admits on reads only, and only
  # a bank that gates reads can have them.
  gatedBanks = {
    genie.gateReads = false;
    genie-memory.gateReads = false;
    den-law = {
      gateReads = true;
      readers = [ "vic" ];
    };
  };
  gatedBankNames = builtins.attrNames gatedBanks;
  readersOf = bank: gatedBanks.${bank}.readers or [ ];
in
{
  inherit gatedBanks gatedBankNames readersOf;

  # Every (bank, reader) pair; its Secret key is the gate's file name `<bank>.read.<reader>`.
  readerTokens = lib.concatMap (
    bank:
    map (reader: {
      inherit bank reader;
      name = "read-token-${bank}-${reader}";
      key = "${bank}.read.${reader}";
    }) (readersOf bank)
  ) gatedBankNames;

  # A write-only token is named write-token-<bank>; a read-and-write one token-<bank>.
  tokenName = bank: if gatedBanks.${bank}.gateReads then "token-${bank}" else "write-token-${bank}";
  tokenSecret =
    bank:
    "hindsight-${if gatedBanks.${bank}.gateReads then "token-${bank}" else "write-token-${bank}"}";

  port = 8888;
  cpPort = 3000;

  # The write gate is a Python module on PYTHONPATH, delivered as a
  # ConfigMap: upstream's loader imports any `module:Class` it can find, so
  # the pinned image runs unmodified.
  gateDir = "/opt/hindsight-write-gate";
  tokensDir = "/etc/hindsight-write-gate/tokens";
  adminDir = "/etc/hindsight-write-gate/admin";

  # ports list for a CiliumNetworkPolicy toPorts entry.
  tcp = ports: [
    {
      ports = map (p: {
        port = toString p;
        protocol = "TCP";
      }) ports;
    }
  ];
}
