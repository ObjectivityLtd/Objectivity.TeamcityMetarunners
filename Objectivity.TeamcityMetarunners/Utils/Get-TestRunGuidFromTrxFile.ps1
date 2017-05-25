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

function Get-TestRunGuidFromTrxFile {
    <#
    .SYNOPSIS
    Returns test run guid from trx file.

    .PARAMETER TrxFolderOrFilePath
    Can be either direct path to the trx (xml) file, which contains RunId or path to the directory where trx files are kept.
    In second scenario - the newest trx file in directory will be chosen.

    .EXAMPLE
    Get-TestRunGuidFromTrxFile -TrxFolderOrFilePath 'C:\sampleFoleder\sampleFile.trx'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $TrxFolderOrFilePath
    )

    if (!(Test-Path -PathType Leaf -Path $TrxFolderOrFilePath)) {

        if (Test-Path -PathType Container -Path $TrxFolderOrFilePath) {

            $TrxFolderOrFilePath = Get-ChildItem -Path $TrxFolderOrFilePath -Filter *.trx | Sort -Property LastWriteTimeUtc -Descending | Select-Object -ExpandProperty FullName -First 1
        }
        else {
            $fileOrPathDoesNotExtists = $true
        }
    }
    
    if ($fileOrPathDoesNotExtists) {
        throw "File/Path $TrxFolderOrFilePath does not exist."
    }

    [xml]$trx = Get-Content -Path $TrxFolderOrFilePath -ReadCount 0

    $testRunGuid = $trx.TestRun.id

    if ([string]::IsNullOrEmpty($testRunGuid)) {
        throw "Xml file $TrxFolderOrFilePath does not have TestRun element or id attribute within it."
    }

    return $testRunGuid
}