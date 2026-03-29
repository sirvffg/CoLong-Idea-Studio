$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$venv = Join-Path $root ".venv-shared"

if (-not (Test-Path (Join-Path $venv "Scripts\python.exe"))) {
  python -m venv $venv
}

$python = Join-Path $venv "Scripts\python.exe"

& $python -m pip install --upgrade pip setuptools wheel

function Install-RequirementFileLight {
  param(
    [string]$RequirementFile
  )

  if (-not (Test-Path $RequirementFile)) {
    return
  }

  $temp = Join-Path $env:TEMP ("colong-lite-" + [System.IO.Path]::GetRandomFileName() + ".txt")
  $skipPrefixes = @(
    "sentence-transformers",
    "torch",
    "torchvision",
    "torchaudio",
    "transformers",
    "safetensors",
    "scikit-learn",
    "scipy",
    "threadpoolctl",
    "joblib",
    "networkx"
  )

  $lines = Get-Content $RequirementFile | Where-Object {
    $line = ($_ | Out-String).Trim()
    if (-not $line -or $line.StartsWith("#")) { return $true }
    foreach ($prefix in $skipPrefixes) {
      if ($line -like "$prefix*") { return $false }
    }
    return $true
  }

  Set-Content -Path $temp -Value $lines -Encoding UTF8
  try {
    & $python -m pip install -r $temp
  } finally {
    Remove-Item $temp -Force -ErrorAction SilentlyContinue
  }
}

Install-RequirementFileLight -RequirementFile (Join-Path $root "apps\auth-portal\requirements.txt")
Install-RequirementFileLight -RequirementFile (Join-Path $root "apps\multiagent\requirements.txt")
Install-RequirementFileLight -RequirementFile (Join-Path $root "apps\multiagent\local_web_portal\requirements.txt")
Install-RequirementFileLight -RequirementFile (Join-Path $root "apps\novelclaw\requirements.txt")
Install-RequirementFileLight -RequirementFile (Join-Path $root "apps\novelclaw\local_web_portal\requirements.txt")

Write-Host "[ok] shared venv ready: $python"
