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

function Start-JMeter {

    <#
    .SYNOPSIS
    Starts JMeter and, depending on RunInBackground parameters, either waits until it finishes or exits immediately.

    .PARAMETER JMeterDir
    Path to root JMeter directory.

    .PARAMETER JmxInputFile
    Input file to run (JMX).

    .PARAMETER JtlOutputFile
    Output file that will be created by JMeter (JTL).

    .PARAMETER JavaPath
    Optional path to java.exe that will be used by JMeter.

    .PARAMETER JMeterProperties
    Additional JMeter properties (e.g. aaa=bbb will be passed to JMeter command line as -Jxxx=yyy)

    .PARAMETER JMeterAdditionalCommandLineParams
    Additional string that will be passed to the JMeter command line.

    .PARAMETER RunInBackground
    If true, jmeter will be run in background and this function will return JMeter process id.

    .PARAMETER RunInBackgroundStdOutFile
    If RunInBackground, this file will contain stdout of jmeter.bat.

    .PARAMETER RunInBackgroundStdErrFile
    If RunInBackground, this file will contain stderr of jmeter.bat.

    .PARAMETER JMeterPidFile
    If specified, a file will be created at this path, that contains JMeter Process ID.

    .PARAMETER NonGUI
    If specified, jemeter will be run in NonGUI mode. It will be listening on specific port (default: 4445) for Shutdown and StopTestNow messages.

    .EXAMPLE
    Start-JMeter -JMeterDir "c:\apache-jmeter-2.11\bin" -JmxInputFile "c:\apache-jmeter-2.11\bin\test.jmx" `
        -JtlOutputFile "c:\workspace\test.jtl" -JMeterProperties @('host=localhost', 'threads=1', 'loops=1')
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $JMeterDir,

        [Parameter(Mandatory=$true)]
        [string]
        $JmxInputFile,

        [Parameter(Mandatory=$true)]
        [string]
        $JtlOutputFile,

        [Parameter(Mandatory=$false)]
        [string]
        $JavaPath,

        [Parameter(Mandatory=$false)]
        [string[]]
        $JMeterProperties,

        [Parameter(Mandatory=$false)]
        [string]
        $JMeterAdditionalCommandLineParams,

        [Parameter(Mandatory=$false)]
        [switch]
        $RunInBackground,

        [Parameter(Mandatory=$false)]
        [string]
        $RunInBackgroundStdOutFile,

        [Parameter(Mandatory=$false)]
        [string]
        $RunInBackgroundStdErrFile,

        [Parameter(Mandatory=$false)]
        [string]
        $JMeterPidFile,

        [Switch]
        [Parameter(Mandatory=$false)]
        $NonGUI = $true
    )

    if (!(Test-Path -LiteralPath $JMeterDir)) {
        throw "Cannot find JMeter directory at '$JMeterDir'."
    }
    if (!(Test-Path -LiteralPath $JmxInputFile)) {
        throw "Cannot find JMX input file at '$JmxInputFile'."
    }

    if (Test-Path -LiteralPath $JtlOutputFile) {
        Write-Log -Info "Output file '$JtlOutputFile' exists - deleting."
        Remove-Item -LiteralPath $JtlOutputFile -Force
    }

    if (Test-Path -LiteralPath $RunInBackgroundStdOutFile) {
        Write-Log -Info "Stdout file '$RunInBackgroundStdOutFile' exists - deleting."
        Remove-Item -LiteralPath $RunInBackgroundStdOutFile -Force
    }

    if (Test-Path -LiteralPath $RunInBackgroundStdErrFile) {
        Write-Log -Info "Stdout file '$RunInBackgroundStdErrFile' exists - deleting."
        Remove-Item -LiteralPath $RunInBackgroundStdErrFile -Force
    }

    $jMeterPath = Join-Path -Path $JMeterDir -ChildPath "bin\jmeter.bat"
    if (!(Test-Path -LiteralPath $jMeterPath)) {
       throw "Cannot find '$jMeterPath'."
    }

    if ($JavaPath) {
       Write-Log -Info "Setting environment variable (process-scoped) JM_LAUNCH to '$JavaPath'"
       [Environment]::SetEnvironmentVariable("JM_LAUNCH", $JavaPath, "Process")
    }

    if ($NonGUI) {
        $cmdArgs = "-n "
    }

    $cmdArgs += "-t `"$JmxInputFile`" -l `"$JtlOutputFile`""
    foreach ($prop in $JMeterProperties) {
        $cmdArgs += " -J$prop"
    }

    if ($JMeterAdditionalCommandLineParams) {
        $cmdArgs += " $JMeterAdditionalCommandLineParams"
    }

    if (!$RunInBackground) {
        Write-ProgressExternal -Message 'Running JMeter'
        [void](Start-ExternalProcess -Command $jmeterPath -ArgumentList $cmdArgs)
        Write-ProgressExternal -Message ''
    } else {
        $params = @{
            'FilePath' = $jmeterPath
            'ArgumentList' = $cmdArgs
            'StdOutFilePath' = $RunInBackgroundStdOutFile
            'StdErrFilePath' = $RunInBackgroundStdErrFile
            'PidFilePath' = $JMeterPidFile
        }

        [void](Start-ExternalProcessAsynchronously @params)

    }

}