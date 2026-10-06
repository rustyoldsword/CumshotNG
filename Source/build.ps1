# Rebuild Scripts\CS2GameScript.pex and Scripts\CS2SexLabScript.pex.
#
# The Bethesda Papyrus compiler cannot parse the SexLab P+ source tree (sslLovense,
# sslThreadModel state overrides, VRIK...), so the three SexLab scripts this file talks
# to are compiled against the hand-written stubs in Source\stubs. Those stubs declare
# only the members used here, with the real signatures; the Papyrus VM resolves every
# call by name against the real P+ scripts at runtime. The stubs are never shipped.
#
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File Source\build.ps1 -Game <Skyrim SE dir> -Mods <MO2 mods dir>
# IMPORTANT: the compiler also searches its own working directory, so this script sets it
# to a scratch folder - otherwise it can pick up a stale CS2SexLabScript.psc lying next
# to wherever you happened to run it from.

param(
    [string]$Game = $env:SKYRIM_GAME,   # Skyrim SE folder with 'Papyrus Compiler' and Data\Scripts\Source
    [string]$Mods = $env:SKYRIM_MODS    # MO2 mods folder with SkyUI, PapyrusUtil, RaceMenu, Mfg Fix NG sources
)

$ErrorActionPreference = 'Stop'
if (-not $Game -or -not $Mods) { throw 'Pass -Game and -Mods (or set SKYRIM_GAME / SKYRIM_MODS).' }

$modRoot  = Split-Path -Parent $PSScriptRoot
$mo2Mods  = $Mods
$gameRoot = $Game
$compiler = Join-Path $gameRoot 'Papyrus Compiler\PapyrusCompiler.exe'

$src   = Join-Path $modRoot 'scripts\source'   # all CS2*.psc live here
$out   = Join-Path $modRoot 'scripts'
$stubs = Join-Path $PSScriptRoot 'stubs'

$imports = @(
    $src
    $stubs
    (Join-Path $mo2Mods 'SkyUI\scripts\Source')
    (Join-Path $mo2Mods 'PapyrusUtil SE - Modders Scripting Utility Functions\Source\Scripts')
    (Join-Path $mo2Mods 'RaceMenu\Source\scripts')
    (Join-Path $mo2Mods 'Mfg Fix NG\source\scripts')
    (Join-Path $gameRoot 'Data\Scripts\Source')     # SKSE-extended vanilla sources
    (Join-Path $gameRoot 'Data\Source\Scripts')     # holds TESV_Papyrus_Flags.flg
) -join ';'

Push-Location $env:TEMP
try {
    # CS2GameScript (ejaculation logic + animation) and CS2SexLabScript (P+ orgasm handler).
    # The other CS2*.pex are unchanged from upstream and are not rebuilt.
    foreach ($name in 'CS2GameScript', 'CS2SexLabScript') {
        & $compiler (Join-Path $src "$name.psc") -f='TESV_Papyrus_Flags.flg' -i="$imports" -o="$out"
        if ($LASTEXITCODE -ne 0) { throw "compiling $name failed" }
    }
} finally {
    Pop-Location
}
