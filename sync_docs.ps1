# Script de Synchronisation MacroscopiX Docs
# Ce script convertit les fichiers .docx en .md (Markdown) pour GitHub
# Et vice-versa si vous modifiez le Markdown.

$action = Read-Host "Quelle action voulez-vous faire ? (1: Docx -> MD, 2: MD -> Docx)"

if ($action -eq "1") {
    Write-Host "Conversion de DOCX vers Markdown..." -ForegroundColor Cyan
    Get-ChildItem . -Filter *.docx | ForEach-Object {
        Write-Host "Traitement de $($_.Name)..."
        pandoc $_.Name -o ($_.BaseName + ".md")
    }
} elseif ($action -eq "2") {
    Write-Host "Conversion de Markdown vers DOCX..." -ForegroundColor Cyan
    Get-ChildItem . -Filter *.md | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
        Write-Host "Traitement de $($_.Name)..."
        pandoc $_.Name -o ($_.BaseName + ".docx")
    }
}

Write-Host "Terminé !" -ForegroundColor Green
