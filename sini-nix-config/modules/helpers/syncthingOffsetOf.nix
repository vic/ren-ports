# syncthingOffsetOf user -> sync-port offset (port = 22000 + offset). den default: uid - 1000, or 0 without a uid.
# A kind field default cannot read a sibling field (README:315 `opt t d` is a constant), so the field is null = derive.
{ ren, ... }:
{
  ren.helpers.syncthingOffsetOf =
    user:
    if user.syncthingOffset != null then
      user.syncthingOffset
    else if user.uid == null then
      0
    else
      user.uid - 1000;
}
