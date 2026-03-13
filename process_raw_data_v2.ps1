# Process raw data files and update insights
$rawDataRoot = "C:\OpenClaw\.openclaw\workspace\raw-data"
$insightsRoot = "C:\Users\User\.openclaw\workspace\insights"
$processedJsonPath = "$insightsRoot\processed.json"

# Load processed.json
$processed = @{}
if (Test-Path $processedJsonPath) {
    $json = Get-Content $processedJsonPath -Raw
    if ($json) {
        $obj = $json | ConvertFrom-Json
        # Convert to hashtable
        if ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [System.Collections.Hashtable])) {
            # it's an array? unlikely
        } else {
            foreach ($prop in $obj.PSObject.Properties) {
                $processed[$prop.Name] = $prop.Value
            }
        }
    }
}

# Text file extensions
$textExtensions = @('.txt', '.md', '.json', '.csv', '.log', '.ps1', '.bat', '.cmd', '.sh', '.yml', '.yaml', '.xml', '.html', '.htm', '.css', '.js', '.ts', '.py', '.java', '.c', '.cpp', '.h', '.cs', '.php', '.sql', '.ini', '.cfg', '.conf', '.reg', '.inf', '.rtf', '.svg')

# Mapping from directory to insight file
$topicMap = @{
    "Fam" = "family-insights.md"
    "Food & Drink" = "food-insights.md"
    "Companies" = "business-insights.md"
    "Shipments" = "sales-insights.md"
    "Working day" = "employees-insights.md"
    "YB" = "yerba-mate-insights.md"
    "investments" = "investments-insights.md"
    "Meds" = "health-insights.md"
    "Quotes" = "quotes-insights.md"
    "Books" = "reading-insights.md"
    "building in ghana" = "real-estate-insights.md"
    "Farm" = "farming-insights.md"
    "akoma confidential" = "legal-insights.md"
    "Kayl Amo" = "legal-insights.md"
    "Flow" = "workflow-insights.md"
    "things to buy" = "shopping-list.md"
    "paapa_s notebook" = "personal-insights.md"
    # default fallback
    "_default" = "raw-data-insights.md"
}

# Gather all files recursively
$files = Get-ChildItem -Path $rawDataRoot -File -Recurse

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($rawDataRoot.Length + 1).Replace("\", "/")
    $shouldProcess = $false
    $lastWrite = $file.LastWriteTimeUtc.ToString("o")
    
    if ($processed.ContainsKey($relativePath)) {
        $prevTime = [DateTime]::Parse($processed[$relativePath])
        if ($lastWrite -gt $prevTime) {
            $shouldProcess = $true
        }
    } else {
        $shouldProcess = $true
    }
    
    # Skip binary files (images, audio, pdf, etc.)
    $ext = $file.Extension.ToLower()
    if ($textExtensions -notcontains $ext) {
        Write-Host "Skipping binary file $relativePath"
        # still mark as processed to avoid re-checking
        if ($shouldProcess) {
            $processed[$relativePath] = $lastWrite
        }
        continue
    }
    
    if (-not $shouldProcess) {
        Write-Host "Skipping $relativePath (already processed)"
        continue
    }
    
    Write-Host "Processing $relativePath"
    
    # Determine topic based on parent directory
    $parentDir = $file.Directory.Name
    $insightFile = $topicMap["_default"]
    if ($topicMap.ContainsKey($parentDir)) {
        $insightFile = $topicMap[$parentDir]
    }
    
    # Read file content
    $content = ""
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
    } catch {
        try {
            $content = Get-Content $file.FullName -Raw -Encoding Default -ErrorAction Stop
        } catch {
            $content = "[File read error: $($_.Exception.Message)]"
        }
    }
    
    # Determine format based on insight file
    $insightPath = Join-Path $insightsRoot $insightFile
    $entry = ""
    
    if ($insightFile -eq "shopping-list.md") {
        # Format: ## From <path> and Added: timestamp
        $entry = "## From $relativePath`nAdded: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n<div style=`"display: none;`">&#x200A;</div>`n$content`n---`n"
    } else {
        # Format with frontmatter
        $title = $file.Name
        $created = $file.CreationTimeUtc.ToString("yyyy-MM-dd HH:mm:ssZ")
        $updated = $lastWrite
        $entry = "### Source: $relativePath`nProcessed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n---`ntitle: $title`nupdated: $updated`ncreated: $created`ncompleted?: no`n---`n`n$content`n---`n"
    }
    
    # Append to insight file
    Add-Content -Path $insightPath -Value $entry -Encoding UTF8
    
    # Update processed.json
    $processed[$relativePath] = $lastWrite
}

# Save processed.json
$processed | ConvertTo-Json | Set-Content -Path $processedJsonPath -Encoding UTF8

Write-Host "Processing complete."