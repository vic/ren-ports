# Write-gate wiring: the validator extension and where it finds its tokens.
{ lib, shared }:
{
  # Per-bank tokens (hindsight-write-gate.py). The loader
  # passes every HINDSIGHT_API_OPERATION_VALIDATOR_* variable to
  # the gate as config. A listed bank with a missing or empty
  # token file, or a bad admin digest, stops the server at startup.
  PYTHONPATH = shared.gateDir;
  HINDSIGHT_API_OPERATION_VALIDATOR_EXTENSION = "hindsight_write_gate:WriteGate";
  HINDSIGHT_API_OPERATION_VALIDATOR_BANKS = builtins.toJSON (
    lib.mapAttrs (bank: b: {
      gate_reads = b.gateReads;
      readers = shared.readersOf bank;
    }) shared.gatedBanks
  );
  HINDSIGHT_API_OPERATION_VALIDATOR_TOKENS_DIR = shared.tokensDir;
  HINDSIGHT_API_OPERATION_VALIDATOR_ADMIN_SHA256_FILE = "${shared.adminDir}/sha256";

  # Document import (POST …/document-transfer) is on. Into a gated
  # bank it needs that bank's token or the admin token, like any
  # write: the gate wraps the engine method behind it.
  HINDSIGHT_API_ENABLE_DOCUMENT_IMPORT_API = "true";
}
