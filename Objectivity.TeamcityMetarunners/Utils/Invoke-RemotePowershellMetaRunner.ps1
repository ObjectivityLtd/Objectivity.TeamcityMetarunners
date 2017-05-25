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

function Invoke-RemotePowershellMetaRunner {

    <#
    .SYNOPSIS
    A helper for TeamCity MetaRunner that invokes powershell code remotely or locally on different credentials.
    
    .PARAMETER ScriptFile
    Path to local / remote (depending on $ScriptFileIsRemotePath) file(s) containing Powershell script to invoke remotely. If $null, $ScriptBody will be used.

    .PARAMETER ScriptBody
    Body of Powershell script to invoke remotely. If $null, $ScriptFile will be used.

    .PARAMETER ScriptArguments
    Arguments that will be passed to the ScriptFile.

    .PARAMETER ScriptFileIsRemotePath
    If true, $ScriptFile will mean the scripts are on remote hosts.
    
    .PARAMETER ConnectionParams
    Connection parameters created by [[New-ConnectionParameters]] function.

    .PARAMETER FailOnNonZeroExitCode
    If true, script will automatically fail on non-zero exit code.

    .EXAMPLE
      $params = @{
        'DatabaseServer' = '%sqlRun.databaseServer%';
        'DatabaseName' = '%sqlRun.databaseName%';
        'Action' = '%sqlRun.action%';
        'IntegratedSecurity' = %sqlRun.integratedSecurity%;
        'Username' = '%sqlRun.username%';
        'Password' = '%sqlRun.password%';
        'TimeoutInSeconds' = '%sqlRun.timeout%';
      }

      Invoke-RemotePowershellMetaRunner -ScriptBody "Write-Host 'Hello'" -ConnectionParams (New-ConnectionParameters)
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]
        $ScriptFile,

        [Parameter(Mandatory=$false)]
        [string]
        $ScriptBody,

        [Parameter(Mandatory=$false)]
        [string[]]
        $ScriptArguments,

        [Parameter(Mandatory=$false)]
        [switch]
        $ScriptFileIsRemotePath,

        [Parameter(Mandatory=$true)]
        [object]
        $ConnectionParams,

        [Parameter(Mandatory=$false)]
        [switch]
        $FailOnNonZeroExitCode = $true
    )

    if (!$ScriptFile -and !$ScriptBody) {
        throw 'You need to specify either script filename or script body.'
    }

    if ($ScriptFile -and $ScriptBody) {
        throw 'You cannot specifiy both script filename and script body.'
    }

    if ($ScriptFile) {
        if ($ScriptFileIsRemotePath) { 

            $scriptToRun = { 
                param ($scriptFile, $scriptArgs, $failOnNonZeroExitCode)

                $Global:ErrorActionPreference = 'Stop'

                foreach ($file in $scriptFile) {
                    if (!(Test-Path -LiteralPath $file)) {
                        throw "File '$file' does not exist at $([system.environment]::MachineName)."
                    }
                }
                foreach ($file in $scriptFile) {
                    . $file $scriptArgs
                }

                if ($failOnNonZeroExitCode) {
                    if ($global:LASTEXITCODE) { throw "Exit code: $($global:LASTEXITCODE)" }
                }
            }
            $cmdParams = @{ 
                ScriptBlock = $scriptToRun
                ArgumentList = @($ScriptFile, $ScriptArguments, $FailOnNonZeroExitCode)
            }
            $logScriptToRun = "remote file(s) $($ScriptFile -join ', ')"

        } else {
            $scriptToRun = ''
            foreach ($file in $ScriptFile) {
                if (!(Test-Path -LiteralPath $file)) {
                   throw "File '$file' does not exist at $([system.environment]::MachineName)."
                }
                $scriptToRun += Get-Content -Path $file -ReadCount 0 | Out-String
                $scriptToRun += "`n"
            }
            $logScriptToRun = "contents of local file(s) $($ScriptFile -join ', ')"
        }
    } else {
        $scriptToRun = $ScriptBody
        $logScriptToRun = 'custom powershell script'
    }

    if ($ScriptBody -or !$ScriptFileIsRemotePath) {
        if ($FailOnNonZeroExitCode) {
            $scriptToRun += "`nif (`$global:LASTEXITCODE) { throw `"Exit code: `$($global:LASTEXITCODE)`" }"
        }
        $cmdParams = @{ ScriptBlock = [Scriptblock]::Create($scriptToRun) }
        if ($ScriptArguments) {
            $cmdParams.ArgumentList = $ScriptArguments
        }
    }

    $cmdParams += $ConnectionParams.PSSessionParams

    if ($ConnectionParams.Nodes) {
        Write-Log -Info "Running $logScriptToRun on $($ConnectionParams.NodesAsString), $($ConnectionParams.OptionsAsString), failOnNonZeroExitCode:$FailOnNonZeroExitCode."
    } else {
        $global:LASTEXITCODE = $null
        Write-Log -Info "Running $logScriptToRun on localhost, failOnNonZeroExitCode:$FailOnNonZeroExitCode."
    }

    Invoke-Command @cmdParams
}