param(
    [string]$Root = ""
)

# Strip any surrounding quotes or trailing slashes passed from Windows batch
if (-not [string]::IsNullOrWhiteSpace($Root)) {
    $Root = $Root.Trim().Trim('"', '''').TrimEnd('\', '/')
}

# If Root is still empty, default to parent directory of this script
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path -Parent $PSScriptRoot
}

$modelsDir = Join-Path $Root "Models"
$iniPath = Join-Path $Root "models.ini"

if (-not (Test-Path -LiteralPath $modelsDir)) {
    Write-Host "[!] Models directory not found at: $modelsDir" -ForegroundColor Yellow
    exit 0
}

# Scan for all GGUF files
$allGguf = Get-ChildItem -LiteralPath $modelsDir -Filter "*.gguf" -Recurse -File -ErrorAction SilentlyContinue
if (-not $allGguf -or $allGguf.Count -eq 0) {
    Write-Host "[*] No .gguf models found in $modelsDir yet." -ForegroundColor Yellow
    Write-Host "    Download GGUF models into the Models folder to get started." -ForegroundColor Gray
    exit 0
}

# Separate multimodal projectors and base models
$mmprojs = @($allGguf | Where-Object { $_.Name -like "*mmproj*" })
$models = @($allGguf | Where-Object { $_.Name -notlike "*mmproj*" })

$lines = @(
    "; ========================================================",
    "; Portable Local AI - Models Preset Configuration",
    "; Auto-generated on launch to map Models and Vision Projectors",
    "; ========================================================",
    ""
)

$visionCount = 0
$textCount = 0

foreach ($m in $models) {
    # Determine alias name: use folder name if in a subfolder, otherwise file base name
    $parentDir = $m.Directory.FullName.TrimEnd('\', '/')
    $modelsRoot = (Get-Item -LiteralPath $modelsDir).FullName.TrimEnd('\', '/')

    if ($parentDir -ne $modelsRoot) {
        $alias = $m.Directory.Name
    } else {
        $alias = [System.IO.Path]::GetFileNameWithoutExtension($m.Name)
    }

    # Clean alias: alphanumeric, dash and underscore only (safe for router and web UI)
    $cleanAlias = $alias -replace '[^a-zA-Z0-9_\-]', '-'

    # Check for matching mmproj:
    $matchedMm = $null
    # Rule 1: mmproj in the same subfolder
    if ($parentDir -ne $modelsRoot) {
        $matchedMm = $mmprojs | Where-Object { $_.DirectoryName -eq $m.DirectoryName } | Select-Object -First 1
    } else {
        # Rule 2: in root Models dir, match if filename has vision tags (vl, vision, llava, minicpm, etc.)
        $matchedMm = $mmprojs | Where-Object { 
            $_.DirectoryName -eq $m.DirectoryName -and (
                $m.BaseName.ToLower().Contains("vl") -or 
                $m.BaseName.ToLower().Contains("vision") -or 
                $m.BaseName.ToLower().Contains("llava") -or
                $m.BaseName.ToLower().Contains("minicpm")
            )
        } | Select-Object -First 1
    }

    # Relative path calculation (safe for any drive or path with spaces)
    $relModel = $m.FullName
    if ($relModel.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relModel = $relModel.Substring($Root.Length).TrimStart('\', '/')
    }
    $relModel = $relModel.Replace('\', '/')

    $lines += "[$cleanAlias]"
    $lines += "model = $relModel"
    if ($matchedMm) {
        $relMm = $matchedMm.FullName
        if ($relMm.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relMm = $relMm.Substring($Root.Length).TrimStart('\', '/')
        }
        $relMm = $relMm.Replace('\', '/')

        $lines += "mmproj = $relMm"
        $visionCount++
        Write-Host " [VISION]   $cleanAlias" -ForegroundColor Green
        Write-Host "            + Projector: $($matchedMm.Name)" -ForegroundColor DarkGreen
    } else {
        $textCount++
        Write-Host " [TEXT/R1]  $cleanAlias" -ForegroundColor Cyan
    }
    $lines += "ctx-size = 8192"
    $lines += "n-gpu-layers = 0"
    $lines += ""
}

# Write without BOM for compatibility with llama.cpp INI parser
[System.IO.File]::WriteAllLines($iniPath, $lines)
Write-Host ""
Write-Host "Preset updated: $textCount text/reasoning models, $visionCount vision models ready." -ForegroundColor White
