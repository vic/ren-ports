# mpv profile definitions (name + settings): scalers and neural upscalers. Called with the shaders dir.
shaders: {
  fsr = {
    name = "AMD FidelityFX Super Resolution";
    settings = {
      glsl-shader = "${shaders}FSR.glsl";
    };
  };
  cas = {
    name = "AMD FidelityFX Contrast Adaptive Sharpening";
    settings = {
      glsl-shader = "${shaders}CAS-scaled.glsl";
    };
  };
  fsr-cas = {
    name = "AMD FidelityFX Super Resolution + Contrast Adaptive Sharpening";
    settings = {
      glsl-shaders = [
        "${shaders}FSR.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}CAS-scaled.glsl"
      ];
    };
  };
  generic = {
    name = "FSRCNNX";
    settings = {
      dscale = "mitchell";
      cscale = "mitchell";
      glsl-shaders = [
        "${shaders}FSRCNNX_x2_16-0-4-1.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}SSimDownscaler.glsl"
        "${shaders}KrigBilateral.glsl"
      ];
    };
  };
  generic-high = {
    name = "FSRCNNX x16";
    settings = {
      dscale = "mitchell";
      cscale = "mitchell";
      glsl-shaders = [
        "${shaders}FSRCNNX_x2_8-0-4-1.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}SSimDownscaler.glsl"
        "${shaders}KrigBilateral.glsl"
      ];
    };
  };
  nnedi-high = {
    name = "NNEDI3 (64 Neurons)";
    settings = {
      dscale = "mitchell";
      cscale = "mitchell";
      glsl-shaders = [
        "${shaders}nnedi3-nns64-win8x6.hook"
      ];
      glsl-shaders-append = [
        "${shaders}SSimDownscaler.glsl"
        "${shaders}KrigBilateral.glsl"
      ];
    };
  };
  nnedi-very-high = {
    name = "NNEDI3 High (128 Neurons)";
    settings = {
      dscale = "mitchell";
      cscale = "mitchell";
      glsl-shaders = [
        "${shaders}nnedi3-nns128-win8x6.hook"
      ];
      glsl-shaders-append = [
        "${shaders}SSimDownscaler.glsl"
        "${shaders}KrigBilateral.glsl"
      ];
    };
  };
}
