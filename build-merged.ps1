<#
.SYNOPSIS
    Builds the merged APK: the AIR game client plus the manager, one package,
    one launcher icon.

.DESCRIPTION
    Two builds in sequence, and the order matters. build-android.ps1 produces
    the manager's dex, native libraries and assets in isolation; the Python
    assembler then takes the *client* APK as the base and grafts them in, so
    that resources.arsc, res/, classes.dex and the AIR assets never get
    re-encoded. The client's classes.dex bakes nine Lair/.../R$* constant sets
    into bytecode, which is why its resource table has to survive untouched.

    Like the other build scripts this runs through a temporary drive alias: the
    project may live under a path containing non-ASCII characters, and aapt2,
    zipalign and Chaquopy's native toolchain all mishandle that on Windows.

    Every path defaults to this repository's own layout and can be overridden,
    so the script can be lifted into a project that arranges things
    differently. The only values that are genuinely not free choices are the
    keystore (must stay the same key, or the merged APK cannot upgrade an
    installed copy) and the version numbers (the manager's versionCode must
    match the shipping manifest's, or the bundled Python server will not
    re-unpack on update).

.PARAMETER ClientApk
    The prebuilt game client APK. Default: build/lal-rebuild-1.0.0.apk

.PARAMETER ManagerApk
    The manager APK produced by build-android.ps1.
    Default: android-manager/app/build/outputs/apk/release/app-release.apk

.PARAMETER Manifest
    The shipping manifest, plain XML, linked against the client's table.
    Default: build/merged/AndroidManifest.xml

.PARAMETER Keystore
    Signing keystore. Default: build/debug.p12. Never commit this file, and
    never change it between releases.

.PARAMETER Output
    Output APK. Default: build/lal-merged-<version>.apk

.PARAMETER AndroidSdk
    Android SDK root. Default: tools/android/sdk

.PARAMETER BuildTools
    Build-tools version directory under the SDK. Default: 35.0.0

.PARAMETER Platform
    Platform directory under the SDK, for android.jar. Default: android-35

.PARAMETER SkipManager
    Skip build-android.ps1 and assemble from the existing manager APK. Useful
    while iterating on the graft, which takes seconds rather than minutes.

.EXAMPLE
    ./build-merged.ps1
    Full build with this repository's layout.

.EXAMPLE
    ./build-merged.ps1 -SkipManager
    Re-assemble from the manager APK already on disk.
#>
[CmdletBinding()]
param(
    [string]$ClientApk,
    [string]$ManagerApk,
    [string]$Manifest,
    [string]$Keystore,
    [string]$Output,
    [string]$WorkDir,
    [string]$AndroidSdk,
    [string]$JavaHome,
    [string]$Python,
    [string]$GradleLauncher,
    [string]$BuildTools = '35.0.0',
    [string]$Platform = 'android-35',
    [switch]$SkipManager
)

