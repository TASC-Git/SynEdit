param(
    [string]$BdsRoot = 'C:\Program Files (x86)\Embarcadero\Studio\37.0',
    [ValidateSet('Win32', 'Win64')]
    [string[]]$Platforms = @('Win32', 'Win64')
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot '..\Source'
$project = Join-Path $PSScriptRoot 'IntegrationTests.dpr'

foreach ($platform in $Platforms) {
    $compilerName = if ($platform -eq 'Win32') { 'dcc32.exe' } else { 'dcc64.exe' }
    $compiler = Join-Path $BdsRoot "bin64\$compilerName"
    if (-not (Test-Path -LiteralPath $compiler)) {
        $compiler = Join-Path $BdsRoot "bin\$compilerName"
    }
    $output = Join-Path $PSScriptRoot "Output\$platform"
    New-Item -ItemType Directory -Path $output -Force | Out-Null
    $unitPath = @(
        $source
        (Join-Path $source 'Highlighters')
        (Join-Path $BdsRoot 'source\DUnit\src')
        (Join-Path $BdsRoot "lib\$platform\release")
    ) -join ';'
    & $compiler '-B' '-Q' '-NSSystem;Winapi;Vcl;System.Win' "-U$unitPath" "-I$source" "-N0$output" "-E$output" $project
    if ($LASTEXITCODE -ne 0) { throw "$platform test compilation failed." }
    Push-Location $output
    try {
        & (Join-Path $output 'IntegrationTests.exe')
        if ($LASTEXITCODE -ne 0) { throw "$platform regression tests failed." }
    } finally {
        Pop-Location
    }
}
