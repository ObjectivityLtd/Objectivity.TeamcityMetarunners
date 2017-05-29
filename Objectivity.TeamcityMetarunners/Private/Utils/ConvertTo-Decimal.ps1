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

function ConvertTo-Decimal {
    <#
    .SYNOPSIS
    Converts string to decimal or $null if conversion fails.
    
    .PARAMETER Value
    String to convert.

    .EXAMPLE
    ConvertTo-Decimal -Value '3.0'
    #>   
     
    [CmdletBinding()]
    [OutputType([decimal])]
    param(
        [Parameter(Mandatory=$false)]
        [string] 
        $Value
    )

    if (!$Value) {
        return $null
    }
    $out = [decimal]0.0
    $result = [System.Decimal]::TryParse($value, [ref]$out)
    if (!$result) {
        return $null
    }
    return $out
}