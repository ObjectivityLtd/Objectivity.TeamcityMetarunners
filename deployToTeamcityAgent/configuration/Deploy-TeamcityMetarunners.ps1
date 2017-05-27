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

function Deploy-TeamcityMetarunners {

    <#
    .SYNOPSIS
    Copies TeamcityMetarunners library to remote host using blue-green deployment.

    .DESCRIPTION
    This function is invoked by PSCI deployment.
    
    .PARAMETER NodeName
    Destination node.

    .PARAMETER Environment
    Environment where the library is being deployed.

    .PARAMETER Tokens
    Tokens resolved for given environment / nodeName.

    .PARAMETER ConnectionParams
    ConnectionParameters object describing how to connect to the remote noed (see [[New-ConnectionParameters]]).

    .EXAMPLE
        Deploy-TeamcityMetarunners

#>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $NodeName,

        [Parameter(Mandatory=$true)]
        [string]
        $Environment,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Tokens,

        [Parameter(Mandatory=$true)]
        [object]
        $ConnectionParams
    )
    
    $sourcePath = Join-Path -Path ((Get-ConfigurationPaths).ProjectRootPath) -ChildPath "package.zip"

    $params = @{
        Path = $sourcePath
        ConnectionParams = $ConnectionParams
        BlueGreenEnvVariableName = $Tokens.Psci.BlueGreenEnvVariableName
        Destination = @($Tokens.Psci.DestPathBlue, $Tokens.Psci.DestPathGreen)
        ClearDestination = $true
    }

    Copy-FilesToRemoteServer @params

    $params = @{
        Path = Join-Path -Path ((Get-ConfigurationPaths).ProjectRootPath) -ChildPath 'PSCI.boot.ps1'
        ConnectionParams = $ConnectionParams
        Destination = $Tokens.Psci.DestPathBoot
        ClearDestination = $false
    }

    Copy-FilesToRemoteServer @params
    
    $blueGreenEnv = $Tokens.Psci.BlueGreenEnvVariableName
    $session = New-PsSession ($ConnectionParams.PSSessionParams)
    Write-Log -Info "Setting PSCI_PATH environment variable"
    Invoke-Command -Session $session -ScriptBlock { 
      $modulePath = [Environment]::GetEnvironmentVariable($using:blueGreenEnv, 'Machine')
      $psciPath = Get-ChildItem -Path "$modulePath\PSCI" -Directory | Select-Object -ExpandProperty FullName
      [Environment]::SetEnvironmentVariable('PSCI_PATH', $psciPath, 'Machine')
      Write-Host "PSCI_PATH set to '$psciPath'"
    }
    
    Remove-PSSession -Session $session

}
