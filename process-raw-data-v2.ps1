# Process raw data files and generate insights - version 2
$rawDataPath = "C:\OpenClaw\.openclaw\workspace\raw-data"
$insightsPath = "C:\Users\User\.openclaw\workspace\insights"
$processedFile = "$insightsPath\processed.json"

# Load processed state
if (Test-Path $processedFile) {
    $processed = Get-Content $processedFile | ConvertFrom-Json
} else {
    $processed = @{}
}

# Ensure insights directory exists
New-Item -ItemType Directory -Force -Path $insightsPath | Out-Null

# Define topic mapping based on folder names
$topicMap = @{
    "things to buy" = "shopping"
    "Meds" = "health"
    "Companies" = "business"
    "Shipments" = "sales"
    "investments" = "investments"
    "Farm" = "farming"
    "building in ghana" = "real-estate"
    "Fam" = "family"
    "Flow" = "workflow"
    "Books" = "reading"
    "Quotes" = "quotes"
    "YB" = "yerba-mate"
    "Food & Drink" = "food"
    "akoma confidential" = "business"
    "paapa_s notebook" = "personal"
    "Working day" = "employees"
    "Kayl Amo" = "legal"
    "_resources" = "resources"
}

# Get all .md and .txt files recursively
$files = Get-ChildItem -Path $rawDataPath -Include *.md, *.txt -Recurse -File

$newFiles = 0
$updatedFiles = 0

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($rawDataPath.Length)
    if ($relativePath.StartsWith("\")) { $relativePath = $relativePath.Substring(1) }
    $lastWrite = $file.LastWriteTimeUtc.ToString('o')
    
    # Check if file already processed and unchanged
    if ($processed.ContainsKey($relativePath) -and $processed[$relativePath] -eq $lastWrite) {
        Write-Host "Skipping unchanged: $relativePath"
        continue
    }
    
    Write-Host "Processing: $relativePath"
    $updatedFiles++
    
    # Determine topic
    $topic = $null
    # Check parent folder names
    $folder = $file.DirectoryName
    if ($folder -eq $rawDataPath) {
        $folderRelative = ""
    } else {
        $folderRelative = $folder.Substring($rawDataPath.Length + 1)
    }
    foreach ($key in $topicMap.Keys) {
        if ($folderRelative -like "*$key*") {
            $topic = $topicMap[$key]
            break
        }
    }
    # If no mapping, use parent folder name as topic
    if (-not $topic) {
        $topic = $file.Directory.Name
        if (-not $topic) { $topic = "other" }
    }
    
    # Read file content
    $content = Get-Content $file.FullName -Raw
    
    # Extract key data (first 500 characters)
    $keyData = $content.Substring(0, [Math]::Min($content.Length, 500))
    
    # Append to insight file
    $insightFile = "$insightsPath\$topic-insights.md"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $divider = "---"
    $entry = @"
### Source: $relativePath
Processed: $timestamp
$keyData
$divider

"@
    Add-Content -Path $insightFile -Value $entry
    
    # Special handling for shopping lists
    if ($topic -eq "shopping") {
        $shoppingListFile = "$insightsPath\shopping-list.md"
        # Extract items: each non-empty line after stripping frontmatter
        $lines = $content -split "`n"
        $inFrontMatter = $false
        $items = @()
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -eq '---') {
                $inFrontMatter = -not $inFrontMatter
                continue
            }
            if ($inFrontMatter) { continue }
            if ($trimmed -eq '') { continue }
            # Skip lines that are all caps (likely headers)
            if ($trimmed -cmatch '^[A-Z\s]+$') { continue }
            # Skip lines that are too short (maybe metadata)
            if ($trimmed.Length -lt 2) { continue }
            $items += $trimmed
        }
        if ($items.Count -gt 0) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $sourceNote = "From $relativePath"
            $entry = @"
## $sourceNote
Added: $timestamp
$($items -join "`n")
---
"@
            Add-Content -Path $shoppingListFile -Value $entry
        }
    }
    
    # Update processed state
    $processed[$relativePath] = $lastWrite
}

# Save processed state
$processed | ConvertTo-Json | Set-Content $processedFile
Write-Host "Processing complete. Updated $updatedFiles files."