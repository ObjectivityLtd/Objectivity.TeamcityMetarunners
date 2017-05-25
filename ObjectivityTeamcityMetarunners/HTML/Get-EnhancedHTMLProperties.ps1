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

function Get-EnhancedHTMLProperties {
    <#
    .SYNOPSIS
    A helper function for ConvertTo-EnhancedHTMLFragment.
    Generates a list of columns (specified in $Properties) applied to $Object.

    .PARAMETER Properties
    Properties as supplied by the user.

    .PARAMETER Object
    Object whose properties will be enumerated.

    .PARAMETER RowNumber
    Current row number.

    .PARAMETER IsTotal
    Flag set if the row is total (RowNumber is not printed in this case).

    .EXAMPLE
    $columns = Get-EnhancedHTMLProperties -Properties $properties -Object $object
    #>

    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory=$true)]
        [object[]]
        $Properties,

        [Parameter(Mandatory=$true)]
        [object]
        $Object,

        [Parameter(Mandatory=$true)]
        [int]
        $RowNumber,

        [Parameter(Mandatory=$false)]
        [switch]
        $IsTotal
    )

    $result = @()

    <#
        We either have a list of all properties, or a hashtable of
        properties to play with. Process the list.
    #>
    foreach ($prop in $Properties) {
        $name = $null
        $value = $null
        $cell_css = ''


        <#
            $prop is a simple string if we are doing "all properties,"
            otherwise it is a hashtable. If it's a string, then we
            can easily get the name (it's the string) and the value.
        #>
        if ($prop -is [string]) {
            Write-Verbose "Property $prop"
            if ($prop -eq "_ROWNUM_") {
                $name = "No"
                if ($IsTotal) {
                    $value = ""
                } else {
                    $value = $RowNumber
                }
            } else {
                $name = $prop
                $value = $object.($prop)
            }
        } elseif ($prop -is [hashtable]) {
            Write-Verbose "Property hashtable"
            <#
                For key "css" or "cssclass," execute the supplied script block.
                It's expected to output a class name; we embed that in the "class"
                attribute later.
            #>
            if ($prop.ContainsKey('cssclass')) { $cell_css = $Object | ForEach $prop['cssclass'] }
            if ($prop.ContainsKey('css')) { $cell_css = $Object | ForEach $prop['css'] }


            <#
                Get the current property name.
            #>
            if ($prop.ContainsKey('n')) { $name = $prop['n'] }
            if ($prop.ContainsKey('name')) { $name = $prop['name'] }
            if ($prop.ContainsKey('label')) { $name = $prop['label'] }
            if ($prop.ContainsKey('l')) { $name = $prop['l'] }


            <#
                Execute the "expression" or "e" key to get the value of the property.
            #>

            if ($prop.ContainsKey('v')) { $value = $Object.$($prop['v']) }
            if ($prop.ContainsKey('value')) { $value = $Object.$($prop['value']) }

            if ($prop.ContainsKey('e')) { $value = $Object | ForEach $prop['e'] }
            if ($prop.ContainsKey('expression')) { $value = $tObject | ForEach $prop['expression'] }

            if ($prop.ContainsKey('f')) { $value = $prop['f'] -f (ConvertTo-Decimal -Value $value) }
            if ($prop.ContainsKey('format')) { $value = $prop['format'] -f (ConvertTo-Decimal -Value $value) }


            <#
                Make sure we have a name and a value at this point.
            #>
            if ($name -eq $null -or $value -eq $null) {
                Write-Error "Hashtable missing Name and/or Expression key"
            }
        } else {
            <#
                We got a property list that wasn't strings and
                wasn't hashtables. Bad input.
            #>
            Write-Warning "Unhandled property $prop"
        }

        # SuppressScriptCop - adding small arrays is ok    
        $result += @{ 'css' = $cell_css;
                      'name' = $name;
                      'value' = $value;
                    }
    }
    return $result
}