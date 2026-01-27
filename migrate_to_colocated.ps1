<#
.SYNOPSIS
    Migration script to Co-located Assets architecture
    
.DESCRIPTION
    Reorganizes project structure:
    - Creates new directories with semantic names
    - Moves images to chapter folders
    - Merges chapter files
    - Fixes image paths in Markdown
    - Removes duplicates
    - Updates mkdocs.yml
    
.EXAMPLE
    .\migrate_to_colocated.ps1 -WhatIf
    
.EXAMPLE
    .\migrate_to_colocated.ps1
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ProjectRoot = "Z:\Source\Books\prodotnetmemory.github.io",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# =============================================================================
# CONFIGURATION
# =============================================================================

$ChapterMapping = @{
    "chapter-01" = @{
        NewName = "01-basic-concepts"
        ImgPrefix = "1-"
    }
    "chapter-02" = @{
        NewName = "02-low-level-memory"
        ImgPrefix = "2-"
    }
    "chapter-03" = @{
        NewName = "03-memory-measurements"
        ImgPrefix = "3-"
    }
    "chapter-04" = @{
        NewName = "04-net-fundamentals"
        ImgPrefix = "4-"
    }
}

$DuplicateFiles = @(
    "docs\home.md",
    "docs\about\about-the-authors.md",
    "docs\about\about-the-technical-reviewer.md"
)

$CommonImages = @(
    "book-cover.png",
    "inside-cover-of-the-book.png",
    "brown-aleks-boosty.png",
    "brown-aleks-donationalerts.png",
    "qr-brown-aleks.png"
)

# Folders to exclude from backup (from .gitignore)
$ExcludeFolders = @(
    ".vs",
    ".vscode",
    ".idea",
    ".claude",
    ".git",
    "node_modules",
    "site",
    ".cache",
    "venv",
    "env",
    "__pycache__",
    "bin",
    "obj",
    "Debug",
    "Release",
    ".localhistory",
    ".vshistory"
)

# =============================================================================
# FUNCTIONS
# =============================================================================

function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor $Color
    Write-Host $Message -ForegroundColor $Color
    Write-Host ("=" * 70) -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}

function Backup-Project {
    param([string]$ProjectRoot)
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path (Split-Path $ProjectRoot -Parent) "prodotnetmemory_backup_$timestamp"
    
    Write-Host "  -> Creating backup in: $backupDir" -ForegroundColor Yellow
    Write-Host "  -> Excluding: $($ExcludeFolders -join ', ')" -ForegroundColor Gray
    
    if ($PSCmdlet.ShouldProcess($ProjectRoot, "Create backup (excluding IDE folders)")) {
        # Create backup directory
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Get all items except excluded folders
        $items = Get-ChildItem -Path $ProjectRoot -Force | Where-Object {
            $_.Name -notin $ExcludeFolders
        }
        
        foreach ($item in $items) {
            $destPath = Join-Path $backupDir $item.Name
            Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
        }
        
        Write-Success "Backup created (IDE folders excluded)"
    }
    
    return $backupDir
}

function Remove-Duplicates {
    param([string]$ProjectRoot)
    
    foreach ($file in $DuplicateFiles) {
        $fullPath = Join-Path $ProjectRoot $file
        if (Test-Path $fullPath) {
            if ($PSCmdlet.ShouldProcess($fullPath, "Delete duplicate")) {
                Remove-Item $fullPath -Force
                Write-Success "Deleted: $file"
            }
        } else {
            Write-Warn "Not found: $file"
        }
    }
}

function New-ChapterStructure {
    param([string]$ProjectRoot)
    
    $chaptersDir = Join-Path $ProjectRoot "docs\chapters"
    
    foreach ($oldName in $ChapterMapping.Keys) {
        $config = $ChapterMapping[$oldName]
        $newDir = Join-Path $chaptersDir $config.NewName
        $imgDir = Join-Path $newDir "img"
        
        if (-not (Test-Path $newDir)) {
            if ($PSCmdlet.ShouldProcess($newDir, "Create directory")) {
                New-Item -ItemType Directory -Path $newDir -Force | Out-Null
                Write-Success "Created: $($config.NewName)/"
            }
        }
        
        if (-not (Test-Path $imgDir)) {
            if ($PSCmdlet.ShouldProcess($imgDir, "Create img directory")) {
                New-Item -ItemType Directory -Path $imgDir -Force | Out-Null
                Write-Success "Created: $($config.NewName)/img/"
            }
        }
    }
}

