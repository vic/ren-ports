
# Nix Fleet configurations ported to Ren

These Nix configurations have been ported by an [agent](./adda-nix-config/AGENTS.md) from their original sources into [Ren](https://github.com/vic/ren).

They serve as code examples of how complex infrastructures _might_ look like when modeled in Ren. The agent identified nouns from Ren vocabulary: `kinds`/`classes`/`channels`/etc. So take these only as reference, these are not canonical (author-aproveed) configurations, our goal was to exercise Ren itself and see how it can model whole infrastructures. Each repo has an auto-generated README with diagrams of their particular entities you can start by browsing their topology and kinds.

Configuration settings were not modified, only their  organization into Ren terms and place at filesystem.

This repo claims no authorship/license/guarantees on any of the code, rights belong to their original authors as stated on each repo license.

- [github:vic/vix](./vic-vix) <em>([topology](./vic-vix/modules/topology/fleet.nix))</em> <small>([original](https://github.com/vic/vix/tree/historic/den))</small>
- [github:sini/nix-config](./sini-nix-config/) <em>([topology](./sini-nix-config/modules/topology/fleet.nix))</em> <small>([original](https://github.com/sini/nix-config))</small>
- [codeberg:adda/nix-config](./adda-nix-config) <em>([topology](./adda-nix-config/modules/topology/fleet.nix))</em> <small>([original](https://codeberg.org/adda/nix-config))</small>
- [github:swarsel/.dotfiles](./swarsel-dotfiles/) <em>([topology](./swarsel-dotfiles/modules/topology/fleet.nix))</em> <small>([original](https://github.com/swarsel/.dotfiles))</small>


