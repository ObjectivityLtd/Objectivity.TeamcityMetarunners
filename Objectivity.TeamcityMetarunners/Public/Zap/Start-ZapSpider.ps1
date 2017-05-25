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

function Start-ZapSpider {
    <#
    .SYNOPSIS
    Starts ZAP Spider for specified url.
    
    .PARAMETER Url
    Url for which Spider should be run.
    
    .PARAMETER ApiKey
    Api key which it was run with ZAP.

    .PARAMETER Port
    Zap port. Overrides the port used for proxying specified in the configuration file.

    .PARAMETER MaxChildren
    API 'maxChildren' parameter can be set to limit the number of children scanned.

    .PARAMETER Recurse
    API 'recurse' parameter can be used to prevent the spider from seeding recursively.

    .EXAMPLE
    Start-ZapSpider -Url 'http://localhost' -ApiKey '12345' -Port 8080
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Url,

        [Parameter(Mandatory=$false)]
        [string]
        $ApiKey = '12345',

        [Parameter(Mandatory=$false)]
        [int]
        $Port = 8080,

        [Parameter(Mandatory=$false)]
        [string]
        $MaxChildren,

        [Parameter(Mandatory=$false)]
        [string]
        $Recurse
    )

    Write-Log -Info "ZAP Spider starting."
    
    $scanUrl = "http://zap/JSON/spider/action/scan/?zapapiformat=JSON&apikey=$ApiKey&url=$Url&maxChildren=$MaxChildren&recurse=$Recurse"
    $responseScan = Invoke-WebRequestWrapper -Uri $scanUrl -Method "Get" -ContentType "JSON" -Proxy "http://localhost:$Port"
    $json = $responseScan.Content | ConvertFrom-Json
    $scanId = $json.scan

    Write-Log -Info "Scan Id = $scanId."

    $status = 0
    while([int]$status -lt 100) {
        $urlGetStatusUrl = "http://zap/JSON/spider/view/status/?zapapiformat=JSON&scanId=" + $scanId
        $responseStatus = Invoke-WebRequestWrapper -Uri $urlGetStatusUrl -Method "Get" -ContentType "JSON" -Proxy "http://localhost:$Port"
        $json = $responseStatus.Content | ConvertFrom-Json
        $status = $json.status
        Write-Log -Info "Status = $status/100"
        Start-Sleep -Seconds 10
    }
    Write-Log -Info "ZAP Spider finished."
}
