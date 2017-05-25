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

function New-ZapReport {
    <#
    .SYNOPSIS
    Generates ZAP report.
    
    .PARAMETER ApiKey
    Api key which it was run with ZAP.

    .PARAMETER ReportFilePath
    Path to report file.

    .PARAMETER Port
    Zap port. Overrides the port used for proxying specified in the configuration file.

    .PARAMETER MinimalFailureThreshold
    Can be 'High', 'Medium', 'Low'. The test will fail when there is at least one alert of given risk level (or higher).

    .EXAMPLE
    New-ZapReport -ReportFilePath "ZAP/zap.html" -ApiKey 12345 -Port 8080
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ReportFilePath,
        
        [Parameter(Mandatory=$false)]
        [string]
        $ApiKey = '12345',

        [Parameter(Mandatory=$false)]
        [int]
        $Port = 8080,

        [Parameter(Mandatory=$false)]
        [string]
        $MinimalFailureThreshold
    )

    Write-Log -Info "ZAP creating report."

    $dir = Split-Path -Path $ReportFilePath -Parent
    if ($dir -and !(Test-Path -Path $dir)) {
        New-Item -Path $dir -ItemType Directory
    }
        
    $reportUrl = "http://zap/OTHER/core/other/htmlreport/?apikey=$ApiKey"

    Invoke-WebRequestWrapper $reportUrl -OutFile $ReportFilePath -Proxy "http://localhost:$Port"
        
    $dict = @{}
    $dict.Add('High',3)
    $dict.Add('Medium',2)
    $dict.Add('Low',1)
    
    if($MinimalFailureThreshold) {

        $MinimalFailureCode = $dict[$MinimalFailureThreshold]

        $xmlReportUrl = "http://zap/OTHER/core/other/xmlreport/?apikey=$ApiKey"
        $xmlResponse = Invoke-WebRequestWrapper $xmlReportUrl -Proxy "http://localhost:$Port"
        $alertsCount = ([xml]$xmlResponse.Content).SelectNodes("//alertitem[riskcode>=$MinimalFailureCode]").Count
        if($alertsCount -gt 0) {
            Write-Output ("##teamcity[buildProblem description='One or more alerts of risk {0} (or higher) were found.']" -f $MinimalFailureThreshold)
        }
    }
}