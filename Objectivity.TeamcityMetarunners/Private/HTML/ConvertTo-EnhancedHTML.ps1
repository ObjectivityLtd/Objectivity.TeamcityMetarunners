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

function ConvertTo-EnhancedHTML {
<#
.SYNOPSIS
Provides an enhanced version of the ConvertTo-HTML command.

.DESCRIPTION
Includes inserting an embedded CSS style sheet, JQuery, and JQuery Data Tables for
interactivity. 
Intended to be used with HTML fragments that are produced
by ConvertTo-EnhancedHTMLFragment. This command does not accept pipeline
input. 
This is a modified version of the cmdlet created by Don Jones and
described in the book 'Creating HTML Reports in PowerShell'
(http://powershell.org/wp/ebooks/).
Following modifications have been made:
- replaced $jqueryUri and $jQueryDataTableURI with $JavascriptUri for more flexibility
- $CssUri and $CssStyleSheet can be provided simultaneously
- removed 'fixing table HTML' part, as it's no longer needed in the modified version of ConvertTo-EnhancedHTMLFragment 

.PARAMETER JavascriptUri
A list of Uniform Resource Indicator (URI) pointing to the locations of 
Javascript files which should be referenced by the html.
Defaults to jQuery and jQuery.DataTables from cdns.


.PARAMETER CssStyleSheet
The CSS style sheet content - not a file name. If you have a CSS file,
you can load it into this parameter as follows:


    -CSSStyleSheet (Get-Content MyCSSFile.css)


Alternately, you may link to a Web server-hosted CSS file by using the
-CssUri parameter.


.PARAMETER CssUri
A Uniform Resource Indicator (URI) to a Web server-hosted CSS file.
Must start with either http:// or https://. If you omit this, you
can still provide an embedded style sheet, which makes the resulting
HTML page more standalone. To provide an embedded style sheet, use
the -CSSStyleSheet parameter.


.PARAMETER Title
A plain-text title that will be displayed in the Web browser's window
title bar. Note that not all browsers will display this.


.PARAMETER PreContent
Raw HTML to insert before all HTML fragments. Use this to specify a main
title for the report:


    -PreContent "<H1>My HTML Report</H1>"


.PARAMETER PostContent
Raw HTML to insert after all HTML fragments. Use this to specify a 
report footer:


    -PostContent "Created on $(Get-Date)"


.PARAMETER HTMLFragments
One or more HTML fragments, as produced by ConvertTo-EnhancedHTMLFragment.


    -HTMLFragments $part1,$part2,$part3

.EXAMPLE
ConvertTo-EnhancedHTML @params | Out-File -FilePath $htmlOutputPath -Encoding UTF8

See New-TeamcityTrendReport or New-JMeterAggregateReport


#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string[]]$JavascriptUri = @('https://code.jquery.com/jquery-1.10.2.min.js', 'https://cdn.datatables.net/1.10.0/js/jquery.dataTables.js'),
        [string[]]$CssStyleSheet,
        [string[]]$CssUri = @('https://cdn.datatables.net/1.10.0/css/jquery.dataTables.css'),
        [string]$Title = 'Report',
        [string]$PreContent,
        [string]$PostContent,
        [Parameter(Mandatory=$True)][string[]]$HTMLFragments
    )


    <#
        Add CSS style sheet. If provided in -CssUri, add a <link> element.
        If provided in -CssStyleSheet, embed in the <head> section.
        Note that BOTH may be supplied - this is legitimate in HTML.
    #>
    Write-Verbose "Making CSS style sheet"
    $stylesheet = ""
    if ($CssUri) {
        foreach ($uri in $CssUri) {
            $stylesheet += "<link rel=`"stylesheet`" href=`"$uri`" type=`"text/css`" />"
        }
    }
    if ($CssStyleSheet) {
        $stylesheet += "<style>"
        foreach ($css in $CssStyleSheet) {
            $stylesheet += "$css`r`n"
        }
        $stylesheet += "</style>"
    }


    <#
        Create the HTML tags for the page title, and for
        our main javascripts.
    #>
    Write-Verbose "Creating <TITLE> and <SCRIPT> tags"
    $titletag = ""
    if ($PSBoundParameters.ContainsKey('title')) {
        $titletag = "<title>$title</title>"
    }

    if ($JavascriptUri) {
        foreach ($uri in $JavascriptUri) {
            $script += "<script type=`"text/javascript`" src=`"$uri`"></script>`n"
        }
    }
    


    <#
        Render supplied HTML fragments as one giant string
    #>
    Write-Verbose "Combining HTML fragments"
    $body = $HTMLFragments | Out-String


    <#
        If supplied, add pre- and post-content strings
    #>
    Write-Verbose "Adding Pre and Post content"
    if ($PSBoundParameters.ContainsKey('precontent')) {
        $body = "$PreContent`n$body"
    }
    if ($PSBoundParameters.ContainsKey('postcontent')) {
        $body = "$body`n$PostContent"
    }


    <#
        Add a final script that calls the datatable code
        We dynamic-ize all tables with the .enhancedhtml-dynamic-table
        class, which is added by ConvertTo-EnhancedHTMLFragment.
    #>
    Write-Verbose "Adding interactivity calls"
    $datatable = ""
    $datatable = "<script type=`"text/javascript`">"
    $datatable += '$(document).ready(function () {'
    $datatable += "`$('.enhancedhtml-dynamic-table').dataTable();"
    $datatable += '} );'
    $datatable += "</script>"


    <#
        Produce the final HTML. We've more or less hand-made
        the <head> amd <body> sections, but we let ConvertTo-HTML
        produce the other bits of the page.
    #>
    Write-Verbose "Producing final HTML"
    ConvertTo-HTML -Head "$stylesheet`n$titletag`n$script`n$datatable" -Body $body  
    Write-Debug "Finished producing final HTML"

}