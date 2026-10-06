$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'load-env.ps1')
. (Join-Path $PSScriptRoot 'configure-java.ps1')
if (-not $env:JWT_SECRET -or [Text.Encoding]::UTF8.GetByteCount($env:JWT_SECRET) -lt 32) {
    throw 'Set JWT_SECRET in .env (at least 32 bytes). See README.md.'
}
Set-Location (Join-Path $projectRoot 'backend')
& .\mvnw.cmd spring-boot:run
exit $LASTEXITCODE
