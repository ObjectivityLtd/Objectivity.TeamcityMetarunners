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

function New-JMeterAggregateData {
    <#
    .SYNOPSIS
    Runs JMeterPluginsCMD to generate aggregate report in png or csv format.

    .PARAMETER JMeterDir
    Path to JMeter directory.

    .PARAMETER InputFilePath
    Path to the input (JTL/PerfMon CSV) file.

    .PARAMETER OutputFormat
    Output format - png or csv.

    .PARAMETER PluginType
    Plugin type to use. For available list see http://jmeter-plugins.org/wiki/JMeterPluginsCMD/
    
    .PARAMETER JavaPath
    Path to java.exe that will be used by JMeter CMDRunner.

    .PARAMETER OutputFilePath
    Path to the output file. If not specified, the output file will be generated at InputFilePath.  
    
    .PARAMETER ImageWidth
    Width of generated image (only valid for OutputFormat = png).

    .PARAMETER ImageHeight
    Height of generated image (only valid for OutputFormat = png).

    .PARAMETER IncludeTestNames
    List of test names that should be included (only for generating PNG files).

    .PARAMETER ExcludeTestNames
    List of test names that should be excluded (only for generating PNG files).

    .EXAMPLE
    New-JMeterAggregateData -JMeterDir $JMeterDir -InputFilePath $InputJtlFilePath -OutputFormat 'csv' -PluginType 'AggregateReport' -OutputFilePath $aggregateCsvOutputPath
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $JMeterDir,

        [Parameter(Mandatory=$true)]
        [string]
        $InputFilePath,

        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet("png", "csv")]
        $OutputFormat,

        [Parameter(Mandatory=$true)]
        [string]
        $PluginType,

        [Parameter(Mandatory=$true)]
        [string]
        $JavaPath,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputFilePath,

        [Parameter(Mandatory=$false)]
        [int]
        $ImageWidth,

        [Parameter(Mandatory=$false)]
        [int]
        $ImageHeight,

        [Parameter(Mandatory=$false)]
        [string[]]
        $IncludeTestNames,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ExcludeTestNames
    )

    if (!(Test-Path -LiteralPath $JMeterDir)) {
        throw "Cannot find JMeter directory at '$JMeterDir'."
    }
    if (!(Test-Path -LiteralPath $InputFilePath)) {
        throw "Cannot find JMeter input file at '$InputFilePath'."
    }

    $cmdRunnerPath = Join-Path -Path $JMeterDir -ChildPath "lib\ext\CMDRunner.jar"
    if (!(Test-Path -LiteralPath $cmdRunnerPath)) {
       throw "Cannot find JMeter CMDRunner plugin at '$cmdRunnerPath'."
    }

    if (!$OutputFilePath) {
        $OutputFilePath = Split-Path -Parent $InputFilePath | Join-Path -ChildPath "${PluginType}.$OutputFormat"
    }

    $cmdArgs = "-jar `"$cmdRunnerPath`" --tool Reporter --generate-$OutputFormat `"$OutputFilePath`" --input-jtl `"$InputFilePath`" --plugin-type $PluginType"
    if ($OutputFormat -eq "png") {
        if ($ImageWidth) {
            $cmdArgs += " --width $ImageWidth"
        }
        if ($ImageHeight) {
           $cmdArgs += " --height $ImageHeight"
        }
    }

    if ($IncludeTestNames) {
        $cmdArgs += " --include-labels {0}" -f ($IncludeTestNames -join ',')
    }
    if ($ExcludeTestNames) {
        $cmdArgs += " --exclude-labels {0}" -f ($ExcludeTestNames -join ',')
    }

    Write-Log -Info "Generating JMeter aggregate report '$PluginType'" -emphasize
    # ignore 'Extra fields have been ignored' lines as there can be lot of them - see https://groups.google.com/forum/#!topic/jmeter-plugins/LTwLyJIJwEA
    [void](Start-ExternalProcess -Command $javaPath -ArgumentList $cmdArgs -IgnoreOutputRegex 'Extra fields have been ignored')
}
