# Local LLM & substrate benchmarking tools; deliberately not in any default role, include explicitly.
{ ... }:
{
  ren.aspects.svc-ai-benchmarking.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.sysbench
        pkgs.iperf3
        pkgs.dmidecode
        pkgs.llama-cpp
        pkgs.local.llm-bench
      ];
    };
}
