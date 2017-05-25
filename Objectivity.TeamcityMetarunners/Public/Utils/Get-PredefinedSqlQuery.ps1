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

function Get-PredefinedSqlQuery {
    <#
    .SYNOPSIS
    Returns one of the predefined query. If query with given name does not exists, throws an exception.

    .PARAMETER PredefinedQueryName
    Name of the predefined query.

    .PARAMETER TestRunGuid
    Data for given test run guid will be taken from database.

    .EXAMPLE
    Get-PredefinedSqlQuery -PredefinedQueryName 'LoadTestVisualStudioQuery'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $PredefinedQueryName,

        [Parameter(Mandatory=$false)]
        [string]
        $TestRunGuid
    )

    $resultQuery = $null

    if ($PredefinedQueryName -eq 'LoadTestVisualStudioQuery'){
        if (!$TestRunGuid){
            throw "Parameter TestRunGuid was not specified but was needed, when Predefined query name is equal to $PredefinedQueryName. Please check given name."
        }

        $resultQuery = @'
        DECLARE @localRunId varchar(50) = 
'@ + "'" + $TestRunGuid + "'" + @'
         
      SELECT 'Request' AS Type,
            pageSummary.LoadTestRunId,
            scenario.ScenarioName,
            testCase.TestCaseName,
            requestMap.RequestUri AS Name,
            pageSummary.PageCount AS Count,
            pageSummary.Minimum,
            pageSummary.Average,
            pageSummary.Percentile90,
            pageSummary.Percentile95,
            pageSummary.Maximum,
            ( H2.COUNT * 100 ) / pageSummary.PageCount AS ErrorPercentage
      FROM dbo.LoadTestPageSummaryData AS pageSummary
            INNER JOIN dbo.WebLoadTestRequestMap AS requestMap ON pageSummary.LoadTestRunId = requestMap.LoadTestRunId
               AND pageSummary.PageId = requestMap.RequestId
            INNER JOIN dbo.LoadTestCase AS testCase ON requestMap.LoadTestRunId = testCase.LoadTestRunId
               AND requestMap.TestCaseId = testCase.TestCaseId
            INNER JOIN dbo.LoadTestScenario AS scenario ON testCase.LoadTestRunId = scenario.LoadTestRunId
               AND testCase.ScenarioId = scenario.ScenarioId
            INNER JOIN [dbo].[LoadTestRun] AS loadTestRun ON scenario.LoadTestRunId = loadTestRun.LoadTestRunId
            LEFT JOIN( 
               SELECT [LoadTestRunId],
                  [RequestId],
                  COUNT(*) AS COUNT
                  FROM [LoadTest2010].[dbo].[LoadTestMessage]
                  GROUP BY [LoadTestRunId],
                           [RequestId] ) H2 ON scenario.LoadTestRunId = H2.LoadTestRunId
                           AND requestMap.RequestId = H2.RequestId
       WHERE loadTestRun.RunId = @localRunId
       UNION ALL
       SELECT 'Transaction',
            transactionSummary.LoadTestRunId,
            scenario.ScenarioName,
            testCase.TestCaseName,
            transactions.TransactionName AS Name,
            transactionSummary.TransactionCount AS Count,
            transactionSummary.Minimum,
            transactionSummary.Average,
            transactionSummary.Percentile90,
            transactionSummary.Percentile95,
            transactionSummary.Maximum,
            NULL
       FROM dbo.LoadTestTransactionSummaryData AS transactionSummary
            INNER JOIN dbo.WebLoadTestTransaction AS transactions ON transactionSummary.LoadTestRunId = transactions.LoadTestRunId
               AND transactionSummary.TransactionId = transactions.TransactionId
            INNER JOIN dbo.LoadTestCase AS testCase ON transactions.LoadTestRunId = testCase.LoadTestRunId
               AND transactions.TestCaseId = testCase.TestCaseId
            INNER JOIN dbo.LoadTestScenario AS scenario ON testCase.LoadTestRunId = scenario.LoadTestRunId
               AND testCase.ScenarioId = scenario.ScenarioId
            INNER JOIN [dbo].[LoadTestRun] AS loadTestRun ON scenario.LoadTestRunId = loadTestRun.LoadTestRunId
      WHERE loadTestRun.RunId = @localRunId
      UNION ALL
      SELECT 'Webtest',
            testSummary.LoadTestRunId,
            scenario.ScenarioName,
            testCase.TestCaseName AS Name,
            NULL,
            testSummary.TestsRun AS Count,
            testSummary.Minimum,
            testSummary.Average,
            testSummary.Percentile90,
            testSummary.Percentile95,
            testSummary.Maximum,
            NULL
      FROM dbo.LoadTestTestSummaryData AS testSummary
      INNER JOIN dbo.LoadTestCase AS testCase ON testSummary.LoadTestRunId = testCase.LoadTestRunId
         AND testSummary.TestCaseId = testCase.TestCaseId
      INNER JOIN dbo.LoadTestScenario AS scenario ON testCase.LoadTestRunId = scenario.LoadTestRunId
         AND testCase.ScenarioId = scenario.ScenarioId
      INNER JOIN [dbo].[LoadTestRun] AS loadTestRun ON scenario.LoadTestRunId = loadTestRun.LoadTestRunId
      WHERE loadTestRun.RunId = @localRunId;
'@

    }

    if (!$resultQuery) {
        throw "Given PredefinedQueryName '$PredefinedQueryName' does not have any implementation. Please check given name."
    }
    
    return $resultQuery;    
}