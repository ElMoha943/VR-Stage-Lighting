# Third-Party Notices

This file identifies the license notices distributed with VVRSL and the
package locations associated with each notice. All paths are relative to the
package root.

## VVRSL and upstream VRSL

- Component: VVRSL, a fork of VR Stage Lighting (VRSL)
- Copyright: Copyright (c) 2022 AcChosen; Copyright (c) 2026 valenvrc
- License: MIT
- Package location: the package as a whole, except for separately identified
  third-party material below
- License notice: [`LICENSES/VVRSL-MIT`](LICENSES/VVRSL-MIT)
- Upstream source: <https://github.com/AcChosen/VR-Stage-Lighting>
- Fork source: <https://github.com/ElMoha943/VR-Stage-Lighting>

## LUTBeam

- Component: LUTBeam and its VVRSL integration
- Copyright: Copyright (c) 2026 Torvid
- License: MIT
- License notice: [`LICENSES/LUTBeam-MIT`](LICENSES/LUTBeam-MIT)
- Package locations:
  - `Editor/LUTBeam/`
  - `Runtime/Scripts/LUTBeam/`
  - `Runtime/Shaders/LUTBeam/`
  - `Runtime/Textures/LUTBeam/`
  - `Runtime/Materials/Lights/LUTBeam/`
  - `Runtime/Materials/Lights/AudioLink/LUTBeam/`
  - `Runtime/Materials/Lights/DMX/LUTBeam/`
  - `Runtime/Prefabs/LUTBeam/`
  - `Runtime/Prefabs/DMX/Horizontal Mode/LUTBeam/`
- Upstream source: not stated in the bundled license notice

## GridReader and TekView

- Component: GridReader, an OSC reader for the VRSL grid node, and its bundled
  TekView assembly
- Copyright: Copyright (c) 2022 TekCastPork
- License: MIT
- License notice: [`LICENSES/GridReader-MIT.txt`](LICENSES/GridReader-MIT.txt)
- Package locations:
  - `Runtime/Scripts/GridReader/GridReader.cs`
  - `Runtime/Scripts/GridReader/TekView.dll`
  - `Runtime/Prefabs/DMX/GridReader/`
  - `Runtime/Materials/Other/VRSL-DMX-GridReader-H.mat`
  - `Runtime/Materials/Other/VRSL-DMX-GridReader-V.mat`
  - `Runtime/Textures/GridReader/`
- Upstream source: not stated in the bundled license notice

## SharpOSC

- Component: SharpOSC 0.1.1
- Copyright: Copyright (c) 2012 Valdemar Örn Erlingsson
- License: MIT
- License notice: [`LICENSES/SharpOSC-MIT.txt`](LICENSES/SharpOSC-MIT.txt)
- Package location: `Runtime/Scripts/GridReader/SharpOSC.dll`
- Upstream source: <https://github.com/ValdemarOrn/SharpOSC>

## Lamp_SludgeBath audio

- Component: `Lamp_SludgeBath.mp3`
- License indication: Creative Commons Attribution-NonCommercial-NoDerivatives
  (CC BY-NC-ND); the bundled badge does not state a license version
- License notice: [`LICENSES/Lamp_SludgeBath-CC-BY-NC-ND.png`](LICENSES/Lamp_SludgeBath-CC-BY-NC-ND.png)
- Package location: `Runtime/Prefabs/Media/Lamp_SludgeBath.mp3`
- Copyright holder and upstream source: not stated in the bundled license badge
