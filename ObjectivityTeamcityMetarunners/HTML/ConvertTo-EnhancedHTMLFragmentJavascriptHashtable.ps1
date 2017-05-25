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

function ConvertTo-EnhancedHTMLFragmentJavascriptHashtable {

    <#
    .SYNOPSIS
    Creates a HTML fragment containing a Javascript hashtable data.

    .PARAMETER InputObject
    Input array that will be converted to Javascript array.

    .PARAMETER JavascriptVariableName
    Name of Javascript variable name where the hashable will be assigned to.

    .EXAMPLE
    ConvertTo-EnhancedHTMLFragmentJavascriptHashtable -InputObject $testTimeThresholdData -JavascriptVariableName 'TestTimeThresholdData'
    #>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [hashtable]
        $InputObject,

        [Parameter(Mandatory=$True)]
        [string]
        $JavascriptVariableName
    )
    BEGIN {
        $out = New-Object -TypeName System.Text.StringBuilder

        [void]($out.Append("<script type=`"text/javascript`">var $JavascriptVariableName = {"))
    }
    PROCESS {
        $properties = $null
        foreach ($object in $InputObject.GetEnumerator()) {
            $key = $object.Key
            $value = $object.Value
            [void]($out.Append("'$key': {"))
            if (!$properties) {
                $properties = @($value | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name)
            }
            
            foreach ($property in $properties) {
                $propValue = $value.$property
                [void]($out.Append("'$property': '$propValue',"))
            }
            [void]($out.Append('},'))
        }
    }
    END {
        [void]($out.Append('};'))
        [void]($out.Append('</script>'))
        $out.ToString()
    }
}