$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$version = if (Test-Path -LiteralPath (Join-Path $repoRoot 'VERSION')) {
    (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
}
else {
    '1.0.0'
}

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
    # The alias exists only because the real path may be non-ASCII, so every
    # default is expressed relative to the alias. Explicit absolute paths
    # inside this engineering folder must use that alias too: dexdump and
    # other native tools cannot read a Unicode --work-dir.
    $asciiRoot = "$drive\"
    $resolve = {
        param($given, $fallback)
        if ($given) {
            $resolvedPath = if ([System.IO.Path]::IsPathRooted($given)) {
                [System.IO.Path]::GetFullPath($given)
            } else {
                [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $given))
            }
            $rootPrefix = $repoRoot.TrimEnd('\') + '\'
            if ($resolvedPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                Join-Path $asciiRoot $resolvedPath.Substring($rootPrefix.Length)
            } elseif ($resolvedPath.Equals($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $asciiRoot
            } else {
                $resolvedPath
            }
        }
        else {
            Join-Path $asciiRoot $fallback
        }
    }

    Push-Location $asciiRoot
    try {
        $androidSdk = & $resolve $AndroidSdk 'tools\android\sdk'
        $python = if ($Python) { $Python } else { Join-Path $asciiRoot '.venv\Scripts\python.exe' }
        $clientApk = & $resolve $ClientApk "build\lal-rebuild-client-$version.apk"
        $managerApk = & $resolve $ManagerApk 'android-manager\app\build\outputs\apk\release\app-release.apk'
        $manifestPath = & $resolve $Manifest 'android-manager\merged-AndroidManifest.xml'
        $keystore = & $resolve $Keystore 'build\debug.p12'
        $output = & $resolve $Output "build\lal-merged-$version.apk"

        if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
            throw "Python virtual environment not found at $python. See README.md."
        }
        if (-not (Test-Path -LiteralPath $keystore -PathType Leaf)) {
            throw "Signing keystore not found at $keystore. Run build-client.ps1 first; the merged APK must be signed with the same key or it cannot upgrade an installed copy."
        }
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            throw "Shipping manifest not found at $manifestPath."
        }

        if (-not $SkipManager) {
            # build-android.ps1 points JAVA_HOME/ANDROID_HOME at *its own*
            # subst drive and tears that drive down on the way out. $env: is
            # process-wide, so those values leak back here and then dangle —
            # apksigner below would fail with "JAVA_HOME is set to an invalid
            # directory: <drive>:\tools\jdk-17". Hide the child's assignments
            # behind a save/restore.
            $savedEnv = @{}
            foreach ($name in 'JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT') {
                $savedEnv[$name] = [System.Environment]::GetEnvironmentVariable($name, 'Process')
            }
            try {
                & (Join-Path $asciiRoot 'build-android.ps1') -AndroidSdk $androidSdk -JavaHome $JavaHome -Python $python -GradleLauncher $GradleLauncher -Tasks @('assembleRelease', '--no-daemon')
                if ($LASTEXITCODE -ne 0) {
                    throw 'The manager build failed.'
                }
            }
            finally {
                foreach ($name in $savedEnv.Keys) {
                    if ($null -eq $savedEnv[$name]) {
                        Remove-Item -Path "env:$name" -ErrorAction SilentlyContinue
                    }
                    else {
                        Set-Item -Path "env:$name" -Value $savedEnv[$name]
                    }
                }
            }
        }

        if (-not (Test-Path -LiteralPath $managerApk -PathType Leaf)) {
            throw "Manager APK not found at $managerApk. Run build-android.ps1 first."
        }
        if (-not (Test-Path -LiteralPath $clientApk -PathType Leaf)) {
            throw "Game client APK not found at $clientApk. Run build-client.ps1 first."
        }

        # apksigner is a batch wrapper that needs a JRE, and the save/restore
        # above can leave JAVA_HOME unset on a machine that never had one. The
        # project ships its own under tools/, so fall back to that.
        if ($JavaHome) { $env:JAVA_HOME = $JavaHome }
        if (-not ($env:JAVA_HOME -and (Test-Path -LiteralPath $env:JAVA_HOME -PathType Container))) {
            $repoJdk = Join-Path $asciiRoot 'tools\jdk-17'
            if (Test-Path -LiteralPath $repoJdk -PathType Container) {
                $env:JAVA_HOME = $repoJdk
            }
            else {
                throw 'apksigner needs a JDK. Set JAVA_HOME, or place one at tools\jdk-17.'
            }
        }

        # -I keeps the script from importing a same-named module out of the cwd.
        $taskExtraArgs = @()
        if ($WorkDir) { $taskExtraArgs += @('--work-dir', (& $resolve $WorkDir '')) }
        & $python -I (Join-Path $asciiRoot 'scripts\build_merged.py') `
            --client-apk $clientApk `
            --manager-apk $managerApk `
            --manifest $manifestPath `
            --android-sdk $androidSdk `
            --build-tools $BuildTools `
            --platform $Platform `
            --keystore $keystore `
            --output $output `
            --forbid androidx.startup `
            --forbid ProfileInstallReceiver @taskExtraArgs
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    exit $code
}
finally {
    & $subst $drive /D
}
