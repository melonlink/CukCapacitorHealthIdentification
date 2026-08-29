# Single build entry point for the manuscript pair.
# Usage:  powershell -File build.ps1        (from manuscript\)
# Builds the English master and the Chinese companion, then refreshes the
# two stable "current PDF" locations:
#   manuscript\main.pdf            <- build\main.pdf
#   manuscript\chinese\main_zh.pdf <- chinese\build\main_zh.pdf
# The stable copies exist so "the latest paper" is always findable without
# entering build caches; NEVER edit them directly.

$ErrorActionPreference = 'Stop'
$env:Path = 'D:\TOOLS\texlive\texlive\2025\bin\windows;' + $env:Path
Set-Location $PSScriptRoot

latexmk -pdf -outdir=build main.tex
if ($LASTEXITCODE -ne 0) { throw "English build failed (latexmk exit $LASTEXITCODE)" }
Copy-Item build\main.pdf main.pdf -Force

Set-Location chinese
latexmk -outdir=build main_zh.tex
# latexmk may return nonzero on dependency bookkeeping; require the PDF to be fresh instead
$xdv = Get-Item build\main_zh.xdv -ErrorAction SilentlyContinue
$pdf = Get-Item build\main_zh.pdf -ErrorAction SilentlyContinue
if (-not $pdf -or ($xdv -and $pdf.LastWriteTime -lt $xdv.LastWriteTime)) {
  xdvipdfmx -o build\main_zh.pdf build\main_zh.xdv
  if ($LASTEXITCODE -ne 0) { throw "Chinese xdv->pdf conversion failed" }
}
Copy-Item build\main_zh.pdf main_zh.pdf -Force
Set-Location $PSScriptRoot

Write-Host "OK: main.pdf and chinese\main_zh.pdf refreshed."
