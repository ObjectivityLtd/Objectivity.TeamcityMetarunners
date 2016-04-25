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

function Get-DefaultJqueryDataTableCss {

    <#
    .SYNOPSIS
    Returns a CSS for styling Jquery Data Table.

    .EXAMPLE
    Get-DefaultJqueryDataTableCss
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param()

return @"
body {
    color:#333333;
    font-family:Calibri,Tahoma;
    font-size: 11pt;
}
h1 {
    text-align:center;
}
h2 {
    border-top:1px solid #666666;
}
td,tfoot th { text-align: right; }
.alignLeft { text-align: left; }
.paginate_enabled_next, .paginate_enabled_previous {
    cursor:pointer; 
    border:1px solid #222222; 
    background-color:#dddddd; 
    padding:2px; 
    margin:4px;
    border-radius:2px;
}
.paginate_disabled_previous, .paginate_disabled_next {
    color:#666666; 
    cursor:pointer;
    background-color:#dddddd; 
    padding:2px; 
    margin:4px;
    border-radius:2px;
}
.dataTables_info { margin-bottom:4px; }
.sectionheader { cursor:pointer; }
.sectionheader:hover { color:red; }
.warning {
    color:red;
    font-weight:bold;
} 
table.dataTable tfoot th { padding: 8px 10px }
.imageWrapper { 
    float: left;
    padding-left: 10px;
}

#tableContainer {
    margin-top: 15px;
    text-align: center;
    width: 100%;
}

#tableData_wrapper {
    margin: 0 auto;
    max-width: 1360px;
}

table.dataTable {
    width: auto;
    white-space: nowrap;
}


table.dataTable td {
    max-width: 620px;
    white-space: nowrap;
    overflow: hidden; 
    text-overflow: ellipsis;
}

table.dataTable th{
    white-space: pre-wrap !important; /* CSS3 */
    overflow: hidden;
    height: auto !important;
    vertical-align: bottom;
}

.ui-tooltip {
    max-width: 1200px;
}

"@

}