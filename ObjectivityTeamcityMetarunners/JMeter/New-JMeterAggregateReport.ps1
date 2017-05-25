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

function New-JMeterAggregateReport {
    <#
    .SYNOPSIS
    Takes input JMeter JTL file (and optionally PerfMon CSV) and generates aggregate report in html format (JMeter-AggregateReport.html).

    .DESCRIPTION
    It runs the following:
    1) Generate AggregateReport in csv format (using JMeterPluginsCMD - generates Aggregate Report in csv format).
    2) Generate other reports (specified in ImagesToGenerate) in png format.
    3) Create html report basing on the output generated in the steps above.

    .PARAMETER JMeterDir
    Path to JMeter directory.

    .PARAMETER InputJtlFilePath
    Path to the input JTL file.

    .PARAMETER OutputDir
    Output directory where .html / .png / .csv files will be generated.

    .PARAMETER InputPerfMonFilePath
    Path to the input PerfMon file (optional).

    .PARAMETER JavaPath
    Optional path to java.exe that will be used by JMeter CMDRunner.
    
    .PARAMETER WarningThresholds
    String containing warning thresholds for each column. For example if $WarningThresholds = 'Average=3000,Max=30000,Error %=0', 
    samples with Average > 3000, Max > 30000 or Error % > 0 will be marked red in the output html.

    .PARAMETER TimeoutInSeconds
    Timeout to wait for external process (CMDRunner) to be finished.

    .PARAMETER CustomCMDRunnerCommandLines
    List of custom command line parameters - each will be passed to a separate invocation of CMDRunner.

    .EXAMPLE
    New-JMeterAggregateReport -JMeterDir "c:\workspace\TeamCityLibraries\JMeterIntegration\lib\apache-jmeter-2.11" `
        -InputJtlFilePath "C:\workspace\TeamCityLibraries\JMeterIntegration\test\visualizer.jtl" `
        -InputPerfMonFilePath "C:\workspace\TeamCityLibraries\JMeterIntegration\test\perfmon.csv" `
        -OutputDir "C:\workspace\TeamCityLibraries\JMeterIntegration\ReportOutput" 
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
        [string]
        $InputPerfMonFilePath,

        [Parameter(Mandatory=$false)]
        [string]
        $JavaPath,
       
        [Parameter(Mandatory=$false)]
        [string]
        $WarningThresholds = 'Average=3000,Median=3000,90% Line=3000,Max=30000,Error %=0',

        [Parameter(Mandatory=$false)]
        [int]
        $TimeoutInSeconds,

        [Parameter(Mandatory=$false)]
        [string[]]
        $CustomCMDRunnerCommandLines = @(
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\ResponseTimesOverTime.png" --plugin-type ResponseTimesOverTime --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\BytesThroughputOverTime.png" --plugin-type BytesThroughputOverTime --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\LatenciesOverTime.png" --plugin-type LatenciesOverTime --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\ResponseCodesPerSecond.png" --plugin-type ResponseCodesPerSecond --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\ResponseTimesDistribution.png" --plugin-type ResponseTimesDistribution --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\ResponseTimesPercentiles.png" --plugin-type ResponseTimesPercentiles --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\TransactionsPerSecond.png" --plugin-type TransactionsPerSecond --width 667 --height 500',
            '--input-jtl "{jtlPath}" --generate-png "{outputDir}\ThreadsStateOverTime.png" --plugin-type ThreadsStateOverTime --width 667 --height 500',
            '--input-jtl "{perfMonPath}" --generate-png "{outputDir}\PerfMon.png" --plugin-type PerfMon --width 667 --height 500'
        )

    )

    if (!(Test-Path -LiteralPath $OutputDir)) {
        Write-Log -Info "Creating directory '$OutputDir'"
        [void](New-Item -Path $OutputDir -ItemType Directory)
    }

    if (!$JavaPath) {
        $JavaPath = 'java.exe'
    }

    $aggregateCsvOutputPath = Join-Path -Path $OutputDir -ChildPath 'JMeter-AggregateReport.csv'
    $aggregateHtmlOutputPath = Join-Path -Path $OutputDir -ChildPath 'JMeter-AggregateReport.html'
    New-JMeterAggregateData -JMeterDir $JMeterDir -InputFilePath $InputJtlFilePath -OutputFormat 'csv' -PluginType 'AggregateReport' -OutputFilePath $aggregateCsvOutputPath -JavaPath $JavaPath

    if ($CustomCMDRunnerCommandLines) {
        $cmdRunnerPath = Join-Path -Path $JMeterDir -ChildPath "lib\ext\CMDRunner.jar"
        if (!(Test-Path -LiteralPath $cmdRunnerPath)) {
            throw "Cannot find JMeter CMDRunner plugin at '$cmdRunnerPath'."
        }

        $replaceStrings = @{
            'jtlPath' = $InputJtlFilePath
            'outputDir' = $OutputDir
            'perfMonPath' = $InputPerfMonFilePath
        }

        foreach ($cmdLine in $CustomCMDRunnerCommandLines) {
            $shouldRun = $true
            foreach ($replaceString in $replaceStrings.Keys) {
                if ($cmdLine -imatch "\{$replaceString\}") {
                    $value = $replaceStrings[$replaceString]
                    if (!$value) {
                        $shouldRun = $false
                        Write-Log -Warn "Command line '$cmdLine' will not run - {$replaceString} is specified but related parameter is not."
                        break
                    } elseif (!(Test-Path -LiteralPath $value)) {
                        $shouldRun = $false
                        Write-Log -Warn "Command line '$cmdLine' will not run - path '$value' does not exist."
                        break
                    } else { 
                        $cmdLine = $cmdLine -ireplace "\{$replaceString\}", $value
                    }
                }
            }
            if ($shouldRun) { 
                $cmdArgs = "-jar `"$cmdRunnerPath`" --tool Reporter $cmdLine"
                [void](Start-ExternalProcess -Command $javaPath -ArgumentList $cmdArgs -TimeoutInSeconds $TimeoutInSeconds)
            }
        }
    }

    if ($WarningThresholds) {
        $warningThresholdsValues = @{}
        foreach ($warnThreshold in ($WarningThresholds -split ',')) {
            $warnThrSplit = $warnThreshold -split '='
            $warningThresholdsValues += @{ $warnThrSplit[0] = $warnThrSplit[1] }
        }

    }

    $params = @{'As'='Table';
            'PreContent'='<h2>Aggregate report</h2>';
            'MakeTableDynamic'=$true;
            'IsTotalRow'={ $_.sampler_label -eq 'TOTAL' };
            'Properties'=
                "_ROWNUM_", 
                @{n='Sampler';e={$_.sampler_label}; css={"alignLeft"}},
                @{n='Count';e={$_.aggregate_report_count}},
                @{n='Average';e={$_.average};
                    css={if ($warningThresholdsValues.ContainsKey('Average') -and (ConvertTo-Decimal -Value $_.average) -gt $warningThresholdsValues['Average']) { 'warning' }}},
                @{n='Median';e={$_.aggregate_report_median};
                    css={if ($warningThresholdsValues.ContainsKey('Median') -and (ConvertTo-Decimal -Value $_.aggregate_report_median) -gt $warningThresholdsValues['Median']) { 'warning' }}},
                @{n='90% Line';e={$_.'aggregate_report_90%_line'};
                    css={if ($warningThresholdsValues.ContainsKey('90% Line') -and (ConvertTo-Decimal -Value $_.'aggregate_report_90%_line') -gt $warningThresholdsValues['90% Line']) { 'warning' }}},
                @{n='Min';e={$_.aggregate_report_min};
                    css={if ($warningThresholdsValues.ContainsKey('Min') -and (ConvertTo-Decimal -Value $_.aggregate_report_min) -gt $warningThresholdsValues['Min']) { 'warning' }}},
                @{n='Max';e={$_.aggregate_report_max};
                    css={if ($warningThresholdsValues.ContainsKey('Max') -and (ConvertTo-Decimal -Value $_.aggregate_report_max) -gt $warningThresholdsValues['Max']) { 'warning' }}},
                @{n='Error %';e={$_.'aggregate_report_error%'};
                    f="{0:P2}"
                    css={if ($warningThresholdsValues.ContainsKey('Error %') -and (ConvertTo-Decimal -Value $_.'aggregate_report_error%') -gt ($warningThresholdsValues['Error %'] / 100)) { 'warning' }}},
                @{n='Rate';e={$_.aggregate_report_rate}; 
                           f="{0:F2}"
                           css={if ($warningThresholdsValues.ContainsKey('Rate') -and (ConvertTo-Decimal -Value $_.aggregate_report_rate) -gt $warningThresholdsValues['Rate']) { 'warning' }}},
                @{n='Bandwidth';
                        e={$_.aggregate_report_bandwidth}; 
                        f="{0:F2}"
                        css={if ($warningThresholdsValues.ContainsKey('Bandwidth') -and (ConvertTo-Decimal -Value $_.aggregate_report_bandwidth) -gt $warningThresholdsValues['Bandwidth']) { 'warning' }}},
                @{n='StdDev';
                        e={$_.aggregate_report_stddev}; 
                        f="{0:F2}"
                        css={if ($warningThresholdsValues.ContainsKey('StdDev') -and (ConvertTo-Decimal -Value $_.aggregate_report_stddev) -gt $warningThresholdsValues['StdDev']) { 'warning' }}}
               }
                     

    Write-Log -Info "Generating JMeter Aggregate Report from '$aggregateCsvOutputPath' and images available at '$OutputDir'" 

    $csv = Get-Content -Path $aggregateCsvOutputPath -ReadCount 0 | ConvertFrom-CSV
    # Remove '%' from column 'aggregate_report_error%', and divide by 100
    if ($csv -and $csv.'aggregate_report_error%') { 
        foreach ($row in $csv) {
            if ($row.'aggregate_report_error%' -match '%') { 
                $row.'aggregate_report_error%' = $row.'aggregate_report_error%' -replace '%',''
                $decimal = ConvertTo-Decimal -Value $row.'aggregate_report_error%'
                if ($decimal) {
                    $row.'aggregate_report_error%' = $decimal / 100;
                }
            }
        }
    }

    $htmlAggregateReport = $csv | ConvertTo-EnhancedHTMLFragment @params
    $htmlImages = Get-ChildItem -Path $OutputDir -Filter *.png | Sort | Foreach-Object { ConvertTo-EnhancedHTMLFragmentImage -Header $_.BaseName -Uri $_.Name }

    $params = @{'HTMLFragments' = @($htmlAggregateReport, $htmlImages)
                'CssStyleSheet' = (Get-DefaultJqueryDataTableCss);
               }

    ConvertTo-EnhancedHTML @params | Out-File -FilePath $aggregateHtmlOutputPath -Encoding UTF8
    Write-Log -Info "JMeter Aggregate Report created at '$aggregateHtmlOutputPath'" -emphasize
}