function Move-ChapterImages {
    param([string]$ProjectRoot)
    
    $sourceImgDir = Join-Path $ProjectRoot "docs\assets\images"
    $chaptersDir = Join-Path $ProjectRoot "docs\chapters"
    
    foreach ($oldName in $ChapterMapping.Keys) {
        $config = $ChapterMapping[$oldName]
        $targetImgDir = Join-Path $chaptersDir "$($config.NewName)\img"
        $prefix = $config.ImgPrefix
        
        $images = Get-ChildItem -Path $sourceImgDir -Filter "$prefix*.png" -ErrorAction SilentlyContinue
        
        $count = 0
        foreach ($img in $images) {
            if ($img.Name -in $CommonImages) { continue }
            
            $targetPath = Join-Path $targetImgDir $img.Name
            
            if ($PSCmdlet.ShouldProcess($img.FullName, "Move to $targetImgDir")) {
                Move-Item -Path $img.FullName -Destination $targetPath -Force
                $count++
            }
        }
        
        if ($count -gt 0) {
            Write-Success "Moved $count images to $($config.NewName)/img/"
        }
    }
}

function Merge-ChapterFiles {
    param([string]$ProjectRoot)
    
    $chaptersDir = Join-Path $ProjectRoot "docs\chapters"
    
    foreach ($oldName in $ChapterMapping.Keys) {
        $config = $ChapterMapping[$oldName]
        
        $oldDir = Join-Path $chaptersDir $oldName
        $newDir = Join-Path $chaptersDir $config.NewName
        
        $chapterNum = [int]($oldName -replace "chapter-0?", "")
        
        $chapterFile = Join-Path $oldDir "chapter$chapterNum.md"
        $targetFile = Join-Path $newDir "index.md"
        
        if (Test-Path $chapterFile) {
            if ($PSCmdlet.ShouldProcess($chapterFile, "Move and rename to index.md")) {
                $content = Get-Content -Path $chapterFile -Raw -Encoding UTF8
                
                # Fix image paths
                $content = $content -replace '\.\./\.\./assets/images/', 'img/'
                $content = $content -replace 'content/img/', 'img/'
                
                Set-Content -Path $targetFile -Value $content -Encoding UTF8 -NoNewline
                
                Write-Success "Created: $($config.NewName)/index.md (paths fixed)"
            }
        } else {
            Write-Warn "Not found: $chapterFile"
            
            $oldIndex = Join-Path $oldDir "index.md"
            if (Test-Path $oldIndex) {
                if ($PSCmdlet.ShouldProcess($oldIndex, "Copy index.md")) {
                    Copy-Item -Path $oldIndex -Destination $targetFile -Force
                    Write-Success "Copied: $($config.NewName)/index.md (stub)"
                }
            }
        }
    }
}

function Remove-OldChapterDirs {
    param([string]$ProjectRoot)
    
    $chaptersDir = Join-Path $ProjectRoot "docs\chapters"
    
    foreach ($oldName in $ChapterMapping.Keys) {
        $oldDir = Join-Path $chaptersDir $oldName
        
        if (Test-Path $oldDir) {
            if ($PSCmdlet.ShouldProcess($oldDir, "Delete old directory")) {
                Remove-Item -Path $oldDir -Recurse -Force
                Write-Success "Deleted: $oldName/"
            }
        }
    }
}

