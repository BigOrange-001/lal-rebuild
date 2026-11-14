[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$AndroidSdk,
    [string]$JavaHome,
    [string]$Python,
    [string]$GradleLauncher,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Tasks
)
$ErrorActionPreference = 'Stop'

function Resolve-GradleLauncher {
    # Prefers the checked-in wrapper, which pins the distribution for everyone.
    # This repository carries no gradle-wrapper.jar, so the fallback reaches for
    # an already-downloaded distribution instead of fetching one at build time.
    param([Parameter(Mandatory)][string] $ManagerDir)

    $wrapper = Join-Path $ManagerDir 'gradlew.bat'
    if (Test-Path -LiteralPath $wrapper -PathType Leaf) {
        return $wrapper
    }

    $cacheRoot = Join-Path $env:USERPROFILE '.gradle\wrapper\dists\gradle-8.13-bin'
    $cached = @(Get-ChildItem -Path $cacheRoot -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'gradle-8.13\bin\gradle.bat' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1)
    if ($cached.Count -gt 0) {
        return $cached[0]
    }

    throw @'
Gradle 8.13 was not found. Either supply -GradleLauncher, or restore the wrapper
(android-manager/gradle/wrapper/gradle-wrapper.jar plus gradlew.bat), or let
Gradle download the distribution once by running "gradle wrapper" in
android-manager with Gradle 8.13 on PATH.
'@
}

# Builds the Android manager APK.
#
# Like build-client.ps1, this runs the whole build through a temporary drive
# alias. The repository lives under a path containing non-ASCII characters, and
# aapt2 and Chaquopy's native toolchain do not survive that on Windows; the alias
# gives every tool an ASCII path without maintaining a second checkout.
#
# Gems and the Python runtime are fetched from the network on first run, so this
# needs internet access the first time and none afterwards.

$repoRoot = $PSScriptRoot
$driveName = @('R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z') |
    Where-Object { -not (Get-PSDrive -Name $_ -ErrorAction SilentlyContinue) } |
    Select-Object -First 1
if (-not $driveName) {
    throw 'No free drive letter is available for the temporary build path.'
}

$drive = "${driveName}:"
$subst = Join-Path $env:SystemRoot 'System32\subst.exe'
& $subst $drive $repoRoot
if ($LASTEXITCODE -ne 0) {
    throw "Could not create the temporary build drive $drive."
}

try {
    $asciiRoot = "$drive\"
    $manager = Join-Path $asciiRoot 'android-manager'
    $androidSdk = if ($AndroidSdk) { $AndroidSdk } else { Join-Path $asciiRoot 'tools\android\sdk' }
    $javaHome = if ($JavaHome) { $JavaHome } else { Join-Path $asciiRoot 'tools\jdk-17' }
    $python = if ($Python) { $Python } else { Join-Path $asciiRoot '.venv\Scripts\python.exe' }
    $runtimeAssets = Join-Path $asciiRoot 'build\android-runtime-assets'

    if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
        throw "Python virtual environment not found at $python. See README.md."
    }

    # The assets must be assembled from the current server sources; a stale
    # bundle would ship old gameplay code inside the APK.
    # -I keeps the script from importing a same-named module out of the cwd.
    #
    # The bundle is written to <assetsRoot>\runtime, not to assetsRoot itself:
    # Gradle merges an assets source directory's *contents* into the APK's
    # assets/, so the extra level is what puts the tree at assets/runtime/...
    # where RuntimeInstaller.ASSET_ROOT looks for it.
    & $python -I (Join-Path $asciiRoot 'scripts\prepare_android_runtime.py') `
        --output (Join-Path $runtimeAssets 'runtime')
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not assemble the server runtime assets.'
    }

    # Gradle discovers the SDK from local.properties; it is generated rather
    # than committed because the path is machine-specific.
    $sdkEscaped = $androidSdk.Replace('\', '\\')
    $properties = Join-Path $manager 'local.properties'
    Set-Content -LiteralPath $properties -Value "sdk.dir=$sdkEscaped" -Encoding ASCII

    # The runtime assets live outside the project so the build never mutates the
    # server sources; Gradle reads the location from this property.
    $assetsProperty = '-PlalRuntimeAssets=' + ($runtimeAssets -replace '\\', '/')
    $gradleArgs = @('--no-daemon', '--no-watch-fs', $assetsProperty, ('-PlalBuildPython=' + $python)) + $Tasks
    if (!$Tasks) {
        # No task was named, so do the useful default.
        $gradleArgs += 'assembleRelease'
    }

    Push-Location $manager
    try {
        $env:JAVA_HOME = $javaHome
        $env:ANDROID_HOME = $androidSdk
        $env:ANDROID_SDK_ROOT = $androidSdk

        $taskGradle = if ($GradleLauncher) { $GradleLauncher } else { Resolve-GradleLauncher -ManagerDir $manager }
        & $taskGradle @gradleArgs
        exit $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
}
finally {
    & $subst $drive /D
}
