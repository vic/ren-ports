# macOS hand-rolled opkssh verifier (no nix-darwin services.opkssh). nix-darwin
# ALREADY owns sshd's AuthorizedKeysCommand for static keys (101-authorized-keys.conf)
# and sshd honours only the first, so we COMPOSE with it: a wrapper that runs
# opkssh verify AND cats that static-key file, at 100- so it wins.
{ ren, ... }:
{
  ren.aspects.security-opkssh.darwin =
    {
      pkgs,
      lib,
      environment,
      resolved-users,
      ...
    }:
    let
      idmDomain = ren.helpers.domainFor environment "kanidm";
      issuerFor =
        p:
        if p.provider == "google" then
          "https://accounts.google.com"
        else
          "https://${idmDomain}/oauth2/openid/opkssh";
      # auth_id from the host's resolved users (carries sshOidcPrincipals).
      authIdLines = lib.concatMap (
        u: map (p: "${u.name} ${p.email} ${issuerFor p}") (u.sshOidcPrincipals or [ ])
      ) resolved-users;
      providersFile = pkgs.writeText "opk-providers" ''
        https://accounts.google.com 206584157355-7cbe4s640tvm7naoludob4ut1emii7sf.apps.googleusercontent.com 24h
        https://${idmDomain}/oauth2/openid/opkssh opkssh 24h
      '';
      authIdFile = pkgs.writeText "opk-auth-id" (lib.concatStringsSep "\n" authIdLines + "\n");
      # Emit opkssh-verified principals AND nix-darwin's static keys, then always
      # exit 0 so sshd uses the combined output. `cd /` first: sshd runs this in
      # the login user's home, which _sshd can't stat (noisy getcwd errors).
      authKeysCmd = pkgs.writeShellScript "opkssh-authorized-keys" ''
        cd /
        ${pkgs.opkssh}/bin/opkssh verify "$1" "$2" "$3" 2>/dev/null || true
        /bin/cat "/etc/ssh/nix_authorized_keys.d/$1" 2>/dev/null || true
        exit 0
      '';
      # sshd refuses an AuthorizedKeysCommand whose path (or parent) is
      # group/world writable, and /nix/store IS group-writable on macOS. Install
      # to a root-owned safe path instead.
      authKeysCmdPath = "/etc/opk/authorized-keys-command";
    in
    {
      # 100- sorts before 101-authorized-keys.conf (first value wins).
      environment.etc."ssh/sshd_config.d/100-opkssh.conf".text = ''
        AuthorizedKeysCommand ${authKeysCmdPath} %u %k %t
        AuthorizedKeysCommandUser _sshd
      '';

      # nix-darwin's environment.etc only makes 0444 store symlinks, so materialise
      # via activation: the command at a safe path, and the policy files as real
      # 0640 files owned by _sshd (opkssh refuses insecure permissions, got 444).
      system.activationScripts.postActivation.text = ''
        mkdir -p /etc/opk
        install -m 0755 ${authKeysCmd} ${authKeysCmdPath}
        rm -f /etc/opk/providers /etc/opk/auth_id
        install -m 0640 -o _sshd ${providersFile} /etc/opk/providers
        install -m 0640 -o _sshd ${authIdFile} /etc/opk/auth_id
      '';
    };
}
