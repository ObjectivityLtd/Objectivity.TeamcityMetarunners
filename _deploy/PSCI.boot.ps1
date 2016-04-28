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

$psciPath = $env:PSCI_PATH
if (!$psciPath) { 
  $psciPath = [Environment]::GetEnvironmentVariable('PSCI_PATH', 'Machine')
}
if (!$psciPath) {
  $psciPath = Get-ChildItem -Path "$PSScriptRoot\.." -Exclude 'Boot' | Select -First 1 -ExpandProperty FullName
  if (!$psciPath) { 
      Write-Host -Object "No PSCI_PATH environment variable and PSCI not found at '$PSScriptRoot\..'. Please ensure PSCI is installed on $([system.environment]::MachineName)."
      exit 1
  } 
}
$psciPath = Join-Path -Path $psciPath -ChildPath 'PSCI.psd1'
if (!(Test-Path -LiteralPath $psciPath )) {
  Write-Host "Cannot find '$psciPath'. Please ensure PSCI is installed on $([system.environment]::MachineName)."
  exit 1
}

Import-Module -Name $psciPath 