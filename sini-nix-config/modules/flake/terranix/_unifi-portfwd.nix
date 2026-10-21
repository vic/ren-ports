# The gateway's port forwards: the records with mode "forward". A forward
# listens on the first WAN, or with `allWans` on every one in `wans` (the
# controller's destination_ips).
{ lib, recordsOf }:
{
  env,
  wans,
  forwards,
}:
lib.listToAttrs (
  map (
    { name, value }:
    lib.nameValuePair name (
      {
        inherit (value) name protocol forward;
        wan = {
          interface = builtins.head wans;
          port = value.wanPort;
        };
      }
      // lib.optionalAttrs (value.allWans or false) {
        destination_ips = map (interface: {
          destination_ip = "any";
          inherit interface;
        }) wans;
      }
    )
  ) (recordsOf "forward" env forwards)
)
