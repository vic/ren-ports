# a-m channels, agents: agent extensions, user -> user.
{ ren, ... }:
{
  ren.channels.agent-extensions = {
    fold = ren.lib.fold.list;
    at = ren.kinds.user;
    to = e: e;
  };
}
