[CmdletBinding()]
param(
    [ValidateSet('start', 'restart', 'stop', 'status')]
    [string]$Mode = 'start',
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MiddlewareRoot = Join-Path $ProjectRoot 'middleware'
$LogRoot = Join-Path $MiddlewareRoot 'logs'
$Python = Get-Command python -ErrorAction SilentlyContinue
$Flutter = 'G:\tools\flutter\bin\flutter.bat'
$ApiBase = "http://127.0.0.1:$Port"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Get-MiddlewareProcesses {
    Get-CimInstance Win32_Process -Filter "Name = 'python.exe' OR Name = 'pythonw.exe'" |
        Where-Object { $_.CommandLine -like '*uvicorn*app.main:app*' }
}

function Stop-Middleware {
    $processes = @(Get-MiddlewareProcesses)
    foreach ($process in $processes) {
        Write-Host "Stopping middleware PID $($process.ProcessId)..." -ForegroundColor Yellow
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
    }
    if ($processes.Count -eq 0) {
        Write-Host 'No existing middleware process found.' -ForegroundColor DarkGray
    }
}

function Show-Commands {
    Write-Host "`nLOCAL TESTING LINKS" -ForegroundColor Green
    Write-Host "Health:       $ApiBase/health"
    Write-Host "API docs:     $ApiBase/docs"
    Write-Host "Citizen web:  $ApiBase/app/"
    Write-Host "Console web:  $ApiBase/console"
    Write-Host "Privacy:      $ApiBase/privacy"
    Write-Host "Terms:        $ApiBase/terms"
    Write-Host "`nFLUTTER COMMANDS" -ForegroundColor Green
    Write-Host "Set-Location '$ProjectRoot\frontend\mobile'"
    Write-Host "& '$Flutter' pub get"
    Write-Host "& '$Flutter' run --dart-define=SAHAYAK_API_BASE=$ApiBase"
    Write-Host "`nAPI TEST COMMANDS" -ForegroundColor Green
    Write-Host "Invoke-RestMethod '$ApiBase/health'"
    Write-Host "Invoke-RestMethod '$ApiBase/v1/meta'"
    Write-Host "`nLOGS" -ForegroundColor Green
    Write-Host "Output: $LogRoot\middleware.out.log"
    Write-Host "Errors: $LogRoot\middleware.err.log"
}

if (-not $Python) {
    throw 'Python was not found on PATH. Install Python 3.11+ and reopen PowerShell.'
}
if (-not (Test-Path $MiddlewareRoot)) {
    throw "Middleware folder not found: $MiddlewareRoot"
}

switch ($Mode) {
    'status' {
        $processes = @(Get-MiddlewareProcesses)
        if ($processes.Count -gt 0) {
            Write-Host "Middleware process is running: PID $($processes[0].ProcessId)" -ForegroundColor Green
        } else {
            Write-Host 'Middleware is not running.' -ForegroundColor Yellow
        }
        Show-Commands
        exit 0
    }
    'stop' {
        Stop-Middleware
        Write-Host 'Middleware stopped.' -ForegroundColor Green
        exit 0
    }
    'restart' {
        Write-Step 'Stopping any old middleware process'
        Stop-Middleware
    }
}

Write-Step 'Installing/updating middleware dependencies'
Push-Location $MiddlewareRoot
try {
    & $Python.Source -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed.' }
} finally {
    Pop-Location
}

New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
Remove-Item (Join-Path $LogRoot 'middleware.out.log'), (Join-Path $LogRoot 'middleware.err.log') -Force -ErrorAction SilentlyContinue

Write-Step "Starting FastAPI middleware on $ApiBase"
$arguments = "-m uvicorn app.main:app --host 127.0.0.1 --port $Port"
Start-Process -FilePath $Python.Source `
    -ArgumentList $arguments `
    -WorkingDirectory $MiddlewareRoot `
    -RedirectStandardOutput (Join-Path $LogRoot 'middleware.out.log') `
    -RedirectStandardError (Join-Path $LogRoot 'middleware.err.log') `
    -WindowStyle Hidden | Out-Null

$healthy = $false
for ($attempt = 1; $attempt -le 30; $attempt++) {
    try {
        $response = Invoke-WebRequest "$ApiBase/health" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $healthy = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $healthy) {
    Write-Host "Middleware did not become healthy. Read: $LogRoot\middleware.err.log" -ForegroundColor Red
    exit 1
}

Write-Host "`nSaHayak middleware started successfully." -ForegroundColor Green
Show-Commands
