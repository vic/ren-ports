# mpv Anime4K (HQ) profiles. Called with the shaders dir.
shaders: {
  anime4k-high-a = {
    name = "Anime4K A (HQ) - For Very Blurry/Compressed";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Restore_CNN_VL.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_VL.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };
  anime4k-high-b = {
    name = "Anime4K B (HQ) - For Blurry/Ringing";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}CAS-scaled.glsl"
        "${shaders}Anime4K_Restore_CNN_Soft_VL.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_VL.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };
  anime4k-high-c = {
    name = "Anime4K C (HQ) - For Crisp/Sharp";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Upscale_Denoise_CNN_x2_VL.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };
  anime4k-high-aa = {
    name = "Anime4K AA (HQ) - For Very Blurry/Compressed";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}CAS-scaled.glsl"
        "${shaders}Anime4K_Restore_CNN_VL.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_VL.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Restore_CNN_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };
  anime4k-high-bb = {
    name = "Anime4K BB (HQ) - For Blurry/Ringing";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Restore_CNN_Soft_VL.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_VL.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Restore_CNN_Soft_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };
  anime4k-high-ca = {
    name = "Anime4K CA (HQ) - For Crisp/Sharp";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Upscale_Denoise_CNN_x2_VL.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Restore_CNN_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };
}
