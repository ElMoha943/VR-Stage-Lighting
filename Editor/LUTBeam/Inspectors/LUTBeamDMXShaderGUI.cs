#if !COMPILER_UDONSHARP && UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace LUTBeam.Editor
{
    [InitializeOnLoad]
    internal static class LUTBeamDMXEditorPreview
    {
        private static readonly int PreviewProperty =
            Shader.PropertyToID("_LUTBeamDMXEditorPreviewActive");

        static LUTBeamDMXEditorPreview()
        {
            EditorApplication.playModeStateChanged += OnPlayModeStateChanged;
            AssemblyReloadEvents.beforeAssemblyReload += DisablePreview;
            EditorApplication.delayCall += RefreshPreviewState;
            RefreshPreviewState();
        }

        private static void OnPlayModeStateChanged(PlayModeStateChange state)
        {
            RefreshPreviewState();
        }

        private static void RefreshPreviewState()
        {
            bool previewActive = !EditorApplication.isPlayingOrWillChangePlaymode;
            Shader.SetGlobalFloat(PreviewProperty, previewActive ? 1f : 0f);
            SceneView.RepaintAll();
        }

        private static void DisablePreview()
        {
            Shader.SetGlobalFloat(PreviewProperty, 0f);
        }
    }

    public sealed class LUTBeamDMXShaderGUI : ShaderGUI
    {
        private static bool showDMXSettings = true;
        private static bool showMovement = true;
        private static bool showBeamShape = true;
        private static bool showGoboArrays = true;
        private static bool showColorAndIntensity = true;
        private static bool showAdvanced;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            GUILayout.Space(4f);
            DrawHeader("LUTBeam VVRSL DMX 13CH");
            GUILayout.Space(6f);

            DrawDMXSettings(materialEditor, properties);
            DrawMovement(materialEditor, properties);
            DrawBeamShape(materialEditor, properties);
            DrawGoboArrays(materialEditor, properties);
            DrawColorAndIntensity(materialEditor, properties);
            DrawAdvanced(materialEditor);
        }

        private void DrawDMXSettings(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            showDMXSettings = DrawFoldout("DMX Settings", showDMXSettings);
            if (!showDMXSettings)
                return;

            using (new EditorGUI.IndentLevelScope())
            {
                MaterialProperty channel = GetProperty("_DMXChannel", properties);
                DrawProperty(materialEditor, channel, "Flattened Starting Channel");
                DrawProperty(materialEditor, GetProperty("_NineUniverseMode", properties), "Extended Universe Mode");
                DrawProperty(materialEditor, GetProperty("_EnableFineChannels", properties), "Fine Pan and Tilt");
                DrawProperty(materialEditor, GetProperty("_EnableStrobe", properties), "Strobe");
                DrawProperty(materialEditor, GetProperty("_EnableSpin", properties), "Gobo Spin");

                EditorGUILayout.HelpBox(
                    "1 Pan | 2 Fine Pan | 3 Tilt | 4 Fine Tilt | 5 Zoom | 6 Dimmer | " +
                    "7 Strobe | 8-10 RGB | 11 Gobo Spin | 12 Gobo Select | 13 Movement Speed",
                    MessageType.None);

                DrawAddressSummary(channel);
            }

            GUILayout.Space(4f);
        }

        private void DrawMovement(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            showMovement = DrawFoldout("Movement", showMovement);
            if (!showMovement)
                return;

            using (new EditorGUI.IndentLevelScope())
            {
                DrawProperty(materialEditor, GetProperty("_PanInvert", properties), "Invert Pan");
                DrawProperty(materialEditor, GetProperty("_TiltInvert", properties), "Invert Tilt");
                DrawProperty(materialEditor, GetProperty("_MaxMinPanAngle", properties), "Pan Half Range");
                DrawProperty(materialEditor, GetProperty("_MaxMinTiltAngle", properties), "Tilt Half Range");
                DrawProperty(materialEditor, GetProperty("_FixtureBaseRotationY", properties), "Pan Offset");
                DrawProperty(materialEditor, GetProperty("_FixtureRotationX", properties), "Tilt Offset");
            }

            GUILayout.Space(4f);
        }

        private void DrawBeamShape(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            showBeamShape = DrawFoldout("Beam Shape", showBeamShape);
            if (!showBeamShape)
                return;

            using (new EditorGUI.IndentLevelScope())
            {
                MaterialProperty zoomMin = GetProperty("_DMXZoomMin", properties);
                MaterialProperty zoomMax = GetProperty("_DMXZoomMax", properties);
                MaterialProperty farZ = GetProperty("_FarZ", properties);

                DrawProperty(materialEditor, zoomMin, "DMX Zoom Minimum");
                DrawProperty(materialEditor, zoomMax, "DMX Zoom Maximum");
                DrawProperty(materialEditor, GetProperty("_DMXZoomAspectX", properties), "DMX Zoom X Scale");
                DrawProperty(materialEditor, GetProperty("_DMXZoomAspectY", properties), "DMX Zoom Y Scale");
                DrawProperty(materialEditor, GetProperty("_NearSizeX", properties), "Near Size X");
                DrawProperty(materialEditor, GetProperty("_NearSizeY", properties), "Near Size Y");
                DrawProperty(materialEditor, GetProperty("_Offset", properties), "Lens Offset");
                DrawProperty(materialEditor, farZ, "Beam Length");

                if (HasSingleValue(zoomMin) && HasSingleValue(zoomMax) && zoomMin.floatValue > zoomMax.floatValue)
                    EditorGUILayout.HelpBox("DMX Zoom Minimum is greater than DMX Zoom Maximum.", MessageType.Warning);

                if (HasSingleValue(farZ) && farZ.floatValue <= 0f)
                    EditorGUILayout.HelpBox("Beam Length must be greater than zero.", MessageType.Warning);
            }

            GUILayout.Space(4f);
        }

        private void DrawGoboArrays(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            showGoboArrays = DrawFoldout("Gobo Arrays", showGoboArrays);
            if (!showGoboArrays)
                return;

            using (new EditorGUI.IndentLevelScope())
            {
                MaterialProperty projectionProperty = GetProperty("_GoboTex", properties);
                MaterialProperty volumeProperty = GetProperty("_GoboLUT", properties);

                if (projectionProperty != null)
                    materialEditor.TexturePropertySingleLine(new GUIContent("Projection Gobo Array"), projectionProperty);
                if (volumeProperty != null)
                    materialEditor.TexturePropertySingleLine(new GUIContent("Volumetric LUT Array"), volumeProperty);

                DrawGoboArrayStatus(projectionProperty, volumeProperty);
            }

            GUILayout.Space(4f);
        }

        private void DrawColorAndIntensity(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            showColorAndIntensity = DrawFoldout("Color and Intensity", showColorAndIntensity);
            if (!showColorAndIntensity)
                return;

            using (new EditorGUI.IndentLevelScope())
            {
                DrawProperty(materialEditor, GetProperty("_Emission", properties), "Light Color Tint");
                DrawProperty(materialEditor, GetProperty("_BeamIntensity", properties), "Maximum Beam Intensity");
                DrawProperty(materialEditor, GetProperty("_GoboIntensity", properties), "Maximum Gobo Intensity");
                DrawProperty(materialEditor, GetProperty("_BeamFalloff", properties), "Beam Falloff");
                DrawProperty(materialEditor, GetProperty("_GlobalIntensity", properties), "Global Intensity");
                DrawProperty(materialEditor, GetProperty("_GlobalIntensityBlend", properties), "Global Intensity Blend");
            }

            GUILayout.Space(4f);
        }

        private static void DrawAdvanced(MaterialEditor materialEditor)
        {
            showAdvanced = DrawFoldout("Advanced", showAdvanced);
            if (!showAdvanced)
                return;

            using (new EditorGUI.IndentLevelScope())
            {
                materialEditor.EnableInstancingField();
                materialEditor.RenderQueueField();
            }
        }

        private MaterialProperty GetProperty(string name, MaterialProperty[] properties)
        {
            return FindProperty(name, properties, false);
        }

        private static void DrawProperty(MaterialEditor materialEditor, MaterialProperty property, string label)
        {
            if (property != null)
                materialEditor.ShaderProperty(property, new GUIContent(label));
        }

        private static bool HasSingleValue(MaterialProperty property)
        {
            return property != null && !property.hasMixedValue;
        }

        private static void DrawAddressSummary(MaterialProperty channel)
        {
            if (!HasSingleValue(channel))
                return;

            int start = Mathf.RoundToInt(channel.floatValue);
            if (start < 1)
            {
                EditorGUILayout.HelpBox("The flattened starting channel must be 1 or greater.", MessageType.Error);
                return;
            }

            EditorGUILayout.HelpBox(
                "Flattened address range: " + start + "-" + (start + 12) + "\n" +
                "Gobo spin: " + (start + 10) + " | Gobo select: " + (start + 11),
                MessageType.Info);
        }

        private static void DrawGoboArrayStatus(
            MaterialProperty projectionProperty,
            MaterialProperty volumeProperty)
        {
            if (projectionProperty == null || volumeProperty == null ||
                projectionProperty.hasMixedValue || volumeProperty.hasMixedValue)
                return;

            Texture projectionTexture = projectionProperty.textureValue;
            Texture volumeTexture = volumeProperty.textureValue;
            Texture2DArray projectionArray = projectionTexture as Texture2DArray;
            Texture2DArray volumeArray = volumeTexture as Texture2DArray;

            if (projectionTexture == null || volumeTexture == null)
            {
                EditorGUILayout.HelpBox("Assign both gobo texture arrays.", MessageType.Error);
                return;
            }

            if (projectionArray == null || volumeArray == null)
            {
                EditorGUILayout.HelpBox("Both gobo assets must be Texture2DArray assets.", MessageType.Error);
                return;
            }

            if (projectionArray.depth != volumeArray.depth)
            {
                EditorGUILayout.HelpBox(
                    "Array slice counts do not match: projection has " + projectionArray.depth +
                    " and volume has " + volumeArray.depth + ".",
                    MessageType.Error);
                return;
            }

            if (projectionArray.depth < 8)
            {
                EditorGUILayout.HelpBox(
                    "This DMX mapping addresses 8 gobos, but the arrays only contain " +
                    projectionArray.depth + " slices.",
                    MessageType.Error);
                return;
            }

            if (projectionArray.depth > 8)
            {
                EditorGUILayout.HelpBox(
                    "Both arrays contain " + projectionArray.depth +
                    " aligned slices. This fixture addresses the first 8.",
                    MessageType.Warning);
                return;
            }

            EditorGUILayout.HelpBox("Projection and volume arrays are aligned at 8 slices.", MessageType.Info);
        }

        private static void DrawHeader(string title)
        {
            GUIStyle style = new GUIStyle("ShurikenModuleTitle")
            {
                font = EditorStyles.boldLabel.font,
                border = new RectOffset(15, 7, 4, 4),
                fixedHeight = 26f,
                contentOffset = new Vector2(0f, -2f),
                alignment = TextAnchor.MiddleCenter
            };

            Rect rect = GUILayoutUtility.GetRect(16f, 26f, style);
            GUI.Box(rect, title, style);
        }

        private static bool DrawFoldout(string title, bool display)
        {
            GUIStyle style = new GUIStyle("ShurikenModuleTitle")
            {
                font = EditorStyles.boldLabel.font,
                border = new RectOffset(15, 7, 4, 4),
                fixedHeight = 22f,
                contentOffset = new Vector2(20f, -2f)
            };

            Rect rect = GUILayoutUtility.GetRect(16f, 22f, style);
            GUI.Box(rect, title, style);

            Rect toggleRect = new Rect(rect.x + 4f, rect.y + 2f, 13f, 13f);
            if (Event.current.type == EventType.Repaint)
                EditorStyles.foldout.Draw(toggleRect, false, false, display, false);

            if (Event.current.type == EventType.MouseDown && rect.Contains(Event.current.mousePosition))
            {
                display = !display;
                Event.current.Use();
            }

            return display;
        }
    }
}
#endif
