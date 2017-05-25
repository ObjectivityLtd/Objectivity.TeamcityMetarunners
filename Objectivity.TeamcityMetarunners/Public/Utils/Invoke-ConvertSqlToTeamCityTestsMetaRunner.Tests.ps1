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

Import-Module -Name "$PSScriptRoot\..\..\Objectivity.TeamcityMetarunners.psd1" -Force


Describe "Invoke-ConvertSqlToTeamCityTestsMetaRunner.Tests.ps1" {
    InModuleScope Objectivity.TeamcityMetarunners {
    <#
        Context "when call with predefined sql query name which is empty and parameter Query is not given" {
            It "should throw missing parameter" {
                {Invoke-ConvertSqlToTeamCityTestsMetaRunner -DatabaseServer 'localhost' -DatabaseName 'LoadTest2010' -IntegratedSecurity `
                    -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average', 'Minimum', 'Maximum' -PredefinedQuery ''} | Should Throw
            }
        }

        Context "when call with predefined sql query name" {        
            $TrxFolderOrFilePath = 'C:\TestReport.trx'
            Mock Test-Path { return $true } -ParameterFilter { $TrxFolderOrFilePath -eq 'C:\TestReport.trx' }
            Mock Get-Content { return "<TestRun id='6d03ab07-c551-4847-a311-9fa9c36bf61c'></TestRun>" }
            Mock Convert-DataToTeamCityTest { return  }

            It "should work" {
                $output = Invoke-ConvertSqlToTeamCityTestsMetaRunner -DatabaseServer 'localhost' -DatabaseName 'LoadTest2010' -IntegratedSecurity `
                    -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average', 'Minimum', 'Maximum' -PredefinedQuery 'LoadTestVisualStudioQuery' -TrxFolderOrFilePath 'C:\TestReport.trx'

                $output.Foreach({ Write-Host $_ })
            }
        }

        Context "when call with provided sql query" {

        $sql = @'
        select top 5 'Request' as Type, 
                LoadTestRunId,
            ScenarioName,
                TestCaseName, 
            RequestUri as Name,
            PageCount as Count,
            Average*1000 as Average,
            Minimum*1000 as Minimum,
            Maximum*1000 as Maximum,
            Percentile90*1000 as Percentile90,
            Percentile95*1000 as Percentile95
        from  [dbo].[LoadTestPageResults]
'@

            It "should work" {
                $output = Invoke-ConvertSqlToTeamCityTestsMetaRunner -DatabaseServer 'localhost' -DatabaseName 'LoadTest2010' -IntegratedSecurity `
                    -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average', 'Minimum', 'Maximum' -Query $sql

                $output.Foreach({ Write-Host $_ })
            }
        }
        #>
    }
}
