Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

Push-Location "$env:BUILD_SOURCESDIRECTORY" # push location for Resolve-Path -Relative to work
$resxFiles = Get-ChildItem -Recurse -Path "$env:BUILD_SOURCESDIRECTORY\*\*.resx"
$xlfFiles = Get-ChildItem -Recurse -Path "$env:BUILD_SOURCESDIRECTORY\*\*.xlf"
$locFiles = @($resxFiles) + $xlfFiles

$exclusionsFilePath = "$env:BUILD_SOURCESDIRECTORY\Localize\LocExclusions.json"
$exclusions = @{ Exclusions = @() }
if (Test-Path -Path $exclusionsFilePath)
{
    $exclusions = Get-Content "$env:BUILD_SOURCESDIRECTORY\Localize\LocExclusions.json" | ConvertFrom-Json
}


$locJson = @{
    Projects = @(
        @{
            LanguageSet = "Azure_Languages"
            LocItems = @(
                $locFiles | ForEach-Object {
                    $outputPath = "Localize\$(($_.DirectoryName | Resolve-Path -Relative).Substring(2) + "\" + $_.Name)" 
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