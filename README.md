# Cumshot NG - SexLab P+

Port of Cumshot 2.0 to SexLab P+ with a particle + projectile hybrid mode and optional UBE race
support. This repository holds the source of the changed scripts, the two patch plugins and the
build tools; the meshes, textures, sounds and the original `Cumshot.esp` / `CumshotSL.esp` ship
only in the release.

Mod page: https://dwemermods.com/mods/4266

## Contents

| Path | Contents |
|---|---|
| `scripts/source/` | All `CS2*.psc`. `CS2GameScript` and `CS2SexLabScript` are changed; the rest are upstream |
| `Source/build.ps1`, `Source/stubs/` | Rebuilds the two changed scripts against hand-written SexLab P+ / SOS stubs (never shipped) |
| `SKSE/Plugins/StorageUtilData/Cumshot/` | Rule and adjustment JSON; `PPlusRules.json` has the `hybridProjectiles` switch |
| `plugins/Cumshot - Particles Hybrid.esp` | Required. Invisible PROJ 0x800 / MGEF 0x801 (splash impact set) / SPEL 0x802, and `CS2ConfigQuest` defaulting to Particles mode |
| `plugins/Cumshot - UBE Races.esp` | Optional, needs `UBE_AllRace.esp`. Adds the 18 UBE races to all 36 Cumshot ArmorAddons |
| `tools/gen_spurt_times.py` | Regenerates the `ParticleSpurtTimes()` table in `CS2GameScript.psc` from the emitter keys of the particle meshes |

## Hybrid mode

In Particles mode `CS2GameScript` fires one invisible projectile per particle spurt, at the spurt
start times read from the meshes, along the emitter axis, so the particle effect leaves splash
decals. The spell is looked up with `GetFormFromFile(0x802, "Cumshot - Particles Hybrid.esp")`,
because `GetModByName` cannot see ESL plugins.

## Building

```
powershell -ExecutionPolicy Bypass -File Source\build.ps1 -Game <Skyrim SE dir> -Mods <MO2 mods dir>
python tools\gen_spurt_times.py <Cumshot mod>\meshes\Cumshot
```

The Papyrus build imports SkyUI, PapyrusUtil, RaceMenu and Mfg Fix NG sources from the MO2 mods folder.

## Credits

Cumshot 2.0 and all its assets belong to their original authors; this is a compatibility port.
