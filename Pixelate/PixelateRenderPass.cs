using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    /// <summary>
    /// Copy the given color buffer to the given destination color buffer.
    ///
    /// You can use this pass to copy a color buffer to the destination,
    /// so you can use it later in rendering. For example, you can copy
    /// the opaque texture to use it for distortion effects.
    /// </summary>
    internal class PixelateRenderPass : ScriptableRenderPass
    {
        public Material blitMaterial = null;
        public FilterMode filterMode { get; set; }

        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle destination { get; set; }

        RenderTargetHandle m_TemporaryColorTexture;
        string m_ProfilerTag;

        /// <summary>
        /// Create the PixelateRenderPass
        /// </summary>
        public PixelateRenderPass(RenderPassEvent renderPassEvent, Material blitMaterial, FilterMode filterMode)
        {
            this.renderPassEvent = renderPassEvent;
            this.blitMaterial = blitMaterial;
            this.filterMode = filterMode;
            m_ProfilerTag = "Pixelate";
            m_TemporaryColorTexture.Init("_TemporaryColorTexture");
        }

        /// <summary>
        /// Configure the pass with the source and destination to execute on.
        /// </summary>
        /// <param name="source">Source Render Target</param>
        /// <param name="destination">Destination Render Target</param>
        public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
        {
            this.source = source;
            this.destination = destination;
        }

        /// <inheritdoc/>
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            opaqueDesc.msaaSamples = 1;

            cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc, filterMode);
            Blit(cmd, source, m_TemporaryColorTexture.Identifier(), blitMaterial, 0);
            Blit(cmd, m_TemporaryColorTexture.Identifier(), source);
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        /// <inheritdoc/>
        public override void FrameCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }
    }
}
