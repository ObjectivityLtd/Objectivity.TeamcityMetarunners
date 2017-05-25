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
function New-JMeterDetailedReport {
    <#
    .SYNOPSIS
    Takes input JMeter JTL file and generates a html report using one of JMeter's builtin xsl.

    .PARAMETER JMeterDir
    Path to JMeter directory.

    .PARAMETER InputJtlFilePath
    Path to the input JTL file.

    .PARAMETER OutputDir
    Directory where the output HTML file will be generated.

    .PARAMETER DetailReport
    If true, 'detailed' xslt will be used for more detailed report.

    .EXAMPLE
    New-JMeterDetailedReport -JMeterDir "c:\workspace\TeamCityLibraries\JMeterIntegration\lib\apache-jmeter-2.11" `
        -InputJtlFilePath "C:\workspace\TeamCityLibraries\JMeterIntegration\test\visualizer.jtl" `
        -DetailReport
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $JMeterDir,

        [Parameter(Mandatory=$true)]
        [string]
        $InputJtlFilePath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutputDir,

        [Parameter(Mandatory=$false)]
        [switch]
        $DetailReport
        
    )

    if (!(Test-Path -LiteralPath $OutputDir)) {
        Write-Log -Info "Creating directory '$OutputDir'"
        [void](New-Item -Path $OutputDir -ItemType Directory)
    }

    $OutputFilePath = Join-Path -Path $OutputDir -ChildPath "JMeter-DetailedReport.html"

    if ($DetailReport) {
        $xslPath = Join-Path -Path $JMeterDir -ChildPath "extras\jmeter-results-detail-report_21.xsl"
    } else {
        $xslPath = Join-Path -Path $JMeterDir -ChildPath "extras\jmeter-results-report_21.xsl"
    }

    if (!(Test-Path -LiteralPath $xslPath)) {
        throw "Cannot find JMeter's xsl at '$xslPath'. Please ensure you have provided correct JMeterDir."
    }

    if (!(Test-Path -LiteralPath $InputJtlFilePath)) {
        throw "Cannot find input JTL file at '$InputJtlFilePath'."
    }

    Write-Log -Info "Generating JMeter detailed report for '$InputJtlFilePath' at '$OutputFilePath'"
    Remove-Item -LiteralPath $OutputFilePath -Force -ErrorAction SilentlyContinue
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($xslPath)
    $xslt.Transform($InputJtlFilePath, $OutputFilePath) 
}