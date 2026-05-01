$files = Get-ChildItem -Path 'd:\habitz\lib' -Recurse -Filter '*.dart'
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false
    
    # Replace old primary color hex
    if ($content -match '0xFF6C63FF') {
        $content = $content -replace '0xFF6C63FF', '0xFF5C4AE4'
        $changed = $true
    }
    
    # Replace secondary purple variant
    if ($content -match '0xFF9B5DFF') {
        $content = $content -replace '0xFF9B5DFF', '0xFF7B6EF6'
        $changed = $true
    }
    
    # Replace old gradient purple
    if ($content -match '0xFF5A54D4') {
        $content = $content -replace '0xFF5A54D4', '0xFF5C4AE4'
        $changed = $true
    }
    
    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Output "Updated colors: $($file.FullName)"
    }
}
