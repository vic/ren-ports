# Names and ports shared by the searxng release, route and network policies.
{
  namespace = "search";
  name = "searxng";
  port = 8080;
  pod."app.kubernetes.io/name" = "searxng";
  tcp = p: {
    port = toString p;
    protocol = "TCP";
  };
}
