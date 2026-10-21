{
  # services.nginx = {
  #   enable = false;
  #   recommendedGzipSettings = true;
  #   recommendedOptimisation = true;
  #   recommendedProxySettings = true;
  #   recommendedTlsSettings = true;

  #   virtualHosts =
  #     # Add any further config to match your needs, e.g.:
  #     # let
  #     #   base = locations: {
  #     #     inherit locations;

  #     # sslCertificate = ;
  #     #     sslCertificateKey = ;

  #     #     forceSSL = true;
  #     #     # enableACME = true;
  #     #     listen = [
  #     #       {
  #     #         addr = config.services.nextcloud.hostName;
  #     #         port = 443;
  #     #         ssl = true;
  #     #       }
  #     #       {
  #     #         addr = config.services.nextcloud.hostName;
  #     #         port = 80;
  #     #       }
  #     #     ];
  #     #   };
  #     #   proxy =
  #     #     port:
  #     #     base {
  #     #       "/" = {
  #     #         proxyPass = "http://localhost:" + toString port;
  #     #         # proxySetHeader = config.services.nextcloud.hostName;
  #     #         #     "X-Real-IP" = "$remote_addr";
  #     #         #     "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
  #     #         #     "X-Forwarded-Proto" = "$scheme";
  #     #       };
  #     #     };
  #     # in
  #     # {
  #     #   ${config.services.nextcloud.hostName} = proxy 8080 // {
  #     #     default = true;
  #     #   };
  #     # };

  #     {
  #       ${hostName} = {
  #         forceSSL = true;
  #         # enableACME = true;
  #         # listen = [
  #         #   {
  #         #     addr = "0.0.0.0";
  #         #     port = 4080;
  #         #     ssl = true;
  #         #   }
  #         #   {
  #         #     addr = hostName;
  #         #     port = 443;
  #         #     ssl = true;
  #         #   }
  #         #   {
  #         #     addr = hostName;
  #         #     port = 80;
  #         #   }
  #         # ];
  #         # locations."/" = {
  #         #   proxyPass = "http://localhost:4080";
  #         # };
  #         sslCertificate = sslCertificateFile;
  #         sslCertificateKey = sslCertificateKeyFile;
  #       };
  #     };
  # };

  # security.acme = {
  # acceptTerms = true;
  # defaults.email = "chocholaty.david@protonmail.com";
  #   certs = {
  #     ${hostName}.email = "chocholaty.david@protonmail.com";
  # };
  # };

  services.nginx = {
    enable = false;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts =
      # Add any further config to match your needs, e.g.:
      # let
      #   base = locations: {
      #     inherit locations;

      # sslCertificate = ;
      #     sslCertificateKey = ;

      #     forceSSL = true;
      #     # enableACME = true;
      #     listen = [
      #       {
      #         addr = config.services.nextcloud.hostName;
      #         port = 443;
      #         ssl = true;
      #       }
      #       {
      #         addr = config.services.nextcloud.hostName;
      #         port = 80;
      #       }
      #     ];
      #   };
      #   proxy =
      #     port:
      #     base {
      #       "/" = {
      #         proxyPass = "http://localhost:" + toString port;
      #         # proxySetHeader = config.services.nextcloud.hostName;
      #         #     "X-Real-IP" = "$remote_addr";
      #         #     "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
      #         #     "X-Forwarded-Proto" = "$scheme";
      #       };
      #     };
      # in
      # {
      #   ${config.services.nextcloud.hostName} = proxy 8080 // {
      #     default = true;
      #   };
      # };
      {
        # "*".locations."paperless.".proxyPass =
        # "http://localhost:${toString config.services.paperless.port}";
        # "${hostName}" = {
        # forceSSL = true;
        # enableACME = true;
        # listen = [
        #   {
        #     addr = "0.0.0.0";
        #     port = 4080;
        #     ssl = true;
        #   }
        #   {
        #     addr = hostName;
        #     port = 443;
        #     ssl = true;
        #   }
        #   {
        #     addr = hostName;
        #     port = 80;
        #   }
        # ];
        # locations."/" = {
        # proxyPass = "http://localhost:${toString config.services.paperless.port}";
        # };
        # sslCertificate = sslCertificateFile;
        # sslCertificateKey = sslCertificateKeyFile;
        # serverAliases = [
        #   "paperless.${hostName}"
        # ];
        # "paperless.${hostName}" = {
        # "${hostName}" = {
        # forceSSL = true;
        # locations."/" = {
        # proxyPass = "http://localhost:${toString config.services.paperless.port}";
        #     # proxy_set_header = [
        #     #   "Host"
        #     #   "X-Real-IP"
        #     # ];
        # };
        # sslCertificate = sslCertificateFile;
        # sslCertificateKey = sslCertificateKeyFile;
        # };

        # "${hostName}" = {
        # };
      };
  };
}
