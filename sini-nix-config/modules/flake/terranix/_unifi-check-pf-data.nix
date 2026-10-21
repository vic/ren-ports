# Port-forward fixture records of the render checks.
rec {
  host = {
    environment = "t";
    name = "ssh-to-h1";
    protocol = "tcp";
    wanPort = "22";
    forward = {
      ip = "10.0.0.5";
      port = "22";
    };
  };
  cluster = {
    environment = "t";
    name = "c1-https-ingress";
    protocol = "tcp_udp";
    wanPort = "443";
    forward = {
      ip = "10.1.0.1";
      port = "443";
    };
    allWans = true;
  };
  other = cluster // {
    environment = "u";
    name = "c2-https-ingress";
  };
}
