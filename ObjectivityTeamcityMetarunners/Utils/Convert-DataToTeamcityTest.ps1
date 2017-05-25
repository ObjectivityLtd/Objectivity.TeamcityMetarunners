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

function Convert-DataToTeamcityTest {
    <#
    .SYNOPSIS
    Convert input dataset into TeamCity test service messages.
    
    .PARAMETER InputData
    Input data set.

    .PARAMETER ColumnTestName
    Column indicates the name of the test.
    
    .PARAMETER ColumnsToReportAsTests
    List of columns that will be reported as TeamCity tests (each column will be mapped to one category).
    For example, if $ColumnsToReportsAsTests = @('average','median') and you have tests 'x', 'y', there will be
    tests average.x, average.y, median.x, median.y

    .PARAMETER TestSuiteName
    Name of test suite that will be reported to TeamCity.

    .PARAMETER TestNames
    When parameter is specified, then only test names specified in this list are taken into consideration.
    Names contained in the ColumnTestName will be filtered into 
    Otherwise (when parameter is not specified) there is no filter.

    .PARAMETER IgnoreTestNames
    List of test names to ignore in TeamCity. (Only used if $TestNames parameter is not specified.)

    .PARAMETER ColumnTestFailure
    Name of dataset column containing information about test errors (decimal number).
    If greater than FailureThreshold, the test will be marked as failed.

    .PARAMETER FailureThreshold
    Threshold for $ColumnTestFailure parameter, above which test will be marked as failed.

    .EXAMPLE
    Convert-DataToTeamcityTest -InputData $InputData -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average'

    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [object[]]
        $InputData,

        [Parameter(Mandatory=$true)]
        [string]
        $ColumnTestName,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ColumnsToReportAsTests,

        [Parameter(Mandatory=$false)]
        [string]
        $TestSuiteName,

        [Parameter(Mandatory=$false)]
        [string[]]
        $TestNames,

        [Parameter(Mandatory=$false)]
        [string[]]
        $IgnoreTestNames,

        [Parameter(Mandatory=$false)]
        [string]
        $ColumnTestFailure,

        [Parameter(Mandatory=$false)]
        [decimal]
        $FailureThreshold = 0

    )

    if ($TestSuiteName) {
        Write-Output -InputObject "##teamcity[testSuiteStarted name='$TestSuiteName']"
    }

    if ($TestNames) {
        $testFilter = { $_.$ColumnTestName -in $TestNames }
    } else {
        $testFilter = { $_.$ColumnTestName -notin $IgnoreTestNames }
    }

    $InputData = $InputData.Where($testFilter)

    # validate all required columns exist in dataset
    if ($InputData.Count -gt 0) {
        $firstRow = $InputData[0]
        foreach ($column in $ColumnsToReportAsTests) {
            if ($firstRow.PSObject.Properties.Name -inotcontains $column) {
                throw "Dataset does not contain column named '$column'."
            }
        }
    }

    foreach ($row in $InputData) {
        $baseTestName = $row.$ColumnTestName
        
        foreach ($column in $ColumnsToReportAsTests) {
            if ($row.$column -ne [System.DBNull]::Value) {
                $testName = "$($column).$baseTestName"
                $testNameEscaped = Convert-StringToTeamCityEscapedString -String $testName
                Write-Output -InputObject ("##teamcity[testStarted name='{0}']" -f $testNameEscaped)
                if ($ColumnTestFailure) {
                    $failureValue = [decimal]($row.$ColumnTestFailure)
                    if ($failureValue -gt $FailureThreshold) {
                        Write-Output -InputObject ("##teamcity[testFailed name='{0}' message='{1}']" -f $testNameEscaped, "Failure threshold exceeded (${failureValue} > ${FailureThreshold})")
                    }
                }

                #create miliseconds from seconds and round to whole miliseconds (without decimal digits)
                $testTime = [decimal]::round($row.$column * 1000)

                Write-Output -InputObject ("##teamcity[testFinished name='{0}' duration='{1}']" -f $testNameEscaped, $testTime)
            }
        }
    }

    if ($TestSuiteName) {
        Write-Output -InputObject "##teamcity[testSuiteFinished name='$TestSuiteName']"
    }

}