# readme fragments: Ren relationship graphs and fleet summary, rendered from live Ren data (see _graphs.nix).
# Orders 31-39 sit between architecture (30) and automatic-import (40); they keep the original sini README sections.
{ ren, lib, ... }:
let
  g = import ./_graphs.nix { inherit ren lib; };
  frag = order: text: {
    at = ren.fleet.sini;
    readme = { inherit order text; };
  };
in
{
  ren.aspects.docs-graph-scope-topology = frag 31 g.scopeTopology;
  ren.aspects.docs-graph-policy-resolution = frag 32 g.policyResolution;
  ren.aspects.docs-graph-pipe-flow = frag 33 g.pipeFlow;
  ren.aspects.docs-graph-pipe-sequence = frag 34 g.pipeSequence;
  ren.aspects.docs-summary-topology = frag 35 g.summaryTopology;
  ren.aspects.docs-summary-environments = frag 36 g.summaryEnvironments;
  ren.aspects.docs-summary-aspects = frag 37 g.summaryAspects;
  ren.aspects.docs-summary-pipes = frag 38 g.summaryPipes;
  ren.aspects.docs-summary-policies = frag 39 g.summaryPolicies;
}
