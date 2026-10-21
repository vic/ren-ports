{ lib, ... }:
{
  ren.aspects.dev-security-signing-key.homeManager =
    { user, config, ... }:
    # Only a user who signs gets a key; git signs per `git.signing.method` (default none).
    lib.mkIf (user.dev-git.signing.method != "none") {
      age.secrets.user-signing-key = {
        rekeyFile = user.secretPath + "/id_signing.age";
        mode = "600";
        generator.script = "shared-ssh-key";
        # agenix's home-manager default path is a *shell string*, not a path:
        # "$(<store>/bin/getconf DARWIN_USER_TEMP_DIR)/agenix/<name>" on darwin
        # and "${XDG_RUNTIME_DIR}/agenix/<name>" on linux. It only resolves
        # inside a shell. Written into a config file that is not shell-expanded it
        # is taken literally, and ssh_config does neither substitution. Pin a real
        # static path instead; agenix symlinks it onto the decrypted secret
        # during activation.
        path = "${config.home.homeDirectory}/.ssh/id_signing";
      };
    };
}
