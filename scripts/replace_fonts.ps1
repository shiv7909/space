$files = Get-ChildItem -Path 'd:\habitz\lib' -Recurse -Filter '*.dart'
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'GoogleFonts\.nunito') {
        $newContent = $content -replace 'GoogleFonts\.nunitoTextTheme', 'GoogleFonts.plusJakartaSansTextTheme'
        $newContent = $newContent -replace 'GoogleFonts\.nunito', 'GoogleFonts.plusJakartaSans'
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Output "Updated: $($file.FullName)"
    }
}
