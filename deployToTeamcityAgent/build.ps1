param ($buildCounter)

$Global:ErrorActionPreference = 'Stop'
$Global:VerbosePreference = 'SilentlyContinue'

### Prepare NuGet / PSGallery
if (!(Get-PackageProvider | Where-Object { $_.Name -eq 'NuGet' })) {
    "Installing NuGet"
    Install-PackageProvider -Name NuGet -force | Out-Null
}
"Preparing PSGallery repository"
Import-PackageProvider -Name NuGet -force | Out-Null
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

### Install PSDepend
$psDepend = Get-Module -Name PSDepend -ListAvailable
if (!$psDepend) { 
    "Installing PSDepend"
    Install-Module PSDepend
} 
else {
    "Using PSDepend $($psDepend.Version)"
}

"Creating package"
Remove-Item -Path "$PSScriptRoot\bin" -Force -Recurse -ErrorAction SilentlyContinue
New-Item -Path "$PSScriptRoot\bin" -ItemType Directory
Copy-Item -Path @("$PSScriptRoot\deploy.ps1", "$PSScriptRoot\PSCI.boot.ps1") -Destination "$PSScriptRoot\bin"
Copy-Item -Path @("$PSScriptRoot\configuration") -Destination "$PSScriptRoot\bin\configuration" -Recurse

Invoke-PSDepend -Path "$PSScriptRoot\build.depend.psd1" -Target "$PSScriptRoot\bin\packages" -Force -Verbose
Compress-Archive -Path "$PSScriptRoot\bin\packages\*" -DestinationPath "$PSScriptRoot\bin\package.zip"
$teamcityMetarunnersVersion = Get-ChildItem -Path "$PSScriptRoot\bin\packages\Objectivity.TeamcityMetarunners" -Directory | Select-Object -ExpandProperty Name
Write-Host "##teamcity[buildNumber '$teamcityMetarunnersVersion-#$buildCounter']"
Remove-Item -Path "$PSScriptRoot\bin\packages\Objectivity.TeamcityMetarunners" -Force -Recurse
