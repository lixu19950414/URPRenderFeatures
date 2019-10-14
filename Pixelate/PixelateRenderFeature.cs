using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    public class PixelateRenderFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class PixelateSettings
        {
            public FilterMode filterMode = FilterMode.Point;
            public RenderPassEvent Event = RenderPassEvent.BeforeRenderingPostProcessing;
            public Material blitMaterial = null;
        }

        public PixelateSettings settings = new PixelateSettings();

        PixelateRenderPass pixelateRenderPass;

        public override void Create()
        {
            pixelateRenderPass = new PixelateRenderPass(settings.Event, settings.blitMaterial, settings.filterMode);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (settings.blitMaterial == null)
            {
                Debug.LogWarning("Missing pixelate material");
                return;
            }

            pixelateRenderPass.Setup(renderer.cameraColorTarget, RenderTargetHandle.CameraTarget);
            renderer.EnqueuePass(pixelateRenderPass);
        }
    }
}
