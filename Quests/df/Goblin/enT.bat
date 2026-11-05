@echo off
chcp 65001 >nul
setlocal

set "PS1=%TEMP%\dump_lua_%RANDOM%.ps1"

> "%PS1%" (
  echo $ErrorActionPreference = 'Stop'
  echo $out = Join-Path (Get-Location) 'lua_dump.txt'
  echo $files = Get-ChildItem -Recurse -File -Filter *.lua ^| Where-Object { $_.FullName -ne $out } ^| Sort-Object FullName
  echo $sb = New-Object System.Text.StringBuilder
  echo [void]$sb.AppendLine(('=' * 70)^)
  echo [void]$sb.AppendLine(' LUA DUMP: ' + (Get-Location)^)
  echo [void]$sb.AppendLine(' Date: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')^)
  echo [void]$sb.AppendLine(' Files: ' + $files.Count^)
  echo [void]$sb.AppendLine(('=' * 70)^)
  echo [void]$sb.AppendLine(''^)
  echo foreach ($f in $files) {
  echo     $rel = $f.FullName.Substring((Get-Location).Path.Length + 1).Replace('\','/')
  echo     [void]$sb.AppendLine(('=' * 70)^)
  echo     [void]$sb.AppendLine(' FILE: ' + $rel^)
  echo     [void]$sb.AppendLine(('=' * 70)^)
  echo     [void]$sb.AppendLine(''^)
  echo     try { $t = Get-Content -Raw -Encoding UTF8 -LiteralPath $f.FullName }
  echo     catch { $t = '-- [dump] не UTF-8: ' + $rel }
  echo     [void]$sb.AppendLine($t^)
  echo     [void]$sb.AppendLine(''^)
  echo }
  echo [System.IO.File]::WriteAllText($out, $sb.ToString^(^), (New-Object System.Text.UTF8Encoding $false^)^)
  echo Write-Host ('Готово: ' + $out^)
  echo Write-Host ('Файлов .lua: ' + $files.Count^)
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
del "%PS1%" >nul 2>nul

echo.
pause