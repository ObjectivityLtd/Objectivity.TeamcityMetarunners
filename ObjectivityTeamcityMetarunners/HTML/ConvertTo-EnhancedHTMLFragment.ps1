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

function ConvertTo-EnhancedHTMLFragment {
<#
.SYNOPSIS
Creates an HTML fragment.

.DESCRIPTION
This is a modified version of the cmdlet created by Don Jones and
described in the book 'Creating HTML Reports in PowerShell'
(http://powershell.org/wp/ebooks/).
Following modifications have been made:
- removed $EvenRowCssClass / $OddRowCssClass - not needed when using DataTables
- added $IsTotalRow to enable generating table footer (needed for totals in DataTables)
- extended properties with 'format' to enable decimal formatting
- refactored the code for more clarity, used StringBuilder instead of string joining

.PARAMETER InputObject
The object to be converted to HTML. You cannot select properties using this
command; precede this command with Select-Object if you need a subset of
the objects' properties.


.PARAMETER TableCssID
Optional. The CSS ID name applied to the <TABLE> tag.


.PARAMETER DivCssID
Optional. The CSS ID name applied to the <DIV> tag which is wrapped around the table.


.PARAMETER TableCssClass
Optional. The CSS class name to apply to the <TABLE> tag.


.PARAMETER DivCssClass
Optional. The CSS class name to apply to the wrapping <DIV> tag.


.PARAMETER As
Must be 'List' or 'Table.' Defaults to Table. Actually produces an HTML
table either way; with Table the output is a grid-like display. With
List the output is a two-column table with properties in the left column
and values in the right column.


.PARAMETER Properties
A comma-separated list of properties to include in the HTML fragment.
This can be * (which is the default) to include all properties of the
piped-in object(s). In addition to property names, you can also use a
hashtable similar to that used with Select-Object. For example:


 Get-Process | ConvertTo-EnhancedHTMLFragment -As Table `
               -Properties Name,ID,@{n='VM';
                                     e={$_.VM};
                                     css={if ($_.VM -gt 100) { 'red' }
                                          else { 'green' }}}


This will create table cell rows with the calculated CSS class names.
E.g., for a process with a VM greater than 100, you'd get:


  <TD class="red">475858</TD>
  
You can use this feature to specify a CSS class for each table cell
based upon the contents of that cell. Valid keys in the hashtable are:


  n, name, l, or label: The table column header
  e or expression: The table cell contents
  css or csslcass: The CSS class name to apply to the <TD> tag 
  
Another example:


  @{n='Free(MB)';
    e={$_.FreeSpace / 1MB -as [int]};
    css={ if ($_.FreeSpace -lt 100) { 'red' } else { 'blue' }}
    
This example creates a column titled "Free(MB)". It will contain
the input object's FreeSpace property, divided by 1MB and cast
as a whole number (integer). If the value is less than 100, the
table cell will be given the CSS class "red." If not, the table
cell will be given the CSS class "blue." The supplied cascading
style sheet must define ".red" and ".blue" for those to have any
effect.  


.PARAMETER PreContent
Raw HTML content to be placed before the wrapping <DIV> tag. 
For example:


    -PreContent "<h2>Section A</h2>"


.PARAMETER PostContent
Raw HTML content to be placed after the wrapping <DIV> tag.
For example:


    -PostContent "<hr />"


.PARAMETER MakeHiddenSection
Used in conjunction with -PreContent. Adding this switch, which
needs no value, turns your -PreContent into  clickable report
section header. The section will be hidden by default, and clicking
the header will toggle its visibility.


When using this parameter, consider adding a symbol to your -PreContent
that helps indicate this is an expandable section. For example:


    -PreContent '<h2>&diams; My Section</h2>'


If you use -MakeHiddenSection, you MUST provide -PreContent also, or
the hidden section will not have a section header and will not be
visible.


.PARAMETER MakeTableDynamic
When using "-As Table", makes the table dynamic. Will be ignored
if you use "-As List". Dynamic tables are sortable, searchable, and
are paginated.


You should not use even/odd styling with tables that are made
dynamic. Dynamic tables automatically have their own even/odd
styling. You can apply CSS classes named ".odd" and ".even" in 
your CSS to style the even/odd in a dynamic table.

.PARAMETER IsTotalRow
Defines when the row is treated as 'total' and rendered in the table footer.
For example 'IsTotalRow'={ $_.nameColumn -eq 'TOTAL' } will render the row
with column 'nameColumn' = 'TOTAL' in the footer.

.EXAMPLE
 $fragment = Get-WmiObject -Class Win32_LogicalDisk |
             Select-Object -Property PSComputerName,DeviceID,FreeSpace,Size |
             ConvertTo-EnhancedHTMLFragment -EvenRowClass 'even' `
                                    -OddRowClass 'odd' `
                                    -PreContent '<h2>Disk Report</h2>' `
                                    -MakeHiddenSection `
                                    -MakeTableDynamic


 You will usually save fragments to a variable, so that multiple fragments
 (each in its own variable) can be passed to ConvertTo-EnhancedHTML.

#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [object[]]$InputObject,

        [string]$TableCssID,
        [string]$DivCssID,
        [string]$DivCssClass,
        [string]$TableCssClass = "display",


        [ValidateSet('List','Table')]
        [string]$As = 'Table',


        [object[]]$Properties = '*',


        [string]$PreContent,


        [switch]$MakeHiddenSection,


        [switch]$MakeTableDynamic,


        [string]$PostContent,

        [scriptblock]$IsTotalRow
    )
    BEGIN {
        <#
            Accumulate output in a variable so that we don't
            produce an array of strings to the pipeline, but
            instead produce a single string.
        #>
        $out = New-Object System.Text.StringBuilder


        <#
            Add the section header (pre-content). If asked to
            make this section of the report hidden, set the
            appropriate code on the section header to toggle
            the underlying table. Note that we generate a GUID
            to use as an additional ID on the <div>, so that
            we can uniquely refer to it without relying on the
            user supplying us with a unique ID.
        #>
        Write-Verbose "Precontent"
        if ($PSBoundParameters.ContainsKey('PreContent')) {
            if ($PSBoundParameters.ContainsKey('MakeHiddenSection')) {
               [string]$tempid = [System.Guid]::NewGuid()
               [void]$out.Append("<span class=`"sectionheader`" onclick=`"`$('#$tempid').toggle(500);`">$PreContent</span>`n")
            } else {
                [void]$out.Append($PreContent)
                $tempid = ''
            }
        }


        <#
            The table will be wrapped in a <div> tag for styling
            purposes. Note that THIS, not the table per se, is what
            we hide for -MakeHiddenSection. So we will hide the section
            if asked to do so.
        #>
        Write-Verbose "DIV"
        if ($PSBoundParameters.ContainsKey('DivCSSClass')) {
            $temp = " class=`"$DivCSSClass`""
        } else {
            $temp = ""
        }
        if ($PSBoundParameters.ContainsKey('MakeHiddenSection')) {
            $temp += " id=`"$tempid`" style=`"display:none;`""
        } else {
            $tempid = ''
        }
        if ($PSBoundParameters.ContainsKey('DivCSSID')) {
            $temp += " id=`"$DivCSSID`""
        }
        [void]$out.Append("<div $temp>")


        <#
            Create the table header. If asked to make the table dynamic,
            we add the CSS style that ConvertTo-EnhancedHTML will look for
            to dynamic-ize tables.
        #>
        Write-Verbose "TABLE"
        $_TableCssClass = ''
        if ($PSBoundParameters.ContainsKey('MakeTableDynamic') -and $As -eq 'Table') {
            $_TableCssClass += 'enhancedhtml-dynamic-table '
        }
        if ($TableCssClass) {
            $_TableCssClass += $TableCssClass
        }
        if ($_TableCssClass -ne '') {
            $css = "class=`"$_TableCSSClass`""
        } else {
            $css = ""
        }
        if ($PSBoundParameters.ContainsKey('TableCSSID')) {
            $css += "id=`"$TableCSSID`""
        } else {
            if ($tempid -ne '') {
                $css += "id=`"$tempid`""
            }
        }
        [void]$out.Append("<table $css>")


        <#
            We're now setting up to run through our input objects
            and create the table rows
        #>
        $wrote_first_line = $false
        $wrote_total = $false


        if ($properties -eq '*') {
            $all_properties = $true
        } else {
            $all_properties = $false
        }

        $rowNumber = 1

    }
    PROCESS {

        foreach ($object in $inputobject) {
            Write-Verbose "Processing object"

            <#
                If asked to include all object properties, get them.
            #>
            if ($all_properties) {
                $properties = $object | Get-Member -MemberType Properties | Select -ExpandProperty Name
            }

            if ($PSBoundParameters.ContainsKey('IsTotalRow') -and ($Object | Where-Object $IsTotalRow)) {
                $isTotal = $true
            }
            
            $columns = Get-EnhancedHTMLProperties -Properties $properties -Object $object -RowNumber $rowNumber -IsTotal:$isTotal

            $rowNumber++
            <#
                Write the table header, if we're doing a table.
            #>
            if (-not $wrote_first_line -and $as -eq 'Table') {
                Write-Verbose "Writing header row"

                $headerrow = $columns | Foreach { "<th>$($_.name)</th>" }
                [void]$out.Append("<thead><tr>$headerrow</tr></thead><tbody>")
                $wrote_first_line = $true
            }

            if ($isTotal) {
                [void]$out.Append("</tbody><tfoot>")
                $tableElement = "th"
            } else {
                $tableElement = "td"
            }

            <#
                When constructing a table, we have to remember the
                property names so that we can build the table header.
                In a list, it's easier - we output the property name
                and the value at the same time, since they both live
                on the same row of the output.
            #>
            if ($As -eq 'table') {
                $datarow = $columns | Foreach { "<${tableElement}$(if ($_.css -ne '') { ' class="'+ $_.css +'"' })>$($_.value)</${tableElement}>" }
                [void]$out.Append("<tr>$datarow</tr>")
            } else {
                $wrote_first_line = $true
                $datarow = $columns | Foreach { "<${tableElement}$(if ($_.css -ne '') { ' class="'+ $_.css +'"' })>$($_.name) :</${tableElement}><${tableElement}$(if ($_.css -ne '') { ' class="'+ $_.css +'"' })>$($_.value)</${tableElement}>" }
                [void]$out.Append("<tr>$datarow</tr>")
            }
            if ($isTotal) {
                [void]$out.Append("</tfoot>")
                $wrote_total = $true
            }
      }
    }
    END {
        <#
            Finally, post-content code, the end of the table,
            the end of the <div>, and write the final string.
        #>
        Write-Verbose "PostContent"
        if ($PSBoundParameters.ContainsKey('PostContent')) {
            [void]$out.Append("`n$PostContent")
        }
        Write-Verbose "Done"
        if (!$wrote_total) {
            [void]$out.Append("</tbody>")
        }

        [void]$out.Append("</table></div>")
        Write-Output $out.ToString()
    }
}