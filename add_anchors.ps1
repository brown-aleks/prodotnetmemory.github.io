<#
.SYNOPSIS
    Adds HTML anchors to figures and listings in chapter files
    
.DESCRIPTION
    Scans chapter index.md files and adds <a id="..."></a> anchors:
    - Before figures: <a id="f-X-Y"></a> before ![Risunok X-Y]
    - Before code blocks that are listings: <a id="l-X-Y"></a>
    - Before tables: <a id="t-X-Y"></a>
    
.EXAMPLE
    .\add_anchors.ps1 -WhatIf
    
.EXAMPLE
    .\add_anchors.ps1
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ProjectRoot = "Z:\Source\Books\prodotnetmemory.github.io"
)

$ErrorActionPreference = "Stop"

# Build Russian words using Unicode to avoid encoding issues
# Risunok = Р и с у н о к
$R_Upper = [char]0x0420  # Р
$R_Lower = [char]0x0440  # р
$I_Char = [char]0x0438   # и
$S_Char = [char]0x0441   # с
$U_Char = [char]0x0443   # у
$N_Char = [char]0x043D   # н
$O_Char = [char]0x043E   # о
$K_Char = [char]0x043A   # к

# Listing = Л и с т и н г
$L_Upper = [char]0x041B  # Л
$L_Lower = [char]0x043B  # л
$T_Char = [char]0x0442   # т
$G_Char = [char]0x0433   # г

# Tablica = Т а б л и ц а
$T_Upper = [char]0x0422  # Т
$T_Lower = [char]0x0442  # т
$A_Char = [char]0x0430   # а
$B_Char = [char]0x0431   # б
$Ts_Char = [char]0x0446  # ц

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

