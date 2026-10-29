param(
    [string]$Godot = $env:GODOT_BIN
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not $Godot) {
    $portableDirectory = Join-Path $repoRoot '.tools/godot'
    if (Test-Path -LiteralPath $portableDirectory) {
        $portableEngine = Get-ChildItem -LiteralPath $portableDirectory -Filter 'Godot_v4*-stable_win64_console.exe' |
            Sort-Object Name -Descending | Select-Object -First 1
        if ($portableEngine) { $Godot = $portableEngine.FullName }
    }
}
if (-not $Godot) {
    foreach ($name in @('godot', 'godot4')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
        if ($command) { $Godot = $command.Source; break }
    }
}
if (-not $Godot) {
    throw 'Godot 4 not found. Pass -Godot C:/path/to/Godot_console.exe or set GODOT_BIN.'
}

# Child-process-only redirection keeps sandbox/CI user data inside this workspace.
# Restore the calling shell's environment even if engine startup fails.
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path $repoRoot '.tools/userdata'
    New-Item -ItemType Directory -Path $env:APPDATA -Force | Out-Null
    $testExitCode = 0
    foreach ($suitePath in @('res://tests/run_tests.gd', 'res://tests/viewer_smoke.gd')) {
        $engineOutput = @(& $Godot --headless --path (Join-Path $repoRoot 'game') --script $suitePath 2>&1)
        $testExitCode = $LASTEXITCODE
        $engineOutput | ForEach-Object { Write-Host $_ }
        # Godot may log script errors yet exit 0 (for example, inside _ready).
        $engineErrors = @($engineOutput | Where-Object { "$_" -match '^\s*(SCRIPT ERROR:|ERROR:)' })
        if ($testExitCode -eq 0 -and $engineErrors.Count -gt 0) {
            Write-Host 'FAIL: Godot reported engine/script errors despite a zero exit code.'
            $testExitCode = 1
        }
        if ($testExitCode -ne 0) { break }
    }
} finally {
    $env:APPDATA = $previousAppData
}
exit $testExitCode