function Update-ChaptersIndex {
    param([string]$ProjectRoot)
    
    $indexPath = Join-Path $ProjectRoot "docs\chapters\index.md"
    
    $lines = @()
    $lines += "# " + [char]0x041E + [char]0x0433 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x043B + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x0435
    $lines += ""
    $lines += "## " + [char]0x0427 + [char]0x0430 + [char]0x0441 + [char]0x0442 + [char]0x044C + " I: " + [char]0x041E + [char]0x0441 + [char]0x043D + [char]0x043E + [char]0x0432 + [char]0x044B
    $lines += ""
    $lines += "- [" + [char]0x0413 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x0430 + " 1. " + [char]0x0411 + [char]0x0430 + [char]0x0437 + [char]0x043E + [char]0x0432 + [char]0x044B + [char]0x0435 + " " + [char]0x043A + [char]0x043E + [char]0x043D + [char]0x0446 + [char]0x0435 + [char]0x043F + [char]0x0446 + [char]0x0438 + [char]0x0438 + "](01-basic-concepts/index.md)"
    $lines += "- [" + [char]0x0413 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x0430 + " 2. " + [char]0x041D + [char]0x0438 + [char]0x0437 + [char]0x043A + [char]0x043E + [char]0x0443 + [char]0x0440 + [char]0x043E + [char]0x0432 + [char]0x043D + [char]0x0435 + [char]0x0432 + [char]0x0430 + [char]0x044F + " " + [char]0x043F + [char]0x0430 + [char]0x043C + [char]0x044F + [char]0x0442 + [char]0x044C + "](02-low-level-memory/index.md)"
    $lines += "- [" + [char]0x0413 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x0430 + " 3. " + [char]0x0418 + [char]0x0437 + [char]0x043C + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x044F + " " + [char]0x043F + [char]0x0430 + [char]0x043C + [char]0x044F + [char]0x0442 + [char]0x0438 + "](03-memory-measurements/index.md)"
    $lines += "- [" + [char]0x0413 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x0430 + " 4. " + [char]0x041E + [char]0x0441 + [char]0x043D + [char]0x043E + [char]0x0432 + [char]0x044B + " .NET](04-net-fundamentals/index.md)"
    $lines += ""
    $lines += "## " + [char]0x0427 + [char]0x0430 + [char]0x0441 + [char]0x0442 + [char]0x044C + " II: " + [char]0x041F + [char]0x0440 + [char]0x043E + [char]0x0434 + [char]0x0432 + [char]0x0438 + [char]0x043D + [char]0x0443 + [char]0x0442 + [char]0x044B + [char]0x0435 + " " + [char]0x0442 + [char]0x0435 + [char]0x043C + [char]0x044B
    $lines += ""
    $lines += "*" + [char]0x0412 + " " + [char]0x043F + [char]0x0440 + [char]0x043E + [char]0x0446 + [char]0x0435 + [char]0x0441 + [char]0x0441 + [char]0x0435 + " " + [char]0x043F + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x0432 + [char]0x043E + [char]0x0434 + [char]0x0430 + "...*"
    
    $newContent = $lines -join "`n"
    
    if ($PSCmdlet.ShouldProcess($indexPath, "Update chapters index")) {
        Set-Content -Path $indexPath -Value $newContent -Encoding UTF8
        Write-Success "Updated: chapters/index.md"
    }
}

function Update-MainIndex {
    param([string]$ProjectRoot)
    
    $indexPath = Join-Path $ProjectRoot "docs\index.md"
    
    if (Test-Path $indexPath) {
        $content = Get-Content -Path $indexPath -Raw -Encoding UTF8
        
        $content = $content -replace 'chapters/chapter-01/', 'chapters/01-basic-concepts/'
        $content = $content -replace 'about/authors/', 'about/authors.md'
        
        if ($PSCmdlet.ShouldProcess($indexPath, "Update links")) {
            Set-Content -Path $indexPath -Value $content -Encoding UTF8 -NoNewline
            Write-Success "Updated: index.md"
        }
    }
}

