# helpers: the old confLib (common/config-lib.nix) as a function of the machine and its globals.
# Emissions call it without `config`; NixOS content passes `config` for the parts that need it.
{ ren, inputs, ... }:
{
  ren.helpers.confLibOf =
    {
      host,
      globals,
      config ? throw "confLib: this part needs the NixOS config of ${host.name}",
      osConfig ? null,
    }:
    let
      inherit (inputs.nixpkgs) lib;
      sw = ren.helpers;
      nodeName = host.name;
      domainDefault = service: ren.fleet.swarsel.pii.services.domains.${service};
      proxyDefault = sw.proxyHostOf host;

      isWgProxyClient =
        globals.wireguard ? wgProxy && builtins.elem nodeName globals.wireguard.wgProxy.clients;

      addressDefault =
        if proxyDefault != nodeName then
          if isWgProxyClient then
            globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy".hosts.${nodeName}.ipv4
          else
            globals.networks.${(sw.netConfigNameOf host)}.hosts.${nodeName}.ipv4
        else
          "localhost";
    in
    rec {
        gen =
          {
            name ? "n/a",
            address ? addressDefault,
            dir ? null,
            domain ? (domainDefault name),
            group ? user,
            port ? null,
            proxy ? proxyDefault,
            user ? name,
          }:
          rec {
            baseDomain = sw.getBaseDomain domain;
            proxyAddress4 = globals.hosts.${proxy}.wanAddress4 or null;
            proxyAddress6 = globals.hosts.${proxy}.wanAddress6 or null;
            serviceAddress = address;
            serviceDir = dir;
            serviceDomain = domain;
            serviceGroup = group;
            serviceName = name;
            serviceNode = nodeName;
            servicePort = port;
            serviceProxy = proxy;
            serviceUser = user;
            specificServiceName = "${name}-${nodeName}";
            subDomain = sw.getSubDomain domain;
            topologyContainerName = "${serviceNode}-${config.virtualisation.oci-containers.backend}-${name}";
          };
        genNginx =
          {
            serviceAddress,
            serviceDomain,
            serviceName,
            servicePort,
            extraConfig ? "",
            extraConfigLoc ? "",
            maxBody ? (-1),
            maxBodyUnit ? "",
            noSslVerify ? false,
            oauth2 ? false,
            oauth2Groups ? [ ],
            protocol ? "http",
            proxyWebsockets ? false,
          }:
          {
            upstreams = {
              ${serviceName}.servers = {
                "${serviceAddress}:${builtins.toString servicePort}" = { };
              };
            };
            virtualHosts = {
              "${serviceDomain}" = {
                acmeRoot = null;
                extraConfig =
                  lib.optionalString noSslVerify ''
                    proxy_ssl_verify off;
                  ''
                  + extraConfig;
                forceSSL = true;
                locations."/" = {
                  extraConfig =
                    lib.optionalString (maxBody != (-1)) ''
                      client_max_body_size ${builtins.toString maxBody}${maxBodyUnit};
                    ''
                    + extraConfigLoc;
                  proxyPass = "${protocol}://${serviceName}";
                  proxyWebsockets = lib.mkIf proxyWebsockets true;
                };
                oauth2 = {
                  enable = lib.mkIf oauth2 true;
                  allowedGroups = lib.mkIf (oauth2Groups != [ ]) oauth2Groups;
                };
                useACMEHost = globals.domains.main;
              };
            };
          };
        getConfig = if osConfig == null then config else osConfig;
        mkAlloyPushUrl =
          {
            domain,
            host,
            path,
            port,
          }:
          let
            monitoringServer = globals.general.monitoringServer;
            isCentral = host == monitoringServer;
            isHomeHost = globals.hosts.${host}.isHome or false;
          in
          if isCentral then
            "http://127.0.0.1:${toString port}${path}"
          else if isHomeHost then
            "http://${
              globals.networks.home-lan.vlans.services.hosts.${monitoringServer}.ipv4
            }:${toString port}${path}"
          else
            "https://${domain}${path}";
        mkDeviceMac =
          id:
          let
            mod = n: d: n - (n / d) * d;
            toHexByte =
              n:
              let
                hex = "0123456789abcdef";
                hi = n / 16;
                lo = mod n 16;
              in
              builtins.substring hi 1 hex + builtins.substring lo 1 hex;

            max = 16777215; # 256^3 - 1

            b1 = id / (256 * 256);
            r1 = mod id (256 * 256);
            b2 = r1 / 256;
            b3 = mod r1 256;
          in
          if (id <= max) then
            (builtins.concatStringsSep ":" (
              map toHexByte [
                b1
                b2
                b3
              ]
            ))
          else
            (throw "Device MAC ID too large (max is 16777215)");
        mkDnsRecord =
          {
            proxyAddress4,
            proxyAddress6,
            serviceName,
          }:
          let
            svc = globals.services.${serviceName};
          in
          {
            ${svc.baseDomain}.subdomainRecords.${svc.subDomain} =
              inputs.dns.lib.combinators.host proxyAddress4 proxyAddress6;
          };
        mkDualFirewallRules =
          {
            forHomeProxy ? true,
            forWebProxy ? true,
            tcpPorts ? [ ],
            udpPorts ? [ ],
          }:
          let
            rule = {
              allowedTCPPorts = lib.mkIf (tcpPorts != [ ]) tcpPorts;
              allowedUDPPorts = lib.mkIf (udpPorts != [ ]) udpPorts;
            };
          in
          {
            ${static.homeProxyIf}.hosts = lib.mkIf (forHomeProxy && static.isHome) {
              ${nodeName}.firewallRuleForNode.${static.homeWebProxy} = rule;
            };
            ${static.webProxyIf}.hosts = lib.mkIf (forWebProxy && static.isProxied) {
              ${nodeName}.firewallRuleForNode.${static.webProxy} = rule;
            };
          };
        mkGrafanaAlertRule =
          {
            expr,
            summary,
            title,
            uid,
            datasourceUid ? "mimir",
            forDuration ? "5m",
            noDataState ? "NoData",
            op ? "lt",
            queryType ? null,
            severity ? "critical",
            threshold ? 1,
          }:
          {
            inherit noDataState title uid;
            annotations.summary = summary;
            condition = "C";
            data = [
              {
                inherit datasourceUid;
                model = {
                  inherit expr;
                  instant = true;
                  range = false;
                  refId = "A";
                }
                // lib.optionalAttrs (queryType != null) { inherit queryType; };
                refId = "A";
                relativeTimeRange = {
                  from = 600;
                  to = 0;
                };
              }
              {
                datasourceUid = "__expr__";
                model = {
                  conditions = [
                    {
                      evaluator = {
                        params = [ threshold ];
                        type = op;
                      };
                    }
                  ];
                  expression = "A";
                  refId = "C";
                  type = "threshold";
                };
                refId = "C";
              }
            ];
            execErrState = "Alerting";
            for = forDuration;
            labels.severity = severity;
          };
        mkHttpMonitoring =
          {
            serviceName,
            servicePort,
            alertFor ? null,
            expectedBodyRegex ? null,
            expectedStatus ? null,
            failIfBodyMatchesRegex ? null,
            hostHeader ? null,
            path ? "/",
            scheme ? "http",
          }:
          {
            ${serviceName} = {
              network = "local-${nodeName}";
              url = "${scheme}://127.0.0.1:${toString servicePort}${path}";
            }
            // lib.optionalAttrs (expectedBodyRegex != null) { inherit expectedBodyRegex; }
            // lib.optionalAttrs (expectedStatus != null) { inherit expectedStatus; }
            // lib.optionalAttrs (hostHeader != null) { inherit hostHeader; }
            // lib.optionalAttrs (failIfBodyMatchesRegex != null) { inherit failIfBodyMatchesRegex; }
            // lib.optionalAttrs (alertFor != null) { inherit alertFor; };
          };
        mkIds = id: {
          gid = id;
          uid = id;
        };
        mkKanidmOauth2ProxyAccess =
          {
            serviceName,
            proxyGroup ? "${serviceName}_access",
          }:
          {
            services.kanidm.provision = {
              groups."${serviceName}.access" = { };
              systems.oauth2.oauth2-proxy = {
                claimMaps.groups.valuesByGroup."${serviceName}.access" = [ proxyGroup ];
                scopeMaps."${serviceName}.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
            };
          };
        mkKanidmOidcSystem =
          {
            kanidmSopsFile,
            originUrl,
            serviceDomain,
            serviceName,
            displayName ? sw.toCapitalized serviceName,
            extraGroups ? [ ],
          }:
          {
            sops.secrets."kanidm-${serviceName}" = {
              group = "kanidm";
              mode = "0440";
              owner = "kanidm";
              sopsFile = kanidmSopsFile;
            };
            services.kanidm.provision = {
              groups = lib.genAttrs ([ "${serviceName}.access" ] ++ extraGroups) (_: { });
              systems.oauth2.${serviceName} = {
                inherit displayName originUrl;
                basicSecretFile = config.sops.secrets."kanidm-${serviceName}".path;
                originLanding = "https://${serviceDomain}/";
                preferShortUsername = true;
                scopeMaps."${serviceName}.access" = [
                  "openid"
                  "email"
                  "profile"
                ];
              };
            };
          };
        mkKanshiOutput =
          monitor: overrides:
          {
            inherit (monitor) position;
            criteria = monitor.output;
            mode = monitor.mode + lib.optionalString (monitor ? refresh) "@${monitor.refresh}Hz";
            scale = builtins.fromJSON monitor.scale * 1.0;
          }
          // lib.optionalAttrs (monitor ? transform) { inherit (monitor) transform; }
          // overrides;
        mkServiceGlobal =
          {
            homeServiceAddress,
            isHome,
            proxyAddress4,
            proxyAddress6,
            serviceAddress,
            serviceDomain,
            serviceName,
            extra ? { },
          }:
          {
            ${serviceName} = {
              inherit
                isHome
                proxyAddress4
                proxyAddress6
                serviceAddress
                ;
              domain = serviceDomain;
              homeServiceAddress = lib.mkIf isHome homeServiceAddress;
            }
            // extra;
          };
        mkShikaneOutput =
          monitor: overrides:
          {
            inherit (monitor) position;
            enable = true;
            match =
              if monitor ? vendor then
                [
                  "m=${monitor.model}"
                  "s=${monitor.serial}"
                  "v=${monitor.vendor}"
                ]
              else
                monitor.output;
            mode = monitor.mode + lib.optionalString (monitor ? refresh) "@${monitor.refresh}Hz";
            scale = builtins.fromJSON monitor.scale * 1.0;
          }
          // lib.optionalAttrs (monitor ? transform) { inherit (monitor) transform; }
          // overrides;
        mkTrayApplet =
          {
            description,
            execStart,
            extraService ? { },
          }:
          {
            Install.WantedBy = [ "tray.target" ];
            Service = {
              ExecStart = execStart;
            }
            // extraService;
            Unit = {
              After = [
                "graphical-session.target"
                "tray.target"
              ];
              Description = description;
              PartOf = [ "tray.target" ];
              Requires = [ "graphical-session.target" ];
            };
          };
        overrideTarget = target: {
          Install.WantedBy = lib.mkForce [ target ];
          Unit = {
            After = lib.mkForce [ target ];
            PartOf = lib.mkForce [ target ];
          };
        };
        static = rec {
          inherit (globals.hosts.${nodeName}) isHome;
          inherit (globals.general)
            dnsServer
            homeDnsServer
            homeProxy
            homeWebProxy
            idmServer
            monitoringServer
            oauthServer
            routerServer
            webProxy
            ;
          homeProxyIf = "home-wgHome";
          homeServiceAddress =
            lib.optionalString inWgHome
              globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome".hosts.${nodeName}.ipv4;
          inWgHome = builtins.elem nodeName wgHomeMembers;
          inWgProxy = builtins.elem nodeName wgProxyMembers;
          isProxied = nodeName != webProxy;
          nginxAccessRules =
            let
              wgHomeNet = globals.networks."${globals.wireguard.wgHome.netConfigPrefix}-wgHome";
            in
            ''
              allow ${globals.networks.home-lan.vlans.home.cidrv4};
              allow ${globals.networks.home-lan.vlans.home.cidrv6};
              allow ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv4};
              allow ${globals.networks.home-lan.vlans.services.hosts.${homeProxy}.ipv6};
              allow ${wgHomeNet.cidrv4};
              allow ${wgHomeNet.cidrv6};
              deny all;
            '';
          scannerDropRules = ''
            location ~* "\.(php|aspx?|env|jsp|cgi|bak|sql|old)(\?|$|/)" {
              access_log off;
              return 444;
            }
            location ~* "(^|/)(\.git/|\.env|\.DS_Store|wp-admin|wp-login|wp-content|wp-includes|xmlrpc\.php|phpmy?admin|cgi-bin)" {
              access_log off;
              return 444;
            }
          '';
          webProxyIf = "${webProxy}-wgProxy";
          wgHomeMembers = lib.optionals (globals.wireguard ? wgHome) (
            globals.wireguard.wgHome.clients ++ [ globals.wireguard.wgHome.server ]
          );
          wgProxyAccessRules =
            let
              wgProxyNet = globals.networks."${globals.wireguard.wgProxy.netConfigPrefix}-wgProxy";
              extraAllows = lib.concatMapStrings (
                host:
                let
                  cfg = globals.hosts.${host};
                in
                lib.optionalString (cfg.wanAddress4 != null) "allow ${cfg.wanAddress4};\n"
                + lib.optionalString (cfg.wanAddress6 != null) "allow ${cfg.wanAddress6};\n"
              ) (lib.filter (h: !(builtins.elem h wgProxyMembers)) (lib.attrNames globals.hosts));
            in
            ''
              allow ${wgProxyNet.cidrv4};
              allow ${wgProxyNet.cidrv6};
            ''
            + extraAllows
            + ''
              deny all;
            '';
          wgProxyMembers = lib.optionals (globals.wireguard ? wgProxy) (
            globals.wireguard.wgProxy.clients ++ [ globals.wireguard.wgProxy.server ]
          );
        };

      };
}
