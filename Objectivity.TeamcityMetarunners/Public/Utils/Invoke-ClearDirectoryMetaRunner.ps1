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

function Invoke-ClearDirectoryMetaRunner {
    <#
    .SYNOPSIS
        A helper for TeamCity MetaRunner that clears current directory using specified regex.

    .PARAMETER IncludeRegex
        Paths that match this regex will be deleted.

    .PARAMETER ExcludeRegex
        Paths that match this regex will be ignored.

    .PARAMETER BaseDirectory
        Root directory where the search will start. If empty, current location will be used.

    .PARAMETER ItemsToMatch
        Determins which items will be matched (FilesAndDirectories, Files or Directories).

    .PARAMETER VerboseLog
        Set to $true for verbose output.

    .EXAMPLE            
        Invoke-ClearDirectoryMetaRunner -Regex '(bin|obj)$' -ItemsToMatch Directories -Verbose

    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $IncludeRegex,

        [Parameter(Mandatory = $false)]
        [string]
        $ExcludeRegex,

        [Parameter(Mandatory = $false)]
        [string]
        $BaseDirectory,

        [Parameter(Mandatory = $false)]
        [string]
        [ValidateSet($null, 'FilesAndDirectories', 'Files', 'Directories')]
        $ItemsToMatch = 'FilesAndDirectories',

        [Parameter(Mandatory = $false)]
        [switch]
        $VerboseLog
    )

    $params = @{
        'Recurse' = $true
    }

    if ($BaseDirectory) {
        $params['Path'] = $BaseDirectory
    } else {
        $params['Path'] = (Get-Location).Path
    }

    if ($ItemsToMatch -eq 'Directories') {
        $params['Directory'] = $true
        $log = 'directories'
    } elseif ($ItemsToMatch -eq 'Files') {
        $params['File'] = $true
        $log = 'files'
    } else {
        $log = 'all items'
    }

    Write-Log -Info ("Deleting {0} under '{1}' using IncludeRegex {2}, ExcludeRegex {3}" -f $log, $BaseDirectory, $IncludeRegex, $ExcludeRegex)
        
    Get-ChildItem @params | Where-Object { (!$IncludeRegex -or $_.FullName -imatch $IncludeRegex) -and (!$ExcludeRegex -or $_.FullName -inotmatch $ExcludeRegex) } | Foreach-Object { 
        if ($VerboseLog) {
            Write-Log -Info "Deleting $($_.FullName)"
        }
        Remove-Item -LiteralPath $_.FullName -Recurse -Force
    }
}