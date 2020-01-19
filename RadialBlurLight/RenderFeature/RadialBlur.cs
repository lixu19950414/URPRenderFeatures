using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RadialBlur : ScriptableRendererFeature
{
    class RadialBlurPass : ScriptableRenderPass
    {
        int m_width;
        int m_height;
        float m_threshold;
        int m_blurTimes;
        float m_factor;
        float m_range;
        float m_volumetricLightFactor;


        int m_blurTex;
        int m_tempBlurTex;
        int m_tempColorTex;
        string m_ProfilerTag = "Render Radial Blur Texture";
        Material m_ExtractColorMat;
        Material m_RadialBlurMat;
        Material m_BlendMat;

        public RadialBlurPass()
        {
            m_blurTex = Shader.PropertyToID("_RadialBlurTex");
            m_tempBlurTex = Shader.PropertyToID("_TempRadialBlurTex");
            m_ExtractColorMat = new Material(Resources.Load<Shader>("Shaders/ExtractColorSH"));
            m_RadialBlurMat = new Material(Resources.Load<Shader>("Shaders/RadialBlurSH"));
            m_BlendMat = new Material(Resources.Load<Shader>("Shaders/BlendSH"));
        }

        public void Setup(int width, int height, float threshold, int blurTimes, float factor, float range, float volumetricLightFactor) {
            m_width = width;
            m_height = height;
            m_threshold = threshold;
            m_blurTimes = blurTimes;
            m_factor = factor;
            m_range = range;
            m_volumetricLightFactor = volumetricLightFactor;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            cmd.GetTemporaryRT(m_blurTex, m_width, m_height, 0, FilterMode.Bilinear, cameraTextureDescriptor.colorFormat);
            cmd.GetTemporaryRT(m_tempBlurTex, m_width, m_height, 0, FilterMode.Bilinear, cameraTextureDescriptor.colorFormat);
            cmd.GetTemporaryRT(m_tempColorTex, cameraTextureDescriptor);
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
           
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            using (new ProfilingSample(cmd, m_ProfilerTag))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                Vector3 lightDir = -renderingData.lightData.visibleLights[renderingData.lightData.mainLightIndex].light.transform.localToWorldMatrix.GetColumn(2);
                lightDir /= lightDir.z;
                lightDir *= renderingData.cameraData.camera.farClipPlane;
                Vector3 sunWorldPos = lightDir + renderingData.cameraData.camera.transform.position;
                Vector4 viewSpaceSunPos = renderingData.cameraData.camera.worldToCameraMatrix * new Vector4(sunWorldPos.x, sunWorldPos.y, sunWorldPos.z, 1);
                Vector4 clipSpaceSunPos = renderingData.cameraData.camera.projectionMatrix * viewSpaceSunPos;
                Vector3 sunUVPos = new Vector3(clipSpaceSunPos.x * 0.5f / clipSpaceSunPos.w + 0.5f,
                    clipSpaceSunPos.y * 0.5f / clipSpaceSunPos.w + 0.5f,
                    clipSpaceSunPos.z * 0.5f / clipSpaceSunPos.w + 0.5f);
                float delta = 0.3f;
                if (sunUVPos.x >= -delta && sunUVPos.x <= delta+1 && sunUVPos.y >= -delta && sunUVPos.y <= 1+delta && sunUVPos.z >=  0)
                {
                    m_ExtractColorMat.SetFloat("_Threshold", m_threshold);
                    cmd.Blit(m_blurTex, m_blurTex, m_ExtractColorMat);
                    m_RadialBlurMat.SetVector("_sunPos", new Vector4(sunUVPos.x, sunUVPos.y, 0, 0));
                    m_RadialBlurMat.SetFloat("_factor", m_factor);
                    for (int i = 0; i < m_blurTimes; ++i)
                    {
                        cmd.Blit(m_blurTex, m_tempBlurTex, m_RadialBlurMat);
                        int temp = m_tempBlurTex;
                        m_tempBlurTex = m_blurTex;
                        m_blurTex = temp;
                    }
                    cmd.SetGlobalTexture(Shader.PropertyToID("_ResRadialBlurTex"), m_tempBlurTex);
                    cmd.Blit(Shader.PropertyToID("_CameraColorTexture"), m_tempColorTex);
                    m_BlendMat.SetVector("_param", new Vector4(sunUVPos.x, sunUVPos.y, Mathf.Min(m_range, 0.5f+delta), m_volumetricLightFactor));
                    cmd.Blit(m_tempColorTex, Shader.PropertyToID("_CameraColorTexture"), m_BlendMat);
                }
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }

    RadialBlurPass m_RadialBlurPass;

    [Header("模糊纹理宽")]
    public int m_width = 800;
    [Header("模糊纹理高")]
    public int m_height = 600;
    [Header("模糊的物体颜色阈值，主要是区分太阳和普通物体")]
    public float m_threshold = 0.8f;
    [Header("径向模糊次数")]
    public int m_blurTimes = 1;
    [Header("径向模糊的步数系数")]
    public float m_factor = 1;
    [Header("模糊效果的有效半径")]
    public float m_effectiveRadius = 0.6f;
    [Header("混合时体积光的混合系数")]
    public float m_volumetricLightFactor = 0.5f;
    public override void Create()
    {
        m_RadialBlurPass = new RadialBlurPass();
        m_RadialBlurPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_RadialBlurPass.Setup(m_width, m_height, m_threshold, m_blurTimes, m_factor, m_effectiveRadius, m_volumetricLightFactor);
        renderer.EnqueuePass(m_RadialBlurPass);
    }
}


