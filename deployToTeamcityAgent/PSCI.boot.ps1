<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

$global:ErrorActionPreference = "Stop"

$modulePath = $env:ObjectivityTeamcityMetarunners_PATH
if (!$modulePath) { 
  $modulePath = [Environment]::GetEnvironmentVariable('ObjectivityTeamcityMetarunners_PATH', 'Machine')
}
if (!$modulePath) {
   Write-Host -Object "No ObjectivityTeamcityMetaRunners_PATH environment variable. Please ensure Objectivity.TeamcityMetarunners is installed on $([system.environment]::MachineName)."
   exit 1
}
$psciPath = Get-ChildItem -Path "$modulePath\PSCI" -Directory | Select-Object -ExpandProperty FullName
if (!(Test-Path -LiteralPath $psciPath )) {
  Write-Host "Cannot find '$psciPath'. Please ensure Objectivity.TeamcityMetarunners is installed on $([system.environment]::MachineName)."
  exit 1
}

Import-Module -Name "$psciPath\PSCI.psd1"

$teamcityRunnersPath = Get-ChildItem -Path "$modulePath\Objectivity.TeamcityMetarunners" -Directory | Select-Object -ExpandProperty FullName
if (!(Test-Path -LiteralPath $psciPath )) {
  Write-Host "Cannot find '$teamcityRunnersPath'. Please ensure Objectivity.TeamcityMetarunners is installed on $([system.environment]::MachineName)."
  exit 1
}

Import-Module -Name "$teamcityRunnersPath\Objectivity.TeamcityMetarunners.psd1"