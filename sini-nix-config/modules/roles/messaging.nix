{ ren, ... }:
{
  ren.aspects.messaging = {
    includes = with ren.aspects; [
      app-messaging-discord
      app-messaging-element
      app-messaging-kdeconnect
      app-messaging-messenger
      app-messaging-zoom
    ];
  };
}
