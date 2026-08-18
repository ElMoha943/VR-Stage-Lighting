Shader "LUTBeam/Simple AudioLink"
{
    Properties
    {
        [NoScaleOffset] _GoboTex ("Gobo Texture", 2DArray) = "white" {}
        [NoScaleOffset] _GoboLUT ("LUT Texture", 2DArray) = "white" {}

        [Header(Shape)]
        _ZoomX ("_ZoomX", Range(0, 2.0)) = 0.1
        _ZoomY ("_ZoomY", Range(0, 2.0)) = 0.1
        _NearSizeX ("_NearSizeX", Range(0, 2.0)) = 0.1
        _NearSizeY ("_NearSizeY", Range(0, 2.0)) = 0.1
        _Offset ("_Offset", Range(-1, 1)) = 0.25
        _FarZ ("_FarZ", Float) = 25
        _Gobo ("Gobo Index", Integer) = 0

        [Header(Color)]
        _Color ("Color", Color) = (1, 1, 1, 1)
        _BeamIntensity ("Max Beam Intensity", Range(0, 8.0)) = 1
        _BeamFalloff ("_BeamFalloff", Range(0, 3.0)) = 1
        _GoboIntensity ("Max Gobo Intensity", Range(0, 8.0)) = 1

        [Header(AudioLink)]
        [Toggle] _AudioLinkToggle ("Use AudioLink", Float) = 0
        [Enum(Bass,0,LowMids,1,HighMids,2,Treble,3)] _AudioLinkBand ("AudioLink Band", Int) = 0
        _AudioLinkDelay ("AudioLink Delay", Float) = 0
        [Toggle] _AudioLinkThemeColorToggle ("Use ThemeColor", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+303" }
        LOD 100

        Cull Back
        ZTest LEqual
        ZWrite Off

        Pass
        {
            Name "LUTBeam AudioLink"
            Blend One One

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "Packages/com.llealloo.audiolink/Runtime/Shaders/AudioLink.cginc"

            Texture2DArray _GoboTex;
            Texture2DArray _GoboLUT;
            float _Offset;
            float _ZoomX;
            float _ZoomY;
            float _NearSizeX;
            float _NearSizeY;
            float _FarZ;
            float _Gobo;
            float4 _Color;
            float _GoboIntensity;
            float _BeamIntensity;
            float _BeamFalloff;
            float _AudioLinkToggle;
            float _AudioLinkDelay;
            float _AudioLinkThemeColorToggle;

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _AudioLinkBand)
            UNITY_INSTANCING_BUFFER_END(Props)

            uint LUTBeamAudioLinkBandIndex(float band)
            {
                return (uint)clamp(floor(band + 0.5), 0.0, 3.0);
            }

            void LUTBeamAudioLinkData(float band, out float3 tint, out float intensity)
            {
                tint = _Color.rgb;
                intensity = 1.0;

                if (_AudioLinkToggle <= 0.5)
                    return;

                intensity = 0.0;
                if (!AudioLinkIsAvailable())
                    return;

                uint bandIndex = LUTBeamAudioLinkBandIndex(band);
                float delay = clamp(_AudioLinkDelay, 0.0, AUDIOLINK_WIDTH - 2.0);
                intensity = saturate(AudioLinkLerp(ALPASS_AUDIOLINK + float2(delay, (float)bandIndex)).r);

                // ThemeColor is the exclusive tint when enabled. It does not
                // multiply the material color.
                if (_AudioLinkThemeColorToggle > 0.5)
                    tint = AudioLinkData(ALPASS_THEME_COLOR0 + uint2(bandIndex, 0)).rgb;
            }

            #define LUTBEAM_CALLBACK_PROJECTION 1
            float3 LUTBeamCallbackProjection(SamplerState samp, float2 uv)
            {
                return _GoboTex.SampleLevel(samp, float3(uv, _Gobo), 0).rrr;
            }

            #define LUTBEAM_CALLBACK_VOLUME 1
            float3 LUTBeamCallbackVolume(SamplerState samp, float2 uv)
            {
                return _GoboLUT.SampleLevel(samp, float3(uv, _Gobo), 0).rrr;
            }

            #include "Packages/com.valenvrc.VVRSL/Runtime/Shaders/LUTBeam/LUTBeam.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                BeamData beam;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 tint;
                float audioIntensity;
                LUTBeamAudioLinkData(
                    UNITY_ACCESS_INSTANCED_PROP(Props, _AudioLinkBand),
                    tint,
                    audioIntensity
                );

                o.beam = LUTBeamVert(
                    v.vertex,
                    _ZoomX,
                    _ZoomY,
                    _FarZ,
                    _NearSizeX,
                    _NearSizeY,
                    _Offset,
                    tint,
                    _BeamIntensity * audioIntensity,
                    _GoboIntensity * audioIntensity,
                    _BeamFalloff
                );

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float3 col = LUTBeamFrag(i.beam, _BeamFalloff);
                return float4(col, 0);
            }
            ENDCG
        }
    }
}
