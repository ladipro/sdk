Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$exclusionsFilePath = "$env:BUILD_SOURCESDIRECTORY\Localize\LocExclusions.json"
$exclusions = @{ Exclusions = @() }
if (Test-Path -Path $exclusionsFilePath)
{
    $exclusions = Get-Content "$env:BUILD_SOURCESDIRECTORY\Localize\LocExclusions.json" | ConvertFrom-Json
}

Push-Location "$env:BUILD_SOURCESDIRECTORY" # push location for Resolve-Path -Relative to work
$jsonFiles = Get-ChildItem -Recurse - Path "$env:BUILD_SOURCESDIRECTORY\*\en\strings.json"
$xlfFiles = @()

$allXlfFiles = Get-ChildItem -Recurse -Path "$env:BUILD_SOURCESDIRECTORY\*\*.xlf"
$langXlfFiles = @()
if ($allXlfFiles.Length -gt 0) {
    $isMatch = $allXlfFiles[0].FullName -Match "\.([\w-]+)\.xlf"
    $firstLangCode = $Matches.1
    $langXlfFiles = Get-ChildItem -Recurse -Path "$env:BUILD_SOURCESDIRECTORY\*\*.$firstLangCode.xlf"
}
$langXlfFiles | ForEach-Object {
    $isMatch = $_.Name -Match "([^.]+)\.[\w-]+\.xlf"
    $xlfFiles += Copy-Item "$($_.FullName)" -Destination "$($_.Directory.FullName)\$($Matches.1).xlf" -PassThru
}

$locFiles = $jsonFiles + $xlfFiles

$locJson = @{
    Projects = @(
        @{
            LanguageSet = "VS_Main_Languages"
            LocItems = @(
                $locFiles | ForEach-Object {
                    $outputPath = "Localize\$(($_.DirectoryName | Resolve-Path -Relative).Substring(2) + "\")" 
                    $continue = $true
                    $exclusions.Exclusions | ForEach-Object {
                        if ($outputPath.Contains($_))
                        {
                            $continue = $false
                        }
                    }
                    if ($continue)
                    {
                        @{
                            SourceFile = $_.FullName
                            CopyOption = "LangIDOnName"
                            OutputPath = $outputPath
                        }
                    }
                }
            )
        }
    )
}

$json = ConvertTo-Json $locJson -Depth 5
Write-Host "(NETCORE_ENGINEERING_TELEMETRY=Build) LocProject.json generated:`n`n$json`n`n"
Pop-Location

New-Item "$env:BUILD_SOURCESDIRECTORY\Localize\LocProject.json" -Force
Set-Content "$env:BUILD_SOURCESDIRECTORY\Localize\LocProject.json" $json
Copy-Item "$env:BUILD_SOURCESDIRECTORY\Localize\LocProject.json" "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\loc"