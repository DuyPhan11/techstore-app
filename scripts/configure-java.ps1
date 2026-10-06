function Test-ValidJdk21($path) {
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { return $false }
    $javaBin = Join-Path $path 'bin'
    $javaRelease = Join-Path $path 'release'
    if ((Test-Path -LiteralPath (Join-Path $javaBin 'java.exe')) -and
        (Test-Path -LiteralPath (Join-Path $javaBin 'javac.exe')) -and
        (Test-Path -LiteralPath $javaRelease)) {
        $javaMetadata = Get-Content -LiteralPath $javaRelease -Raw
        if ($javaMetadata -match '(?m)^JAVA_VERSION="21(?:\.|"|\+)') {
            return $true
        }
    }
    return $false
}

if (-not (Test-ValidJdk21 $env:JAVA_HOME)) {
    # Check system JAVA_HOME
    $sysJava = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'Machine')
    if (-not $sysJava) { $sysJava = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'User') }
    if (Test-ValidJdk21 $sysJava) {
        $env:JAVA_HOME = $sysJava
    } else {
        # Search common JDK 21 install paths
        $candidates = @(
            'C:\Program Files\Java\jdk-21*',
            'C:\Program Files\Eclipse Adoptium\jdk-21*',
            'C:\Program Files\Amazon Corretto\jdk21*',
            'C:\Program Files\Microsoft\jdk-21*',
            "$env:USERPROFILE\.jdks\*21*"
        )
        foreach ($pattern in $candidates) {
            $found = Get-Item $pattern -ErrorAction SilentlyContinue | Where-Object { Test-ValidJdk21 $_.FullName } | Select-Object -First 1
            if ($found) {
                $env:JAVA_HOME = $found.FullName
                break
            }
        }
    }
}

if (-not (Test-ValidJdk21 $env:JAVA_HOME)) {
    throw "TechStore requires JDK 21. Vui long cai dat JDK 21 va cap nhat JAVA_HOME trong file .env."
}

$javaBin = Join-Path $env:JAVA_HOME 'bin'
$env:PATH = "$javaBin;$env:PATH"
Write-Host "TechStore uses JDK 21: $env:JAVA_HOME"
