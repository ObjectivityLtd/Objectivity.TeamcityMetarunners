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

function ConvertTo-JUnitXml {
    <#
    .SYNOPSIS
    Outputs JUnit xml file basing on input CSV file.

    .DESCRIPTION
    If $TestSuiteName is specified, it produces one test for each row of CSV file (taking test time from $ColumnTestTime column).
    
    .PARAMETER CsvInputFilePath
    Path to the input CSV file.

    .PARAMETER OutputFilePath
    Path to the output JUnit xml file.

    .PARAMETER ColumnTestName
    Name of CSV column containing test names.

    .PARAMETER ColumnTestTime
    Name of CSV column containing test times.

    .PARAMETER TestSuiteName
    Name of test suite that will be created in JUnit xml.

    .PARAMETER ColumnTestFailure
    Name of CSV column containing information about test failure (decimal number).
    If greater than FailureThreshold, the test will be marked as failed.

    .PARAMETER FailureThreshold
    Threshold for column $ColumnTestFailure, above which test will be marked as failed.

    .PARAMETER TestNames
    List of test names to report in TeamCity (i.e. rows with column ColumnTestName in TestNames).
    If not specified, all rows will be reported apart from ones specified in $IgnoreTestNames.

    .PARAMETER IgnoreTestNames
    List of test names to ignore in TeamCity. Only used if TestNames is not specified.

    .PARAMETER TestClassNamePrefix
    Prefix that will be added to test name. Can be used to categorize tests (e.g. 'Average.').

    .EXAMPLE
    ConvertTo-JUnitXml -CsvInputFilePath "AggregateReport.csv" -OutputFilePath "JMeter-Results.xml" -TestSuiteName "JMeter" -FailureThreshold 0 `
        -ColumnTestName "sampler_label" -ColumnTestTime "average" -ColumnTestFailure "aggregate_report_error%" -TestClassNamePrefix "Average." `
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $CsvInputFilePath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputFilePath,

        [Parameter(Mandatory=$true)]
        [string]
        $ColumnTestName,

        [Parameter(Mandatory=$true)]
        [string]
        $ColumnTestTime,

        [Parameter(Mandatory=$true)]
        [string]
        $TestSuiteName,

        [Parameter(Mandatory=$false)]
        [string]
        $ColumnTestFailure,

        [Parameter(Mandatory=$false)]
        [decimal]
        $FailureThreshold = 0,

        [Parameter(Mandatory=$false)]
        [string[]]
        $TestNames,

        [Parameter(Mandatory=$false)]
        [string[]]
        $IgnoreTestNames,

        [Parameter(Mandatory=$false)]
        [string]
        $TestClassNamePrefix  
    )

    if ($TestNames) {
        $testFilter = { $_.$ColumnTestName -in $TestNames }
    } else {
        $testFilter = { $_.$ColumnTestName -notin $IgnoreTestNames }
    }

    $data = Get-Content "$CsvInputFilePath" -ReadCount 0 | ConvertFrom-CSV | Where-Object $testFilter

    $xmlWriter = New-Object System.Xml.XmlTextWriter($OutputFilePath, $null)
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $xmlWriter.IndentChar = "`t"
    $xmlWriter.WriteStartDocument()
    $xmlWriter.WriteStartElement('testsuite')
    $xmlWriter.WriteAttributeString('name', $TestSuiteName)
    $xmlWriter.WriteAttributeString('file', (Split-Path -Leaf $CsvInputFilePath))

    foreach ($dataObj in $data) {
        $xmlWriter.WriteStartElement('testcase')
        $xmlWriter.WriteAttributeString('classname', ("{0}{1}" -f $TestClassNamePrefix, $dataObj.$ColumnTestName))
        $xmlWriter.WriteAttributeString('name', $dataObj.$ColumnTestName)
        $xmlWriter.WriteAttributeString('time', $dataObj.$ColumnTestTime)
        $failureValue = [decimal]($dataObj.$ColumnTestFailure -replace '%', '')
        if ($failureValue -gt $FailureThreshold) {
            $xmlWriter.WriteStartElement('failure')
            $xmlWriter.WriteAttributeString('type', "Failure threshold exceeded ($failureValue)")
            $xmlWriter.WriteEndElement()
        }
        $xmlWriter.WriteEndElement()
    }

    # close 'testsuite'
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()
}