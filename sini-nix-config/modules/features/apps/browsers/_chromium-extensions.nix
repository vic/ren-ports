# Web Store extension set shared by the Linux install and the macOS policy
# force-list. Mirrors the firefox addon set; firefox-only addons
# (firefox-color, sidebery) have no chromium equivalent and are dropped.
# Evaluates to the list of extension ids.
builtins.catAttrs "id" [
  {
    id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
    name = "uBlock Origin";
  }
  {
    id = "nngceckbapebfimnlniiiahkandclblb";
    name = "Bitwarden";
  }
  {
    id = "mnjggcdmjocbbbhaepdhchncahnbgone";
    name = "SponsorBlock";
  }
  {
    id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    name = "Dark Reader";
  }
  {
    id = "mlomiejdfkolichcflejclcbmpeaniij";
    name = "Ghostery";
  }
  {
    id = "gebbhagfogifgggkldgodflihgfeippi";
    name = "Return YouTube Dislike";
  }
  {
    id = "bkdgflcldnnnapblkhphbgpggdiikppg";
    name = "DuckDuckGo Privacy Essentials";
  }
  {
    id = "kekjfbackdeiabghhcdklcdoekaanoel";
    name = "MAL-Sync";
  }
]
