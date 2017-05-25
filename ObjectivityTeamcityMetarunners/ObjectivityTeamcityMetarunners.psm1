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

$curDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$baseModuleDir = "$curDir\baseModules"

if (!(Get-Module -Name PSCI) -and !(Get-Module -Name PSCI -ListAvailable)) {
    "Importing PSCI library from '${baseModuleDir}\PSCI'"
    Import-Module -Name "${baseModuleDir}\PSCI" -Force -Global
}

$publicFunctions = @()
Get-ChildItem -Recurse $curDir -Include *.ps1 | Where-Object { $_ -notmatch '\.Tests.ps1|_deploy'  } | Foreach-Object {
    . $_.FullName 
    if ($_.FullName -match '(Utils|JMeter|TestTrend|Zap)\\') {
        $publicFunctions += ($_.Name -replace '.ps1', '')
    }     
}

Export-ModuleMember -Function $publicFunctions
