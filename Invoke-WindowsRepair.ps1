[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $env:ProgramData 'WindowsRepairTool'),
    [switch]$SkipDism,
    [switch]$SkipSfc,
    [switch]$SkipChkdsk
)

$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    throw 'Administrator privileges are required. Open PowerShell as Administrator and run this script again.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logPath = Join-Path $OutputDirectory "repair-$timestamp.log"
$resultPath = Join-Path $OutputDirectory "repair-$timestamp.json"
$results = [ordered]@{
    startedAt = (Get-Date).ToString('o')
    computerName = $env:COMPUTERNAME
    outputDirectory = $OutputDirectory
    checks = [ordered]@{}
}

Start-Transcript -Path $logPath -Force | Out-Null
try {
    if (-not $SkipDism) {
        Write-Host '=== Repairing the Windows component store (DISM) ===' -ForegroundColor Cyan
        & DISM.exe /Online /Cleanup-Image /RestoreHealth
        $results.checks.dism = [ordered]@{ exitCode = $LASTEXITCODE }
    }

    if (-not $SkipSfc) {
        Write-Host '=== Verifying protected system files (SFC) ===' -ForegroundColor Cyan
        & sfc.exe /scannow
        $results.checks.sfc = [ordered]@{ exitCode = $LASTEXITCODE }
    }

    if (-not $SkipChkdsk) {
        Write-Host '=== Scanning the system filesystem (CHKDSK) ===' -ForegroundColor Cyan
        & chkdsk.exe $env:SystemDrive /scan
        $results.checks.chkdsk = [ordered]@{ exitCode = $LASTEXITCODE }
    }
}
finally {
    $results.completedAt = (Get-Date).ToString('o')
    $results.logPath = $logPath
    $results | ConvertTo-Json -Depth 5 | Set-Content -Path $resultPath -Encoding UTF8
    Stop-Transcript | Out-Null
}

$failedChecks = @($results.checks.GetEnumerator() | Where-Object { $_.Value.exitCode -ne 0 })
if ($failedChecks.Count -gt 0) {
    Write-Error "One or more checks returned a non-zero exit code. See $resultPath and $logPath."
    exit 1
}

Write-Host "Repair checks completed successfully. Results: $resultPath" -ForegroundColor Green
exit 0
