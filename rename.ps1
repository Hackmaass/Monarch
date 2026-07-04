$ErrorActionPreference = "Stop"

# Define the replacements (Order matters: uppercase, exact case, lowercase)
$replacements = @(
    @{ Old = "CREDIFY"; New = "MONARCH" },
    @{ Old = "Credify"; New = "Monarch" },
    @{ Old = "credify"; New = "monarch" }
)

# 1. Text Replacement
Write-Host "Replacing text content..."
$files = Get-ChildItem -Recurse -File | Where-Object { 
    $_.FullName -notmatch "\\\.git\\" -and 
    $_.FullName -notmatch "\\node_modules\\" -and 
    $_.FullName -notmatch "\\build\\" -and 
    $_.FullName -notmatch "\\\.next\\" -and
    $_.FullName -notmatch "\\.svg$" -and
    $_.FullName -notmatch "\\.png$" -and
    $_.FullName -notmatch "\\.ico$" -and
    $_.Name -ne "rename.ps1"
}

foreach ($file in $files) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        $modified = $false
        
        foreach ($repl in $replacements) {
            if ($content.Contains($repl.Old)) {
                $content = $content.Replace($repl.Old, $repl.New)
                $modified = $true
            }
        }
        
        if ($modified) {
            [System.IO.File]::WriteAllText($file.FullName, $content)
            Write-Host "Updated content in: $($file.FullName)"
        }
    } catch {
        Write-Host "Failed to process: $($file.FullName) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 2. Rename Files
Write-Host "Renaming files..."
$filesToRename = Get-ChildItem -Recurse -File | Where-Object { 
    $_.FullName -notmatch "\\\.git\\" -and 
    $_.FullName -notmatch "\\node_modules\\" -and 
    $_.FullName -notmatch "\\build\\" -and 
    $_.FullName -notmatch "\\\.next\\" -and
    $_.Name -match "credify"
}

foreach ($file in $filesToRename) {
    $newName = $file.Name -ireplace "credify", "monarch"
    $newName = $newName -creplace "Credify", "Monarch"
    $newName = $newName -creplace "CREDIFY", "MONARCH"
    Rename-Item -Path $file.FullName -NewName $newName
    Write-Host "Renamed file: $($file.Name) -> $newName"
}

# 3. Rename Directories (Bottom-up to avoid path issues)
Write-Host "Renaming directories..."
$dirsToRename = Get-ChildItem -Recurse -Directory | Where-Object { 
    $_.FullName -notmatch "\\\.git\\" -and 
    $_.FullName -notmatch "\\node_modules\\" -and 
    $_.FullName -notmatch "\\build\\" -and 
    $_.FullName -notmatch "\\\.next\\" -and
    $_.Name -match "credify"
} | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true}

foreach ($dir in $dirsToRename) {
    $newName = $dir.Name -ireplace "credify", "monarch"
    $newName = $newName -creplace "Credify", "Monarch"
    $newName = $newName -creplace "CREDIFY", "MONARCH"
    Rename-Item -Path $dir.FullName -NewName $newName
    Write-Host "Renamed directory: $($dir.Name) -> $newName"
}

Write-Host "Done."
