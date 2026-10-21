# mpv Anime4K (Fast) profiles. Called with the shaders dir.
shaders: {
  anime4k-fast-a = {
    name = "Anime4K A (Fast) - For Very Blurry/Compressed";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Restore_CNN_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_S.glsl"
      ];
    };
  };
  anime4k-fast-b = {
    name = "Anime4K B (Fast) - For Blurry/Ringing";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Restore_CNN_Soft_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_S.glsl"
      ];
    };
  };
  anime4k-fast-c = {
    name = "Anime4K C (Fast) - For Crisp/Sharp";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Upscale_Denoise_CNN_x2_M.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_S.glsl"
      ];
    };
  };
  anime4k-fast-aa = {
    name = "Anime4K AA (Fast) - For Very Blurry/Compressed";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Restore_CNN_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Restore_CNN_S.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_S.glsl"
      ];
    };
  };
  anime4k-fast-bb = {
    name = "Anime4K BB (Fast) - For Blurry/Ringing";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Restore_CNN_Soft_M.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_M.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Restore_CNN_Soft_S.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_S.glsl"
      ];
    };
  };
  anime4k-fast-cc = {
    name = "Anime4K CA (Fast) - For Crisp/Sharp";
    settings = {
      glsl-shaders = [
        "${shaders}Anime4K_Clamp_Highlights.glsl"
      ];
      glsl-shaders-append = [
        "${shaders}Anime4K_Upscale_Denoise_CNN_x2_M.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x2.glsl"
        "${shaders}Anime4K_AutoDownscalePre_x4.glsl"
        "${shaders}Anime4K_Restore_CNN_S.glsl"
        "${shaders}Anime4K_Upscale_CNN_x2_S.glsl"
      ];
    };
  };
}