function Add-FigureAnchors {
    param([string]$Content)
    
    # Build word: Рисунок (both upper and lower first letter)
    $risunokClass = "[$R_Upper$R_Lower]"
    $figureWord = "$risunokClass$I_Char$S_Char$U_Char$N_Char$O_Char$K_Char"
    
    # Match figures: ![Рисунок 1-1](...) - but only if not already preceded by anchor
    $figurePattern = "(?<!<a id=`"f-[^`"]+`"></a>\s*)(\!\[$figureWord\s+(\d+-\d+[a-z]?)\])"
    
    $result = [regex]::Replace($Content, $figurePattern, {
        param($match)
        $figNum = $match.Groups[2].Value
        $figTag = $match.Groups[1].Value
        return "<a id=`"f-$figNum`"></a>`n$figTag"
    })
    
    return $result
}

function Add-ListingAnchors {
    param([string]$Content)
    
    # Build word: Листинг
    $listingClass = "[$L_Upper$L_Lower]"
    $listingWord = "$listingClass$I_Char$S_Char$T_Char$I_Char$N_Char$G_Char"
    
    # Match: Листинг X-Y or **Листинг X-Y**
    $listingPattern = "(?<!<a id=`"l-[^`"]+`"></a>\s*)((?:^|\n)(\s*\*?\*?)($listingWord)\s+(\d+-\d+[a-z]?))"
    
    $result = [regex]::Replace($Content, $listingPattern, {
        param($match)
        $listNum = $match.Groups[4].Value
        $fullMatch = $match.Groups[1].Value
        
        # Determine if it starts with newline
        if ($fullMatch.StartsWith("`n")) {
            return "`n<a id=`"l-$listNum`"></a>" + $fullMatch.Substring(1)
        } else {
            return "<a id=`"l-$listNum`"></a>$fullMatch"
        }
    })
    
    return $result
}

function Add-TableAnchors {
    param([string]$Content)
    
    # Build word: Таблица
    $tablicaClass = "[$T_Upper$T_Lower]"
    $tablicaWord = "$tablicaClass$A_Char$B_Char$L_Lower$I_Char$Ts_Char$A_Char"
    
    # Match: Таблица X-Y
    $tablePattern = "(?<!<a id=`"t-[^`"]+`"></a>\s*)((?:^|\n)(\s*\*?\*?)($tablicaWord)\s+(\d+-\d+[a-z]?))"
    
    $result = [regex]::Replace($Content, $tablePattern, {
        param($match)
        $tableNum = $match.Groups[4].Value
        $fullMatch = $match.Groups[1].Value
        
        if ($fullMatch.StartsWith("`n")) {
            return "`n<a id=`"t-$tableNum`"></a>" + $fullMatch.Substring(1)
        } else {
            return "<a id=`"t-$tableNum`"></a>$fullMatch"
        }
    })
    
    return $result
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  ADDING ANCHORS TO FIGURES AND LISTINGS" -ForegroundColor Magenta
Write-Host "============================================" -ForegroundColor Magenta

$chaptersDir = Join-Path $ProjectRoot "docs\chapters"
$chapters = Get-ChildItem -Path $chaptersDir -Directory | Where-Object { $_.Name -match '^\d{2}-' }

$totalFigAdded = 0
$totalListAdded = 0
$totalTableAdded = 0

foreach ($chapter in $chapters) {
    $indexPath = Join-Path $chapter.FullName "index.md"
    
    if (Test-Path $indexPath) {
        Write-Step "Processing: $($chapter.Name)"
        
        $content = Get-Content -Path $indexPath -Raw -Encoding UTF8
        $originalContent = $content
        
        # Count existing anchors
        $existingFigAnchors = ([regex]::Matches($content, '<a id="f-')).Count
        $existingListAnchors = ([regex]::Matches($content, '<a id="l-')).Count
        $existingTableAnchors = ([regex]::Matches($content, '<a id="t-')).Count
        
        Write-Info "Existing anchors: figures=$existingFigAnchors, listings=$existingListAnchors, tables=$existingTableAnchors"
        
        # Add anchors
        $content = Add-FigureAnchors -Content $content
        $content = Add-ListingAnchors -Content $content
        $content = Add-TableAnchors -Content $content
        
        # Count new anchors
        $newFigAnchors = ([regex]::Matches($content, '<a id="f-')).Count
        $newListAnchors = ([regex]::Matches($content, '<a id="l-')).Count
        $newTableAnchors = ([regex]::Matches($content, '<a id="t-')).Count
        
        $addedFig = $newFigAnchors - $existingFigAnchors
        $addedList = $newListAnchors - $existingListAnchors
        $addedTable = $newTableAnchors - $existingTableAnchors
        
        $totalFigAdded += $addedFig
        $totalListAdded += $addedList
        $totalTableAdded += $addedTable
        
        if ($content -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($indexPath, "Add anchors (+$addedFig fig, +$addedList list, +$addedTable tbl)")) {
                Set-Content -Path $indexPath -Value $content -Encoding UTF8 -NoNewline
                Write-Success "Added: +$addedFig figures, +$addedList listings, +$addedTable tables"
            }
        } else {
            Write-Info "No changes needed"
        }
        
        # Report references count
        $figRefs = [regex]::Matches($content, '\[.*?\]\(<#f-(\d+-\d+[a-z]?)\s*>\)')
        $listRefs = [regex]::Matches($content, '\[.*?\]\(<#l-(\d+-\d+[a-z]?)\s*>\)')
        $tableRefs = [regex]::Matches($content, '\[.*?\]\(<#t-(\d+-\d+[a-z]?)\s*>\)')
        
        Write-Info "References found: figures=$($figRefs.Count), listings=$($listRefs.Count), tables=$($tableRefs.Count)"
        
        # Check for orphan references
        $missingCount = 0
        foreach ($ref in $figRefs) {
            $refId = $ref.Groups[1].Value
            if ($content -notmatch "<a id=`"f-$refId`"") {
                Write-Host "    [!] Missing anchor: f-$refId" -ForegroundColor Red
                $missingCount++
            }
        }
        foreach ($ref in $listRefs) {
            $refId = $ref.Groups[1].Value
            if ($content -notmatch "<a id=`"l-$refId`"") {
                Write-Host "    [!] Missing anchor: l-$refId" -ForegroundColor Red
                $missingCount++
            }
        }
        foreach ($ref in $tableRefs) {
            $refId = $ref.Groups[1].Value
            if ($content -notmatch "<a id=`"t-$refId`"") {
                Write-Host "    [!] Missing anchor: t-$refId" -ForegroundColor Red
                $missingCount++
            }
        }
        
        if ($missingCount -eq 0) {
            Write-Success "All references have matching anchors"
        }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  SUMMARY" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Total anchors added:" -ForegroundColor White
Write-Host "    Figures:  +$totalFigAdded" -ForegroundColor Cyan
Write-Host "    Listings: +$totalListAdded" -ForegroundColor Cyan
Write-Host "    Tables:   +$totalTableAdded" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart docker:" -ForegroundColor White
Write-Host "     docker compose down" -ForegroundColor Gray
Write-Host "     docker compose up" -ForegroundColor Gray
Write-Host "  2. Test anchor links in browser" -ForegroundColor White
Write-Host "  3. Check for any remaining warnings" -ForegroundColor White
Write-Host ""
Write-Host "If all OK:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m `"Fix: add anchors for figures and listings`"" -ForegroundColor Gray
Write-Host "  git push origin main" -ForegroundColor Gray
Write-Host ""
