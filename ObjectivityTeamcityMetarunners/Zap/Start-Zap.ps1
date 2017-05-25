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

function Start-Zap {
    <#
    .SYNOPSIS
    Starts ZAP process.
        
    .PARAMETER ZAPDir
    Path to root ZAP directory.
    
    .PARAMETER ZAPProperties
    List of properties which ZAP should be run.

    .PARAMETER StdOutFilePath
    If specified, stdout will be sent to this filename.

    .PARAMETER StdErrFilePath
    If specified, stderr will be sent to this filename.

    .PARAMETER PidFilePath
    If specified, PID of the process will be sent to this filename (it can be later killed with Stop-ProcessForcefully).

    .PARAMETER ApiKey
    Api key which it was run with ZAP.

    .PARAMETER StartTimeout
    How many second to wait for Zap to start up.

    .PARAMETER ConnectionTimeout
    Zap connection timeout.

    .PARAMETER Port
    Zap port. Overrides the port used for proxying specified in the configuration file.

    .EXAMPLE
    Start-ZAP -ZAPDir 'C:\ZAP\' -ApiKey '12345' -ConnectionTimeout 60
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ZAPDir,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ZAPProperties,

        [Parameter(Mandatory=$false)]
        [string]
        $StdOutFilePath = "zapstdout.txt",

        [Parameter(Mandatory=$false)]
        [string]
        $StdErrFilePath = "zapstderr.txt",

        [Parameter(Mandatory=$false)]
        [string]
        $PidFilePath = "zappid.txt",

        [Parameter(Mandatory=$false)]
        [string]
        $ApiKey = 12345,

        [Parameter(Mandatory=$false)]
        [int]
        $StartTimeout = 60,
       
        [Parameter(Mandatory=$false)]
        [int]
        $ConnectionTimeout = 60,

        [Parameter(Mandatory=$false)]
        [int]
        $Port = 8080
    )

    if (!(Test-Path -LiteralPath $ZAPDir)) {
        throw "Cannot find ZAP directory at '$ZAPDir'."
    }    

    $cmdArgs = "-daemon "
    $cmdArgs += "-config api.key=$ApiKey "
    $cmdArgs += "-config connection.timeoutInSecs=$ConnectionTimeout "
    $cmdArgs += "-port $Port "
    $cmdArgs += $ZAPProperties -Join ' '

    $ZAPPath = Join-Path -Path $ZAPDir -ChildPath "ZAP.bat"
    if (!(Test-Path -LiteralPath $ZAPPath)) {
       throw "Cannot find '$ZAPPath'."
    }

    $params = @{
        'FilePath' = $ZAPPath
        'WorkingDirectory' = $ZAPDir
        'ArgumentList' = $cmdArgs
        'StdOutFilePath' = $StdOutFilePath
        'StdErrFilePath' = $StdErrFilePath
        'PidFilePath' = $PidFilePath
    }

    [void](Start-ExternalProcessAsynchronously @params)

    $status = @()
    $timeout = New-TimeSpan -Seconds $StartTimeout
    $sw = [Diagnostics.StopWatch]::StartNew()
 
    
    
    $loadedMessage = '*Initializing Tips and Tricks*';
    #$loadedMessage = '*ZAP is now listening on*'; TODO: uncomment when zap release contains a fix to output this message https://github.com/zaproxy/zaproxy/issues/2063
    while (($status -like $loadedMessage).length -eq 0 ) {
       if ($sw.elapsed -ge $timeout) {
          throw "Zap timed out after '$timeout'."
        }
        $status = Get-Content -Path $StdOutFilePath -ReadCount 1 -Tail 5
        Start-Sleep -Milliseconds 200
    }

    # TODO: remove when zap release contains a fix to output this message https://github.com/zaproxy/zaproxy/issues/2063
    Start-Sleep -s 5

    Write-Log -Info "ZAP ready."
}