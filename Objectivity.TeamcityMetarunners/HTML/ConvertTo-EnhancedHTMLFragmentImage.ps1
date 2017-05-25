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

function ConvertTo-EnhancedHTMLFragmentImage {

    <#
    .SYNOPSIS
    Creates a HTML fragment containing an image. Note the image is wrapped in a div class="imageWrapper".

    .PARAMETER Uri
    Uri to the image.

    .PARAMETER Header
    Header that will be rendered above the image.

    .PARAMETER Width
    Width of the image.

    .PARAMETER Height
    Height of the image.

    .EXAMPLE
    ConvertTo-EnhancedHTMLFragmentImage -Header $_.BaseName -Uri $_.Name
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $Uri, 

        [Parameter(Mandatory=$false)]
        [string] 
        $Header, 
        
        [Parameter(Mandatory=$false)]
        [int]
        $Width,

        [Parameter(Mandatory=$false)]
        [int]
        $Height
    )

    return "<div class=`"imageWrapper`"><h3>$Header</h3><img src=`"$Uri`" $(if ($Width) { "width="""$Width""""" })$(if ($Height) { "height="""$Height""""" })></img></div>"
}