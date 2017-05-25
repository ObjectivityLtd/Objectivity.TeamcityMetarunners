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

function Invoke-CopyFilesMetaRunner {
    <#
    .SYNOPSIS
        A helper for TeamCity MetaRunner that copies files locally.

    .PARAMETER Path
        The file or directory path that should be copied locally or uploaded to remote server.

    .PARAMETER Destination
        The path where the file will be saved to (must be directory).

    .PARAMETER Include
        The files to be included in copying.

    .PARAMETER Exclude
        The files to be excluded from copying.

    .PARAMETER ClearDestination
        If $true then all content from $Destination will be deleted.

    .EXAMPLE            
        Invoke-CopyFilesMetaRunner -Path c:\temp\test.exe -Destination c:\temp\

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]
        $Path,
       
        [Parameter(Mandatory = $true)]
        [string]
        $Destination,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Include,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Exclude,

        [Parameter(Mandatory = $false)]
        [switch]
        $ClearDestination = $false
    )

    if ($ClearDestination -and (Test-Path -LiteralPath $Destination)) { 
        Write-Log -Info "Deleting '$Destination'."
        [void](Remove-Item -LiteralPath $Destination -Force -Recurse)
    }

    $newPaths = New-Object System.Collections.ArrayList
    foreach ($p in $Path) {
        if (Test-Path -LiteralPath $p -PathType Container) {
            # we need to do this or otherwise we would get a new directory in $Destination
            [void]($newPaths.Add((Join-Path -Path $p -ChildPath '*')))
        } else {
            [void]($newPaths.Add($p))
        }
    }

    Write-Log -Info ("Copying '{0}' to '{1}'" -f ($Path -join ', '), $Destination)
    [void](New-Item -Path $Destination -ItemType 'Directory' -Force)
    $params = @{
        Path = $newPaths
        Destination = $Destination
        Force = $true
        Recurse = $true
    }
    if ($Include) {
        $params.Include = $Include
    }
    if ($Exclude) {
        $params.Exclude = $Exclude
    }

    Copy-Item @params
}