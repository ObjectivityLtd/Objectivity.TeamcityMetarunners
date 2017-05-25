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

Describe -Tag "PSCI.unit" "Get-PredefinedSqlQuery.ps1" {
    InModuleScope PSCI.teamcityExtensions {
            
            Context "when supplied predefined query name which does not exist" {
                It "should throw exception." {
                   {Get-PredefinedSqlQuery -PredefinedQueryName 'NotExistingSqlQueryName'} | Should Throw
                }
            }
            
                        
            Context "when predefined query is LoadTestVisualStudioQuery but none TestRunGuid parameter supplied " {
                It "should throw exception" {
                   {Get-PredefinedSqlQuery -PredefinedQueryName 'LoadTestVisualStudioQuery'} | Should Throw
                }
            }
            
                        
            Context "when predefined query is LoadTestVisualStudioQuery but testRunGuid parameter is empty" {
                It "should throw exception." {
                   {Get-PredefinedSqlQuery -PredefinedQueryName 'LoadTestVisualStudioQuery' -TestRunGuid ''} | Should Throw
                }
            }
            
                        
            Context "when predefined query is LoadTestVisualStudioQuery and testRunGuid is supplied" {                
                It "should return the predefined query containing given testRunGuid" {
                   $result = Get-PredefinedSqlQuery -PredefinedQueryName 'LoadTestVisualStudioQuery' -TestRunGuid '0000-1111-AAAA-BBBB-9999'

                   $result | Should Not Be $null
                   $result.Contains('0000-1111-AAAA-BBBB-9999') | Should Be $true
                }
            }
    }
}