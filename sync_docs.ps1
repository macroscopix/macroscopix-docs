# Script de Synchronisation MacroscopiX Docs
# Ce script convertit les fichiers entre le format .docx (dossier docx/) et .md (racine)

$action = Read-Host "Quelle action voulez-vous faire ? (1: Docx -> MD, 2: MD -> Docx)"

if ($action -eq "1") {
    Write-Host "Conversion de DOCX vers Markdown..." -ForegroundColor Cyan
    if (-not (Test-Path "docx")) { mkdir "docx" }
    Get-ChildItem docx/ -Filter *.docx | ForEach-Object {
        Write-Host "Traitement de $($_.Name)..."
        pandoc "docx/$($_.Name)" -o "$($_.BaseName).md"
    }
} elseif ($action -eq "2") {
    Write-Host "Conversion de Markdown vers DOCX..." -ForegroundColor Cyan
    if (-not (Test-Path "docx")) { mkdir "docx" }
    Get-ChildItem . -Filter *.md | Where-Object { $_.Name -ne "README.md" } | ForEach-Object {
        Write-Host "Traitement de $($_.Name)..."
        pandoc "$($_.Name)" -o "docx/$($_.BaseName).docx"
    }
}

Write-Host "Terminé !" -ForegroundColor Green
