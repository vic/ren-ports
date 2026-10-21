# Collected agent-extensions mcpServers -> opencode `mcp` schema.
# url => remote (opencode substitutes {file:} at load time; token stays out of the store);
# else local: `command` is ONE array of executable plus args, env key is `environment`.
lib: mcpMap:
lib.mapAttrs (
  _: server:
  if server ? url then
    {
      type = "remote";
      inherit (server) url;
    }
    // lib.optionalAttrs (server ? bearerTokenFile) {
      headers.Authorization = "Bearer {file:${server.bearerTokenFile}}";
    }
  else
    {
      type = "local";
      command = lib.toList server.command ++ (server.args or [ ]);
    }
    // lib.optionalAttrs ((server.env or { }) != { }) {
      environment = server.env;
    }
) mcpMap
