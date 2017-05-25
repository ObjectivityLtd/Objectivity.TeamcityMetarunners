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

function Invoke-ConvertSqlToTeamCityTestsMetaRunner {
    <#
    .SYNOPSIS
    On given database executes given sql query and pass result dataset into Convert-DataToTeamCityTest function.

    .PARAMETER DatabaseServer
    Name of database server.

    .PARAMETER DatabaseName
    Name of database.

    .PARAMETER PredefinedQuery
    If one of the predefined query is choosen, the Sql query parameter would be ignored.
    Otherwise only sql query will be taken into consideration.

    .PARAMETER TrxFolderOrFilePath
    Path to the trx (xml) file, which contains RunGuid. When specified, then RunGuid from the file will be taken as a parameter to sql predefined query.

    .PARAMETER Query
    Sql query to execute.
    Only used if predefinedQuery parameter is not specified.

    .PARAMETER IntegratedSecurity
    If true, Windows Authentication will be used. SQL Server Authentication otherwise.

    .PARAMETER Username
    Username - leave empty for domain agent credentials.

    .PARAMETER Password
    Password - leave empty for domain agent credentials.

    .PARAMETER ColumnTestName
    Column indicates the name of the test.

    .PARAMETER ColumnsToReportAsTests
    List of columns that will be reported as TeamCity tests (each column will be mapped to one category).
    For example, if $ColumnsToReportsAsTests = @('average','median') and you have tests 'x', 'y', there will be
    tests average.x, average.y, median.x, median.y

    .EXAMPLE
    Invoke-ConvertSqlToTeamCityTestsMetaRunner -DatabaseServer 'localhost' -DatabaseName 'LoadTest2010' -IntegratedSecurity `
    -ColumnTestName 'Name' -ColumnsToReportAsTests 'Average', 'Minimum', 'Maximum' -Query $sql
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $DatabaseServer,

        [Parameter(Mandatory=$false)]
        [string]
        $DatabaseName,

        [Parameter(Mandatory=$false)]
        [string]
        $PredefinedQuery,
        
        [parameter(Mandatory=$false)]
        [string]
        $TrxFolderOrFilePath,

        [Parameter(Mandatory=$false)]
        [string]
        $Query,

        [Parameter(Mandatory=$false)]
        [switch]
        $IntegratedSecurity,

        [Parameter(Mandatory=$false)]
        [string]
        $Username,

        [Parameter(Mandatory=$false)]
        [string]
        $Password,

        [Parameter(Mandatory=$true)]
        [string]
        $ColumnTestName,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ColumnsToReportAsTests
    )

    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder["Data Source"] = $DatabaseServer
    if ($DatabaseName) {
        $builder["Initial Catalog"] = $DatabaseName
    }

    $credential = $null
    if ($IntegratedSecurity) {
        $builder["Integrated Security"] = $true
        if ($Username) {
            $credential = ConvertTo-PSCredential -User $Username -Password $Password
        }
    } else {
        $builder["User ID"] = $Username
        $builder["Password"] = $Password
    }

    $params = @{
        'ConnectionString' = $builder.ConnectionString
    }
    if ($credential) {
        $params['Credential'] = $credential
    }

    if ($PredefinedQuery) {
        if ($TrxFolderOrFilePath) {
            $testRunGuid = Get-TestRunGuidFromTrxFile -TrxFolderOrFilePath $TrxFolderOrFilePath

            $loadTestVisualizerPath = $TrxFolderOrFilePath + "\LoadTestVisualizer.html"
            if (Test-Path -PathType Leaf -Path $loadTestVisualizerPath) {
                Clear-Content $loadTestVisualizerPath

                ("<script>location='http://objplntc/ltv/home/index/{0}'</script>'" -f $testRunGuid) >> $loadTestVisualizerPath
            }
        }
        $predefinedSqlQuery = Get-PredefinedSqlQuery -PredefinedQueryName $PredefinedQuery -TestRunGuid $testRunGuid
        $params['Query'] = $predefinedSqlQuery
    } elseif ($Query) {
        $params['Query'] = $Query
    }

    $sqlResult = Invoke-Sql @params
    $sqlResultTable = $sqlResult.Tables[0]

    Convert-DataToTeamCityTest -InputData $sqlResultTable -ColumnTestName $ColumnTestName -ColumnsToReportAsTests $ColumnsToReportAsTests
}