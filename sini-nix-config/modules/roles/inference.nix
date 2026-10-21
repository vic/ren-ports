{ ren, ... }:
{
  ren.aspects.inference = {
    includes = with ren.aspects; [
      svc-ai-llama-cpp
      svc-ai-ninfer
    ];
  };
}
