$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'load-env.ps1')
. (Join-Path $PSScriptRoot 'configure-java.ps1')
Set-Location (Join-Path $projectRoot 'backend')
& .\mvnw.cmd -q dependency:build-classpath '-Dmdep.outputFile=target/test-classpath.txt'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$testClasspath = (Get-Content target/test-classpath.txt -Raw).Trim()
& (Join-Path $env:JAVA_HOME 'bin/java.exe') --class-path $testClasspath (Join-Path $PSScriptRoot 'PrepareTestDatabase.java') $projectRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\mvnw.cmd test
exit $LASTEXITCODE
