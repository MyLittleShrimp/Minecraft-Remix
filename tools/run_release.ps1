param(
    [ValidateSet('Play','Import','Smoke','Export')][string]$Mode='Play',
    [string]$Godot=''
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
if(-not $Godot){
    $Godot=Join-Path $projectRoot '.tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe'
    if(-not(Test-Path -LiteralPath $Godot)){
        $command=Get-Command godot -ErrorAction SilentlyContinue
        if($command){$Godot=$command.Source}else{throw 'Install Godot 4.7.2, pass -Godot <absolute exe path>, or run python tools/bootstrap_godot.py'}
    }
}
$Godot=(Resolve-Path -LiteralPath $Godot).Path
$localDir=Join-Path $projectRoot '.local/release-check'
New-Item -ItemType Directory -Force -Path $localDir | Out-Null
if($Mode -ne 'Play'){
    $env:REMIX_SAVE_PATH=Join-Path $localDir 'campaign.json'
    $env:REMIX_CONTROLS_PATH=Join-Path $localDir 'controls.cfg'
}
$log=Join-Path $localDir ($Mode.ToLower()+'.log')
$engineArgs=@('--path',$projectRoot,'--log-file',$log)
switch($Mode){
    'Import' {$engineArgs+=@('--headless','--editor','--import')}
    'Smoke' {$engineArgs+=@('--fixed-fps','60','--quit-after','2400','--script','res://tests/release_smoke.gd')}
    'Export' {
        $out=Join-Path $projectRoot 'builds/windows'
        New-Item -ItemType Directory -Force -Path $out | Out-Null
        $engineArgs+=@('--headless','--export-release','Windows Desktop',(Join-Path $out 'MinecraftRemix.exe'))
    }
}
& $Godot @engineArgs
if($LASTEXITCODE -ne 0){throw "Godot $Mode failed; read $log"}
if($Mode -ne 'Play'){
    $content=Get-Content -LiteralPath $log -Raw
    if($content -match 'SCRIPT ERROR|ERROR:|(?m)^FAIL '){throw "Runtime errors; read $log"}
    if($Mode -eq 'Smoke' -and $content -notmatch 'RELEASE_SMOKE checks=\d+ failures=0'){throw 'Smoke check did not finish'}
}
if($Mode -eq 'Export'){
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/INSTALLATION.md') -Destination (Join-Path $out 'README.txt')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/branding/launcher.ico') -Destination $out
    $legal=Join-Path $out 'legal'
    New-Item -ItemType Directory -Force -Path $legal | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets/legal') -File | Copy-Item -Destination $legal
}
Write-Output "RELEASE_RUN $Mode passed"
