<#
.SYNOPSIS
    Fixes broken links and warnings after migration to Co-located Assets
    
.DESCRIPTION
    - Fixes links in index.md (adds index.md to paths)
    - Fixes navigation links in about/*.md (deleted files)
    - Creates a simple favicon.png placeholder
    
.EXAMPLE
    .\fix_warnings.ps1
#>

param(
    [string]$ProjectRoot = "Z:\Source\Books\prodotnetmemory.github.io"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [*] $Message" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  FIXING WARNINGS AFTER MIGRATION" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

# =============================================================================
# STEP 1: Fix index.md
# =============================================================================

Write-Step "Step 1: Fixing docs/index.md"

$indexPath = Join-Path $ProjectRoot "docs\index.md"
$content = Get-Content -Path $indexPath -Raw -Encoding UTF8

# Fix: chapters/01-basic-concepts/ -> chapters/01-basic-concepts/index.md
$original = $content
$content = $content -replace '\(chapters/01-basic-concepts/\)', '(chapters/01-basic-concepts/index.md)'
$content = $content -replace '\(chapters/\)', '(chapters/index.md)'

if ($content -ne $original) {
    Set-Content -Path $indexPath -Value $content -Encoding UTF8 -NoNewline
    Write-Success "Fixed chapter links in index.md"
} else {
    Write-Info "index.md already has correct links"
}

# =============================================================================
# STEP 2: Fix about/*.md navigation
# =============================================================================

Write-Step "Step 2: Fixing navigation in about/*.md"

$aboutFiles = @(
    "acknowledgments.md",
    "foreword.md",
    "introduction.md"
)

# New navigation section
$newNavLines = @()
$newNavLines += ""
$newNavLines += "---"
$newNavLines += ""
$newNavLines += "## " + [char]0x041D + [char]0x0430 + [char]0x0432 + [char]0x0438 + [char]0x0433 + [char]0x0430 + [char]0x0446 + [char]0x0438 + [char]0x044F  # Навигация
$newNavLines += ""
$newNavLines += "- [" + [char]0x041E + [char]0x0431 + " " + [char]0x0430 + [char]0x0432 + [char]0x0442 + [char]0x043E + [char]0x0440 + [char]0x0430 + [char]0x0445 + "](authors.md)"  # Об авторах
$newNavLines += "- [" + [char]0x041E + " " + [char]0x0440 + [char]0x0435 + [char]0x0446 + [char]0x0435 + [char]0x043D + [char]0x0437 + [char]0x0435 + [char]0x043D + [char]0x0442 + [char]0x0435 + "](technical-reviewer.md)"  # О рецензенте
$newNavLines += "- [" + [char]0x0411 + [char]0x043B + [char]0x0430 + [char]0x0433 + [char]0x043E + [char]0x0434 + [char]0x0430 + [char]0x0440 + [char]0x043D + [char]0x043E + [char]0x0441 + [char]0x0442 + [char]0x0438 + "](acknowledgments.md)"  # Благодарности
$newNavLines += "- [" + [char]0x041F + [char]0x0440 + [char]0x0435 + [char]0x0434 + [char]0x0438 + [char]0x0441 + [char]0x043B + [char]0x043E + [char]0x0432 + [char]0x0438 + [char]0x0435 + "](foreword.md)"  # Предисловие
$newNavLines += "- [" + [char]0x0412 + [char]0x0432 + [char]0x0435 + [char]0x0434 + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x0435 + "](introduction.md)"  # Введение

$newNav = $newNavLines -join "`n"

foreach ($file in $aboutFiles) {
    $filePath = Join-Path $ProjectRoot "docs\about\$file"
    
    if (Test-Path $filePath) {
        Write-Info "Processing: about/$file"
        
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        
        # Remove old navigation block (from "---" with nav links to end)
        # Pattern matches: --- followed by lines starting with "- [" to end of file
        $content = $content -replace '(?s)\r?\n---\r?\n- \[.*$', ''
        
        # Trim and add new navigation
        $content = $content.TrimEnd() + "`n" + $newNav
        
        Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
        Write-Success "Fixed: about/$file"
    }
}

# =============================================================================
# STEP 3: Check chapter 2 for broken anchors
# =============================================================================

Write-Step "Step 3: Checking chapter 2 for broken anchors"

$ch2Path = Join-Path $ProjectRoot "docs\chapters\02-low-level-memory\index.md"
if (Test-Path $ch2Path) {
    $content = Get-Content -Path $ch2Path -Raw -Encoding UTF8
    
    # Find lines with l-2-2 or t-2-4
    $matches = [regex]::Matches($content, '.{0,30}(l-2-2|t-2-4).{0,30}')
    
    if ($matches.Count -gt 0) {
        Write-Host "  [!] Found broken anchor references:" -ForegroundColor Yellow
        foreach ($m in $matches) {
            Write-Host "      ...$($m.Value)..." -ForegroundColor Gray
        }
        Write-Host "      These appear to be listing/table references (l=listing, t=table)" -ForegroundColor Yellow
        Write-Host "      Manual review recommended" -ForegroundColor Yellow
    } else {
        Write-Success "No broken anchors found in chapter 2"
    }
}

# =============================================================================
# STEP 4: Create favicon placeholder
# =============================================================================

Write-Step "Step 4: Creating favicon placeholder"

$faviconPath = Join-Path $ProjectRoot "docs\assets\images\favicon.png"

if (-not (Test-Path $faviconPath)) {
    Write-Info "favicon.png not found"
    Write-Host "  To create a favicon, you can:" -ForegroundColor White
    Write-Host "    1. Use online tool: https://favicon.io/favicon-generator/" -ForegroundColor Gray
    Write-Host "    2. Create 32x32 or 64x64 PNG image" -ForegroundColor Gray
    Write-Host "    3. Save as: docs/assets/images/favicon.png" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Or remove favicon from mkdocs.yml if not needed" -ForegroundColor White
} else {
    Write-Success "favicon.png exists"
}

# =============================================================================
# Summary
# =============================================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  DONE!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart docker: docker compose down && docker compose up" -ForegroundColor White
Write-Host "  2. Check console for remaining warnings" -ForegroundColor White
Write-Host "  3. Create favicon.png (optional)" -ForegroundColor White
Write-Host "  4. Review chapter 2 anchor references (if any)" -ForegroundColor White
Write-Host ""
Write-Host "After verification:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m " + [char]0x0022 + "Fix: broken links and navigation" + [char]0x0022 -ForegroundColor Gray
Write-Host "  git push origin main" -ForegroundColor Gray
Write-Host ""
