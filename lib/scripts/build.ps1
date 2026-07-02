param(
    [string]$Arg = ''
)

try {
    $versionName = $null
    $versionSuffix = $env:PILI_VERSION_SUFFIX

    $versionCode = [int](git rev-list --count HEAD).Trim()

    $commitHash = (git rev-parse HEAD).Trim()

    if ([string]::IsNullOrWhiteSpace($versionSuffix) -and
        $env:GITHUB_REPOSITORY -and
        $env:GITHUB_REPOSITORY -ne 'Starfallan/PiliNara') {
        $versionSuffix = '-fork'
    }

    if (-not [string]::IsNullOrWhiteSpace($versionSuffix) -and
        -not $versionSuffix.StartsWith('-')) {
        $versionSuffix = "-$versionSuffix"
    }

    $updatedContent = foreach ($line in (Get-Content -Path 'pubspec.yaml' -Encoding UTF8)) {
        if ($line -match '^\s*version:\s*([\d\.]+)') {
            $versionName = $matches[1]
            if (-not [string]::IsNullOrWhiteSpace($versionSuffix)) {
                $versionName += $versionSuffix
            }
            elseif ($Arg -eq 'android') {
                $versionName += '-' + $commitHash.Substring(0, 9)
            }
            "version: $versionName+$versionCode"
        }
        else {
            $line
        }
    }

    if ($null -eq $versionName) {
        throw 'version not found'
    }

    $updatedContent | Set-Content -Path 'pubspec.yaml' -Encoding UTF8

    $buildTime = [int]([DateTimeOffset]::Now.ToUnixTimeSeconds())

    $data = @{
        'pili.name' = $versionName
        'pili.code' = $versionCode
        'pili.hash' = $commitHash
        'pili.time' = $buildTime
    }

    $data | ConvertTo-Json -Compress | Out-File 'pili_release.json' -Encoding UTF8

    Add-Content -Path $env:GITHUB_ENV -Value "version=$versionName+$versionCode"
}
catch {
    Write-Error "Prebuild Error: $($_.Exception.Message)"
    exit 1
}
