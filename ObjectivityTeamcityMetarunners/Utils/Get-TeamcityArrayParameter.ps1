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

function Get-TeamcityArrayParameter {

    <#
    .SYNOPSIS
    A helper for TeamCity MetaRunners that converts a string parameter to array.
    
    .PARAMETER Param
    Value of the parameter to convert.

    .EXAMPLE
      $param = Get-TeamCityArrayParameter -Param @"
%teamcity.parameter%
"@
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $Param
    )

    if (!$Param) {
        return @()
    }

    # 1) Remove all \r
    # 2) Save \,
    # 3) Convert all , to \n
    # 4) Convert \, back to ,
    # 5) Convert \\ to \
    # 6) Split by \n
    return ,($Param `
        -replace "`r", "" `
        -replace "\\\\", "\ " `
        -replace "\\,", "`r" `
        -replace ",", "`n" `
        -replace "`r", "," `
        -replace "\\ ", "\" `
        -split "`n")
}