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

Import-Module -Name "$PSScriptRoot\..\..\..\PSCI.psd1" -Force

Describe -Tag "PSCI.unit" "Invoke-ClearDirectoryMetaRunner" {
    InModuleScope PSCI.teamcityExtensions {
        
            Context "when IncludeRegex and ExcludeRegex are specified" {
                It "directories should be properly filtered" {

                    try { 
                        Push-Location -Path $env:TEMP
                        New-Item -Path 'test1\bin' -ItemType Directory -Force
                        New-Item -Path 'test2\bin' -ItemType Directory -Force

                        Invoke-ClearDirectoryMetaRunner -IncludeRegex 'bin$' -ExcludeRegex 'test2'

                        Test-Path -LiteralPath 'test1\bin' | Should Be $false
                        Test-Path -LiteralPath 'test2\bin' | Should Be $true
                    } finally {
                        Remove-Item -LiteralPath 'test1' -Force -Recurse
                        Remove-Item -LiteralPath 'test2' -Force -Recurse
                        Pop-Location
                    }
                }
            }
    }
}