function New-MkDocsConfig {
    param([string]$ProjectRoot)
    
    $configPath = Join-Path $ProjectRoot "mkdocs.yml"
    
    $cfg = @()
    $cfg += "# ============================================================================="
    $cfg += "# BASIC INFO"
    $cfg += "# ============================================================================="
    $cfg += "site_name: Pro .NET " + [char]0x0423 + [char]0x043F + [char]0x0440 + [char]0x0430 + [char]0x0432 + [char]0x043B + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x0435 + " " + [char]0x041F + [char]0x0430 + [char]0x043C + [char]0x044F + [char]0x0442 + [char]0x044C + [char]0x044E
    $cfg += "site_description: " + [char]0x0410 + [char]0x0432 + [char]0x0442 + [char]0x043E + [char]0x0440 + [char]0x0441 + [char]0x043A + [char]0x0438 + [char]0x0439 + " " + [char]0x043F + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x0432 + [char]0x043E + [char]0x0434 + " " + [char]0x043A + [char]0x043D + [char]0x0438 + [char]0x0433 + [char]0x0438 + " Pro .NET Memory Management " + [char]0x043D + [char]0x0430 + " " + [char]0x0440 + [char]0x0443 + [char]0x0441 + [char]0x0441 + [char]0x043A + [char]0x0438 + [char]0x0439 + " " + [char]0x044F + [char]0x0437 + [char]0x044B + [char]0x043A
    $cfg += "site_author: " + [char]0x0410 + [char]0x043B + [char]0x0435 + [char]0x043A + [char]0x0441 + [char]0x0430 + [char]0x043D + [char]0x0434 + [char]0x0440 + " " + [char]0x0411 + [char]0x0440 + [char]0x043E + [char]0x0443 + [char]0x043D
    $cfg += "site_url: https://brown-aleks.github.io/prodotnetmemory.github.io/"
    $cfg += "repo_url: https://github.com/brown-aleks/prodotnetmemory.github.io"
    $cfg += "repo_name: brown-aleks/prodotnetmemory"
    $cfg += "edit_uri: edit/main/docs/"
    $cfg += "copyright: |"
    $cfg += "  Copyright &copy; 2024 Konrad Kokosa, Christophe Nasarre, Kevin Gosse<br>"
    $cfg += "  " + [char]0x041F + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x0432 + [char]0x043E + [char]0x0434 + " &copy; 2025 <a href=" + [char]0x0022 + "https://t.me/brown_aleks" + [char]0x0022 + " target=" + [char]0x0022 + "_blank" + [char]0x0022 + ">" + [char]0x0410 + [char]0x043B + [char]0x0435 + [char]0x043A + [char]0x0441 + [char]0x0430 + [char]0x043D + [char]0x0434 + [char]0x0440 + " " + [char]0x0411 + [char]0x0440 + [char]0x043E + [char]0x0443 + [char]0x043D + "</a>"
    $cfg += ""
    $cfg += "# ============================================================================="
    $cfg += "# THEME"
    $cfg += "# ============================================================================="
    $cfg += "theme:"
    $cfg += "  name: material"
    $cfg += "  language: ru"
    $cfg += "  "
    $cfg += "  palette:"
    $cfg += "    - media: " + [char]0x0022 + "(prefers-color-scheme: light)" + [char]0x0022
    $cfg += "      scheme: default"
    $cfg += "      primary: indigo"
    $cfg += "      accent: indigo"
    $cfg += "      toggle:"
    $cfg += "        icon: material/brightness-7"
    $cfg += "        name: " + [char]0x041F + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x043A + [char]0x043B + [char]0x044E + [char]0x0447 + [char]0x0438 + [char]0x0442 + [char]0x044C + " " + [char]0x043D + [char]0x0430 + " " + [char]0x0442 + [char]0x0451 + [char]0x043C + [char]0x043D + [char]0x0443 + [char]0x044E + " " + [char]0x0442 + [char]0x0435 + [char]0x043C + [char]0x0443
    $cfg += "    - media: " + [char]0x0022 + "(prefers-color-scheme: dark)" + [char]0x0022
    $cfg += "      scheme: slate"
    $cfg += "      primary: indigo"
    $cfg += "      accent: indigo"
    $cfg += "      toggle:"
    $cfg += "        icon: material/brightness-4"
    $cfg += "        name: " + [char]0x041F + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x043A + [char]0x043B + [char]0x044E + [char]0x0447 + [char]0x0438 + [char]0x0442 + [char]0x044C + " " + [char]0x043D + [char]0x0430 + " " + [char]0x0441 + [char]0x0432 + [char]0x0435 + [char]0x0442 + [char]0x043B + [char]0x0443 + [char]0x044E + " " + [char]0x0442 + [char]0x0435 + [char]0x043C + [char]0x0443
    $cfg += "  "
    $cfg += "  font:"
    $cfg += "    text: Roboto"
    $cfg += "    code: Roboto Mono"
    $cfg += "  "
    $cfg += "  features:"
    $cfg += "    - announce.dismiss"
    $cfg += "    - content.action.edit"
    $cfg += "    - content.action.view"
    $cfg += "    - content.code.annotate"
    $cfg += "    - content.code.copy"
    $cfg += "    - content.code.select"
    $cfg += "    - content.tabs.link"
    $cfg += "    - content.tooltips"
    $cfg += "    - header.autohide"
    $cfg += "    - navigation.expand"
    $cfg += "    - navigation.footer"
    $cfg += "    - navigation.indexes"
    $cfg += "    - navigation.instant"
    $cfg += "    - navigation.instant.prefetch"
    $cfg += "    - navigation.instant.progress"
    $cfg += "    - navigation.path"
    $cfg += "    - navigation.sections"
    $cfg += "    - navigation.tabs"
    $cfg += "    - navigation.tabs.sticky"
    $cfg += "    - navigation.top"
    $cfg += "    - navigation.tracking"
    $cfg += "    - search.highlight"
    $cfg += "    - search.share"
    $cfg += "    - search.suggest"
    $cfg += "    - toc.follow"
    $cfg += ""
    $cfg += "# ============================================================================="
    $cfg += "# PLUGINS"
    $cfg += "# ============================================================================="
    $cfg += "plugins:"
    $cfg += "  - search:"
    $cfg += "      lang: ru"
    $cfg += ""
    $cfg += "# ============================================================================="
    $cfg += "# MARKDOWN EXTENSIONS"
    $cfg += "# ============================================================================="
    $cfg += "markdown_extensions:"
    $cfg += "  - abbr"
    $cfg += "  - admonition"
    $cfg += "  - attr_list"
    $cfg += "  - def_list"
    $cfg += "  - footnotes"
    $cfg += "  - md_in_html"
    $cfg += "  - meta"
    $cfg += "  - tables"
    $cfg += "  - toc:"
    $cfg += "      permalink: true"
    $cfg += "      permalink_title: " + [char]0x0421 + [char]0x0441 + [char]0x044B + [char]0x043B + [char]0x043A + [char]0x0430 + " " + [char]0x043D + [char]0x0430 + " " + [char]0x044D + [char]0x0442 + [char]0x043E + [char]0x0442 + " " + [char]0x0440 + [char]0x0430 + [char]0x0437 + [char]0x0434 + [char]0x0435 + [char]0x043B
    $cfg += "      toc_depth: 3"
    $cfg += "  - pymdownx.arithmatex:"
    $cfg += "      generic: true"
    $cfg += "  - pymdownx.betterem:"
    $cfg += "      smart_enable: all"
    $cfg += "  - pymdownx.caret"
    $cfg += "  - pymdownx.critic"
    $cfg += "  - pymdownx.details"
    $cfg += "  - pymdownx.emoji:"
    $cfg += "      emoji_index: !!python/name:material.extensions.emoji.twemoji"
    $cfg += "      emoji_generator: !!python/name:material.extensions.emoji.to_svg"
    $cfg += "  - pymdownx.highlight:"
    $cfg += "      anchor_linenums: true"
    $cfg += "      line_spans: __span"
    $cfg += "      pygments_lang_class: true"
    $cfg += "      use_pygments: true"
    $cfg += "      auto_title: true"
    $cfg += "      linenums: true"
    $cfg += "  - pymdownx.inlinehilite"
    $cfg += "  - pymdownx.keys"
    $cfg += "  - pymdownx.mark"
    $cfg += "  - pymdownx.smartsymbols"
    $cfg += "  - pymdownx.superfences:"
    $cfg += "      custom_fences:"
    $cfg += "        - name: mermaid"
    $cfg += "          class: mermaid"
    $cfg += "          format: !!python/name:pymdownx.superfences.fence_code_format"
    $cfg += "  - pymdownx.tabbed:"
    $cfg += "      alternate_style: true"
    $cfg += "      combine_header_slug: true"
    $cfg += "  - pymdownx.tasklist:"
    $cfg += "      custom_checkbox: true"
    $cfg += "  - pymdownx.tilde"
    $cfg += ""
    $cfg += "# ============================================================================="
    $cfg += "# EXTRA"
    $cfg += "# ============================================================================="
    $cfg += "extra:"
    $cfg += "  social:"
    $cfg += "    - icon: fontawesome/brands/github"
    $cfg += "      link: https://github.com/brown-aleks"
    $cfg += "      name: GitHub"
    $cfg += "    - icon: fontawesome/brands/telegram"
    $cfg += "      link: https://t.me/brown_aleks"
    $cfg += "      name: Telegram"
    $cfg += ""
    $cfg += "extra_css:"
    $cfg += "  - assets/stylesheets/custom.css"
    $cfg += ""
    $cfg += "# ============================================================================="
    $cfg += "# NAVIGATION"
    $cfg += "# ============================================================================="
    $cfg += "nav:"
    $cfg += "  - " + [char]0x0413 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x043D + [char]0x0430 + [char]0x044F + ": index.md"
    $cfg += "  "
    $cfg += "  - " + [char]0x041E + " " + [char]0x043A + [char]0x043D + [char]0x0438 + [char]0x0433 + [char]0x0435 + ":"
    $cfg += "    - about/index.md"
    $cfg += "    - " + [char]0x041E + [char]0x0431 + " " + [char]0x0430 + [char]0x0432 + [char]0x0442 + [char]0x043E + [char]0x0440 + [char]0x0430 + [char]0x0445 + ": about/authors.md"
    $cfg += "    - " + [char]0x041E + " " + [char]0x0440 + [char]0x0435 + [char]0x0446 + [char]0x0435 + [char]0x043D + [char]0x0437 + [char]0x0435 + [char]0x043D + [char]0x0442 + [char]0x0435 + ": about/technical-reviewer.md"
    $cfg += "    - " + [char]0x0411 + [char]0x043B + [char]0x0430 + [char]0x0433 + [char]0x043E + [char]0x0434 + [char]0x0430 + [char]0x0440 + [char]0x043D + [char]0x043E + [char]0x0441 + [char]0x0442 + [char]0x0438 + ": about/acknowledgments.md"
    $cfg += "    - " + [char]0x041F + [char]0x0440 + [char]0x0435 + [char]0x0434 + [char]0x0438 + [char]0x0441 + [char]0x043B + [char]0x043E + [char]0x0432 + [char]0x0438 + [char]0x0435 + ": about/foreword.md"
    $cfg += "    - " + [char]0x0412 + [char]0x0432 + [char]0x0435 + [char]0x0434 + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x0435 + ": about/introduction.md"
    $cfg += "  "
    $cfg += "  - " + [char]0x0413 + [char]0x043B + [char]0x0430 + [char]0x0432 + [char]0x044B + ":"
    $cfg += "    - chapters/index.md"
    $cfg += "    - 1. " + [char]0x0411 + [char]0x0430 + [char]0x0437 + [char]0x043E + [char]0x0432 + [char]0x044B + [char]0x0435 + " " + [char]0x043A + [char]0x043E + [char]0x043D + [char]0x0446 + [char]0x0435 + [char]0x043F + [char]0x0446 + [char]0x0438 + [char]0x0438 + ": chapters/01-basic-concepts/index.md"
    $cfg += "    - 2. " + [char]0x041D + [char]0x0438 + [char]0x0437 + [char]0x043A + [char]0x043E + [char]0x0443 + [char]0x0440 + [char]0x043E + [char]0x0432 + [char]0x043D + [char]0x0435 + [char]0x0432 + [char]0x0430 + [char]0x044F + " " + [char]0x043F + [char]0x0430 + [char]0x043C + [char]0x044F + [char]0x0442 + [char]0x044C + ": chapters/02-low-level-memory/index.md"
    $cfg += "    - 3. " + [char]0x0418 + [char]0x0437 + [char]0x043C + [char]0x0435 + [char]0x0440 + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x044F + " " + [char]0x043F + [char]0x0430 + [char]0x043C + [char]0x044F + [char]0x0442 + [char]0x0438 + ": chapters/03-memory-measurements/index.md"
    $cfg += "    - 4. " + [char]0x041E + [char]0x0441 + [char]0x043D + [char]0x043E + [char]0x0432 + [char]0x044B + " .NET: chapters/04-net-fundamentals/index.md"
    $cfg += "  "
    $cfg += "  - " + [char]0x041F + [char]0x0440 + [char]0x0438 + [char]0x043B + [char]0x043E + [char]0x0436 + [char]0x0435 + [char]0x043D + [char]0x0438 + [char]0x044F + ":"
    $cfg += "    - " + [char]0x0413 + [char]0x043B + [char]0x043E + [char]0x0441 + [char]0x0441 + [char]0x0430 + [char]0x0440 + [char]0x0438 + [char]0x0439 + ": appendix/glossary.md"
    $cfg += "    - " + [char]0x0420 + [char]0x0435 + [char]0x0441 + [char]0x0443 + [char]0x0440 + [char]0x0441 + [char]0x044B + ": appendix/resources.md"
    $cfg += "    - FAQ: appendix/faq.md"
    
    $newConfig = $cfg -join "`n"
    
    if ($PSCmdlet.ShouldProcess($configPath, "Update mkdocs.yml")) {
        Set-Content -Path $configPath -Value $newConfig -Encoding UTF8
        Write-Success "Updated: mkdocs.yml"
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Green
    Write-Host "MIGRATION COMPLETE!" -ForegroundColor Green
    Write-Host ("=" * 70) -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Test locally: docker compose up" -ForegroundColor White
    Write-Host "  2. Open: http://localhost:8000" -ForegroundColor White
    Write-Host "  3. Check all pages and images" -ForegroundColor White
    Write-Host "  4. If OK, commit:" -ForegroundColor White
    Write-Host "     git add ." -ForegroundColor Gray
    Write-Host "     git commit -m " + [char]0x0022 + "Refactor: migrate to Co-located Assets" + [char]0x0022 -ForegroundColor Gray
    Write-Host "     git push origin main" -ForegroundColor Gray
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Magenta
Write-Host "     MIGRATION TO CO-LOCATED ASSETS ARCHITECTURE" -ForegroundColor Magenta
Write-Host "======================================================================" -ForegroundColor Magenta

if (-not (Test-Path $ProjectRoot)) {
    Write-Host "  [X] Project directory not found: $ProjectRoot" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Project: $ProjectRoot" -ForegroundColor White

if (-not $Force -and -not $WhatIfPreference) {
    Write-Host ""
    Write-Host "WARNING: This script will make significant changes!" -ForegroundColor Yellow
    Write-Host "   Run with -WhatIf first to preview changes." -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "Cancelled." -ForegroundColor Red
        exit 0
    }
}

Write-Step "STEP 1: Creating backup"
Backup-Project -ProjectRoot $ProjectRoot

Write-Step "STEP 2: Removing duplicates"
Remove-Duplicates -ProjectRoot $ProjectRoot

Write-Step "STEP 3: Creating new directory structure"
New-ChapterStructure -ProjectRoot $ProjectRoot

Write-Step "STEP 4: Moving images to chapters"
Move-ChapterImages -ProjectRoot $ProjectRoot

Write-Step "STEP 5: Merging chapter files"
Merge-ChapterFiles -ProjectRoot $ProjectRoot

Write-Step "STEP 6: Removing old directories"
Remove-OldChapterDirs -ProjectRoot $ProjectRoot

Write-Step "STEP 7: Updating chapters index"
Update-ChaptersIndex -ProjectRoot $ProjectRoot

Write-Step "STEP 8: Updating main page"
Update-MainIndex -ProjectRoot $ProjectRoot

Write-Step "STEP 9: Updating mkdocs.yml"
New-MkDocsConfig -ProjectRoot $ProjectRoot

Show-Summary
