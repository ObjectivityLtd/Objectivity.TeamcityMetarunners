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

function Invoke-CopyDownloadFilesMetaRunner {
    <#
    .SYNOPSIS
        A helper for TeamCity MetaRunner that downloads files.

    .PARAMETER Path
        The file or directory path that should be copied locally or downloaded from remote server.

    .PARAMETER ConnectionParams
        Connection parameters created by [[New-ConnectionParameters]] function.

    .PARAMETER Destination
        The path where the file will be saved to (must be directory).

    .PARAMETER Include
        The files to be included in copying.

    .PARAMETER Exclude
        The files to be excluded from copying.

    .PARAMETER ClearDestination
        If $true then all content from $Destination will be deleted.

    .EXAMPLE            
        Invoke-CopyDownloadFilesMetaRunner -Path c:\temp\test.exe -Destination c:\temp\ -ConnectionParams (New-ConnectionParameters -Nodes 'remote-server.com')

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true)]
        [object]
        $ConnectionParams,
        
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

    if ($ConnectionParams.Nodes) {
        Copy-FilesFromRemoteServer -RemotePath $path -ConnectionParams $ConnectionParams -Destination $Destination -Include $Include -IncludeRecurse -Exclude $Exclude -ExcludeRecurse -ClearDestination:$ClearDestination
    } else {
        Invoke-CopyFilesMetaRunner -Path $path -Destination $Destination -Include $Include -Exclude $Exclude -ClearDestination:$ClearDestination
    }
}