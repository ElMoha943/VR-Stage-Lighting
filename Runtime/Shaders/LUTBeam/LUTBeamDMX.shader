// VVRSL SpotLight 13CH layout:
// 1 Pan, 2 Fine Pan, 3 Tilt, 4 Fine Tilt, 5 Zoom, 6 Dimmer,
// 7 Strobe, 8 Red, 9 Green, 10 Blue, 11 Gobo Spin,
// 12 Gobo Select, 13 Movement Speed (handled by VVRSL interpolation).
Shader "LUTBeam/VVRSL DMX 13CH"
{
    Properties
    {
        [NoScaleOffset] _GoboTex ("Gobo Texture", 2DArray) = "white" {}
        [NoScaleOffset] _GoboLUT ("LUT Texture", 2DArray) = "white" {}

        [Header(VVRSL 13 Channel DMX)]
        _DMXChannel ("Flattened Starting DMX Channel", Int) = 1
        [Toggle] _NineUniverseMode ("Extended Universe Mode", Int) = 0
        [Toggle] _EnableFineChannels ("Enable Fine Pan and Tilt", Int) = 1
        [Toggle] _PanInvert ("Invert Pan", Int) = 0
        [Toggle] _TiltInvert ("Invert Tilt", Int) = 0
        [Toggle] _EnableStrobe ("Enable Strobe", Int) = 1
        [Toggle] _EnableSpin ("Enable Gobo Spin", Int) = 1

        [Header(Movement)]
        _MaxMinPanAngle ("Pan Half Range", Float) = 180
        _MaxMinTiltAngle ("Tilt Half Range", Float) = 180
        _FixtureBaseRotationY ("Pan Offset", Range(-540, 540)) = 0
        _FixtureRotationX ("Tilt Offset", Range(-180, 180)) = 0

        [Header(Shape)]
        _DMXZoomMin ("DMX Zoom Minimum", Range(0, 2.0)) = 0.05
        _DMXZoomMax ("DMX Zoom Maximum", Range(0, 2.0)) = 0.5
        _DMXZoomAspectX ("DMX Zoom X Scale", Range(0, 2.0)) = 1
        _DMXZoomAspectY ("DMX Zoom Y Scale", Range(0, 2.0)) = 1
        _NearSizeX ("Near Size X", Range(0, 2.0)) = 0.1
        _NearSizeY ("Near Size Y", Range(0, 2.0)) = 0.1
        _Offset ("Lens Offset", Range(-1, 1)) = 0.25
        _FarZ ("Beam Length", Float) = 25

        [Header(Color and Intensity)]
        [HDR] _Emission ("Light Color Tint", Color) = (1, 1, 1, 1)
        _BeamIntensity ("Maximum Beam Intensity", Range(0, 8.0)) = 1
        _GoboIntensity ("Maximum Gobo Intensity", Range(0, 8.0)) = 1
        _BeamFalloff ("Beam Falloff", Range(0, 3.0)) = 1
        _GlobalIntensity ("Global Intensity", Range(0, 1)) = 1
        _GlobalIntensityBlend ("Global Intensity Blend", Range(0, 1)) = 1
        [HideInInspector] _FinalIntensity ("Final Intensity", Range(0, 1)) = 1
        [HideInInspector] _LUTBeamFinalIntensityVolumetric ("Volumetric Final Intensity", Range(0, 1)) = 1
        [HideInInspector] _LUTBeamFinalIntensityProjection ("Projection Final Intensity", Range(0, 1)) = 1
        [HideInInspector] _ConeWidth ("Fixture Cone Width", Float) = 2.25
        [HideInInspector] _ConeLength ("Fixture Cone Length", Float) = 2

        [HideInInspector] _StrobeFreq ("Strobe Frequency", Range(0, 25)) = 1
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
            Name "LUTBeam VVRSL DMX 13CH"
            Blend One One

            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #define VRSL_DMX
            #define VOLUMETRIC_YES
            #define LUTBEAM_EXTERNAL_CAMERA_DEPTH 1
            #define LUTBEAM_VIEW_INDEPENDENT_PROJECTION 1

            #include "UnityCG.cginc"
            #include "Packages/com.valenvrc.VVRSL/Runtime/Shaders/Shared/VRSL-Defines.cginc"
            #include "Packages/com.valenvrc.VVRSL/Runtime/Shaders/Shared/VRSL-DMXFunctions.cginc"

            Texture2DArray _GoboTex;
            Texture2DArray _GoboLUT;
            float _Offset;
            float _DMXZoomMin;
            float _DMXZoomMax;
            float _DMXZoomAspectX;
            float _DMXZoomAspectY;
            float _NearSizeX;
            float _NearSizeY;
            float _FarZ;
            float _GoboIntensity;
            float _BeamIntensity;
            float _BeamFalloff;
            float _LUTBeamDMXEditorPreviewActive;

            UNITY_INSTANCING_BUFFER_START(LUTBeamProps)
                UNITY_DEFINE_INSTANCED_PROP(float, _LUTBeamFinalIntensityVolumetric)
                UNITY_DEFINE_INSTANCED_PROP(float, _LUTBeamFinalIntensityProjection)
            UNITY_INSTANCING_BUFFER_END(LUTBeamProps)

            bool LUTBeamDMXIsEditorPreview()
            {
                return _LUTBeamDMXEditorPreviewActive > 0.5;
            }

            float LUTBeamDMXPan(uint dmxChannel)
            {
                if (LUTBeamDMXIsEditorPreview())
                    return 0.0;

                float inputValue = getValueAtCoords(dmxChannel, _Udon_DMXGridRenderTextureMovement);
                if (allowFineChannels() == 1)
                    inputValue += getValueAtCoords(dmxChannel + 1, _Udon_DMXGridRenderTextureMovement) / 256.0;

                return (getMinMaxPan() * 2.0 * inputValue) - getMinMaxPan();
            }

            float LUTBeamDMXTilt(uint dmxChannel)
            {
                if (LUTBeamDMXIsEditorPreview())
                    return 0.0;

                float inputValue = getValueAtCoords(dmxChannel + 2, _Udon_DMXGridRenderTextureMovement);
                if (allowFineChannels() == 1)
                    inputValue += getValueAtCoords(dmxChannel + 3, _Udon_DMXGridRenderTextureMovement) / 256.0;

                return (getMinMaxTilt() * 2.0 * inputValue) - getMinMaxTilt();
            }

            float3x3 LUTBeamDMXPanTiltRotation(uint dmxChannel)
            {
                float pan = radians(getOffsetY() + LUTBeamDMXPan(dmxChannel));
                float tilt = radians(getOffsetX() + LUTBeamDMXTilt(dmxChannel));

                float panSin;
                float panCos;
                float tiltSin;
                float tiltCos;
                sincos(pan, panSin, panCos);
                sincos(tilt, tiltSin, tiltCos);

                // Match VRSL-StandardMover-Vertex.cginc: pan rotates around
                // local Z and tilt rotates around local X.
                float3x3 panMatrix = float3x3(
                    panCos, -panSin, 0,
                    panSin, panCos, 0,
                    0, 0, 1
                );
                float3x3 tiltMatrix = float3x3(
                    1, 0, 0,
                    0, tiltCos, -tiltSin,
                    0, tiltSin, tiltCos
                );

                panMatrix = checkPanInvertY() == 1 ? transpose(panMatrix) : panMatrix;
                tiltMatrix = checkTiltInvertZ() == 1 ? transpose(tiltMatrix) : tiltMatrix;

                // VVRSL's mover beam meshes point down local -Y, while the
                // analytic LUTBeam frustum points down local -Z. Convert the
                // LUTBeam basis before applying VVRSL's pan/tilt transform.
                float3x3 beamBasisMatrix = float3x3(
                    1, 0, 0,
                    0, 0, -1,
                    0, 1, 0
                );

                // VVRSL multiplies column vectors by pan * tilt. LUTBeam.cginc
                // multiplies row vectors by the callback matrix, so both the
                // basis conversion and dynamic transform are transposed here.
                return mul(beamBasisMatrix, transpose(mul(panMatrix, tiltMatrix)));
            }

            float LUTBeamDMXGoboIndex(uint dmxChannel)
            {
                if (LUTBeamDMXIsEditorPreview())
                    return clamp(round((float)instancedGOBOSelection()), 1.0, 8.0) - 1.0;

                // Gobo selection is discrete channel data. The regular reader
                // converts single-universe RGB to luminance, which reduces a
                // red-only DMX value to 21.26% of its original range.
                float channelValue = getValueAtCoordsRaw(
                    dmxChannel + 11,
                    _Udon_DMXGridRenderTexture
                );
                float selection = round((channelValue * 255.0) / 30.0);
                return clamp(selection, 1.0, 8.0) - 1.0;
            }

            float LUTBeamDMXGoboSpin(uint dmxChannel)
            {
                if (LUTBeamDMXIsEditorPreview())
                    return 0.0;

                float status = getValueAtCoordsRaw(
                    dmxChannel + 10,
                    _Udon_DMXGridRenderTexture
                );
                float phase = getValueAtCoordsRaw(
                    dmxChannel + 10,
                    _Udon_DMXGridSpinTimer
                );
                phase = checkPanInvertY() == 1 ? -phase : phase;
                return status > 0.5 ? -phase * 4.0 : phase * 4.0;
            }

            #define LUTBEAM_CALLBACK_TRANSFORM 1
            float3x3 LUTBeamCallbackTransform(float3 vertex, inout float3 worldPositionOffset)
            {
                return LUTBeamDMXPanTiltRotation(getDMXChannel());
            }

            #define LUTBEAM_CALLBACK_STATE 1
            #define LUTBEAM_CALLBACK_UV_TRANSFORM 1
            float2 LUTBeamCallbackUVTransform(float2 uv, float4 callbackState)
            {
                float2 centered = uv - 0.5;
                return float2(
                    centered.x * callbackState.z - centered.y * callbackState.y,
                    centered.x * callbackState.y + centered.y * callbackState.z
                ) + 0.5;
            }

            #define LUTBEAM_CALLBACK_PROJECTION 1
            float3 LUTBeamCallbackProjection(SamplerState samp, float2 uv, float4 callbackState)
            {
                return _GoboTex.SampleLevel(samp, float3(uv, callbackState.x), 0).rrr;
            }

            #define LUTBEAM_CALLBACK_VOLUME 1
            float3 LUTBeamCallbackVolume(SamplerState samp, float2 uv, float4 callbackState)
            {
                return _GoboLUT.SampleLevel(samp, float3(uv, callbackState.x), 0).rrr;
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

                uint dmxChannel = getDMXChannel();
                bool dmxActive = !LUTBeamDMXIsEditorPreview();
                float zoomInput = dmxActive
                    ? getValueAtCoords(dmxChannel + 4, _Udon_DMXGridRenderTexture)
                    : 0.5;
                float zoom = lerp(
                    _DMXZoomMin,
                    _DMXZoomMax,
                    zoomInput
                );
                // The VVRSL fixture width is a calibration multiplier around
                // the prefab's 2.25 default. Channel 5 still supplies zoom.
                float coneWidthScale = max(getConeWidth() + 1.0, 0.001) / 2.25;
                float zoomX = zoom * _DMXZoomAspectX * coneWidthScale;
                float zoomY = zoom * _DMXZoomAspectY * coneWidthScale;

                // VVRSL stores Cone Length as abs(value - 10.5). Recover the
                // inspector value and preserve the prefab's 8.5 default.
                float fixtureConeLength = clamp(10.5 - getConeLength(), 0.5, 10.0);
                float beamLength = _FarZ * (fixtureConeLength / 8.5);
                float3 color = getEmissionColor().rgb;
                if (dmxActive)
                {
                    color *= float3(
                        getValueAtCoords(dmxChannel + 7, _Udon_DMXGridRenderTexture),
                        getValueAtCoords(dmxChannel + 8, _Udon_DMXGridRenderTexture),
                        getValueAtCoords(dmxChannel + 9, _Udon_DMXGridRenderTexture)
                    );
                }

                float strobe = dmxActive && isStrobe() == 1
                    ? getValueAtCoords(dmxChannel + 6, _Udon_DMXGridStrobeOutput)
                    : 1.0;
                float intensity = getGlobalIntensity()
                    * (dmxActive ? GetDMXIntensity(dmxChannel, 1.0) : 1.0)
                    * strobe;
                float volumetricIntensity = intensity * UNITY_ACCESS_INSTANCED_PROP(
                    LUTBeamProps,
                    _LUTBeamFinalIntensityVolumetric
                );
                float projectionIntensity = intensity * UNITY_ACCESS_INSTANCED_PROP(
                    LUTBeamProps,
                    _LUTBeamFinalIntensityProjection
                );

                // Spin is uniform across the fixture, so resolve it per vertex
                // and pass sine/cosine to the fragment stage.
                float goboSpin = isGOBOSpin() == 1 ? LUTBeamDMXGoboSpin(dmxChannel) : 0.0;
                float spinSin;
                float spinCos;
                sincos(goboSpin, spinSin, spinCos);
                float4 callbackState = float4(0, spinSin, spinCos, 0);
                o.beam = LUTBeamVert(
                    v.vertex,
                    zoomX,
                    zoomY,
                    beamLength,
                    _NearSizeX,
                    _NearSizeY,
                    _Offset,
                    color,
                    _BeamIntensity * volumetricIntensity,
                    _GoboIntensity * projectionIntensity,
                    _BeamFalloff,
                    callbackState
                );

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Resolve the discrete channel-12 slice after Unity restores
                // this fixture's instance ID. Both paths also share the
                // vertex-resolved channel-11 rotation in state Y/Z.
                i.beam.callbackState.x = LUTBeamDMXGoboIndex(getDMXChannel());

                float3 col = LUTBeamFrag(i.beam, _BeamFalloff);
                return float4(col, 0);
            }
            ENDCG
        }
    }

    CustomEditor "LUTBeam.Editor.LUTBeamDMXShaderGUI"
}
