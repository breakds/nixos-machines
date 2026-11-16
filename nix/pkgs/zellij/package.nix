# zellij with the fix for tabs created while no client is attached: such a
# tab got the size 0x0, its layout failed, and zellij dropped it.
# The patch is zellij-org/zellij PR #5612 without its test, for issue #5594.
# Drop this once a release has the fix.
{ zellij-unwrapped }:

zellij-unwrapped.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./detached-tab-size.patch ];
})
