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

Describe -Tag "PSCI.unit" "Convert-DataToTeamCityTest.Tests.ps1" {
    InModuleScope PSCI.teamcityExtensions {

            Context "when provided valid InputData" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName1'
                        Average = 300
                    },
                    [PSCustomObject]@{
                        Name = 'TestName2'
                        Average = 400
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average'

                It "should return valid TeamCity service messages" {
                    $output.Count | Should Be 4
                    $output[0] | Should Be "##teamcity[testStarted name='Average.TestName1']"
                }
            }
            
            Context "when ColumnTestFailure is greater than 0" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName1'
                        Average = 300
                        ColumnTestFailureName = 1
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests @('Average') -ColumnTestFailure 'ColumnTestFailureName'

                It "should return valid TeamCity service messages" {
                    $output.Count | Should Be 3
                    $output[1] | Should Be "##teamcity[testFailed name='Average.TestName1' message='Failure threshold exceeded (1 > 0)']"
                }
            }
            
            Context "when TestSuiteName parameter is provided" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName1'
                        Average = 300
                    }
                )

                $testSuiteName = 'someTestSuiteName'
                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average' -TestSuiteName $testSuiteName

                It "should be logged as valid TeamCity service messages" {
                    $output.Count | Should Not Be $null
                    $output.Count | Should Be 4
                    $output[0] | Should Be "##teamcity[testSuiteStarted name='$testSuiteName']"
                    $output[3] | Should Be "##teamcity[testSuiteFinished name='$testSuiteName']"
                }
            }

            Context "when provided valid InputData but looking for a column which not exists in input dataset" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName1'
                        Average = 300
                    },
                    [PSCustomObject]@{
                        Name = 'TestName2'
                        Average = 400
                    }
                )

                It "should throw exception" {
                    { Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'NotExistingColumnName' } | Should Throw
                }
            }

            Context "when 2 tests are provided but TestNames parameter contains only one of them " {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName1'
                        Minimum = 1
                    },
                    [PSCustomObject]@{
                        Name = 'TestName2'
                        Minimum = 2
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Minimum' -TestNames 'TestName1'

                It "should return valid TeamCity service messages only from the first test name (TestName1)" {
                    $output.Count | Should Be 2
                    $output[0] | Should Be "##teamcity[testStarted name='Minimum.TestName1']"
                }
            }

            Context "when in IgnoreTestNames parameter 1 test is set to be ignored" {
                $testNameWhichShouldBeExcluded = 'TestName2'
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName1'
                        Minimum = 1
                    },
                    [PSCustomObject]@{
                        Name = $testNameWhichShouldBeExcluded
                        Minimum = 2
                    },
                    [PSCustomObject]@{
                        Name = 'TestName3'
                        Minimum = 3
                    },
                    [PSCustomObject]@{
                        Name = 'TestName4'
                        Minimum = 4
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Minimum' -IgnoreTestNames $testNameWhichShouldBeExcluded

                $outputContainsExludedName = $false;
                foreach($var in $output)
                {
                    if($var.Contains($testNameWhichShouldBeExcluded))
                    {
                        $outputContainsExludedName = $true;
                    }
                }

                It "this test (with given name) should be exluded from output" {
                    $output.Count | Should Be 6
                    $outputContainsExludedName | Should be $false
                }
            }

            Context "when dbnull value is provided as some column to report" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName777'
                        ErrorPercentage = [System.DBNull]::Value
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests @('ErrorPercentage')

                It "should not return any TeamCity service messages" {
                    $output | Should Be $null
                }
            }

            Context "when provided column contains value with few digits after coma" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName123321'
                        Average = 0.174444
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average'

                It "should return valid TeamCity service messages contains proper rounding (round down)" {
                    $output.Count | Should Be 2
                    $output[1] | Should Be "##teamcity[testFinished name='Average.TestName123321' duration='174']"
                }
            }

            Context "when provided column contains value with few digits after coma" {
                $InputData = @(
                    [PSCustomObject]@{
                        Name = 'TestName123321'
                        Average = 0.1745555555555
                    }
                )

                $output = Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average'

                It "should return valid TeamCity service messages contains proper rounding (round up)" {
                    $output.Count | Should Be 2
                    $output[1] | Should Be "##teamcity[testFinished name='Average.TestName123321' duration='175']"
                }
            }
    }
}