# Process raw data files and generate insights
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

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($rawDataPath.Length + 1)
    $lastWrite = $file.LastWriteTimeUtc.ToString('o')
    
    # Check if file already processed and unchanged
    if ($processed.ContainsKey($relativePath) -and $processed[$relativePath] -eq $lastWrite) {
        Write-Host "Skipping unchanged: $relativePath"
        continue
    }
    
    Write-Host "Processing: $relativePath"
    
    # Determine topic
    $topic = $null
    # Check parent folder names
    $folder = $file.DirectoryName.Substring($rawDataPath.Length + 1)
    foreach ($key in $topicMap.Keys) {
        if ($folder -like "*$key*") {
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
    
    # Extract key data (simplify: first few lines or whole content)
    $lines = $content -split "`n"
    $keyData = $lines[0..([Math]::Min($lines.Count, 10))] -join "`n"
    
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
    
    # Update processed state
    $processed[$relativePath] = $lastWrite
}

# Save processed state
$processed | ConvertTo-Json | Set-Content $processedFile
Write-Host "Processing complete."