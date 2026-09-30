$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '../terra_nt')
try {
    & flutter analyze --no-pub
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & flutter test --no-pub
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $buildArgs = @('build', 'apk', '--release', '--no-pub')
    if (Test-Path -LiteralPath '.env') {
        $buildArgs += '--dart-define-from-file=.env'
    }
    & flutter @buildArgs
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
