$ErrorActionPreference = 'Stop'
$ProjectRoot = $PSScriptRoot
$BundledPython = Join-Path $ProjectRoot '.venv\Scripts\python.exe'
$Gateway = Join-Path $ProjectRoot 'server\gateway.py'
$ExitCode = 1

Push-Location $ProjectRoot
try {
    if (Test-Path -LiteralPath $BundledPython -PathType Leaf) {
        & $BundledPython $Gateway @args
        $ExitCode = $LASTEXITCODE
    }
    elseif (Get-Command python -ErrorAction SilentlyContinue) {
        & python $Gateway @args
        $ExitCode = $LASTEXITCODE
    }
    elseif (Get-Command py -ErrorAction SilentlyContinue) {
        & py -3 $Gateway @args
        $ExitCode = $LASTEXITCODE
    }
    else {
        throw 'Python 3 was not found. Create .venv from server/requirements.txt or install Python 3.'
    }
}
finally {
    Pop-Location
}

exit $ExitCode
