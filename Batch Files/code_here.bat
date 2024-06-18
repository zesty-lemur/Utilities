@echo off
:: Get the clipboard content and store it in a variable
for /f "tokens=* delims=" %%a in ('powershell -command "Get-Clipboard"') do set rawPath=%%a

:: Remove double quotes from the path
set rawPath=%rawPath:"=%

:: Get the target path by splitting the path
for /f "tokens=* delims=" %%a in ('powershell -command "[System.IO.Path]::GetDirectoryName('%rawPath%')"') do set targetPath=%%a

:: Open the target path in VS Code
code "%targetPath%"