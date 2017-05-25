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

function Test-RunCondition {

    <#
    .SYNOPSIS
    Evaluates a string specified by user - used to decide whether to run a metarunner.

    .DESCRIPTION
    This is required because currently TeamCity does not allow to execute a build step based on a condition - https://youtrack.jetbrains.com/issue/TW-17939.

    .PARAMETER RunCondition
    An expression that will be evaluated.
    
    .EXAMPLE
    Test-RunCondition -RunCondition "'1' -eq '1'"
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $RunCondition
    )

    if ($RunCondition) {
        Write-Log -Info "Evaluating RunCondition: $RunCondition"
        $result = Invoke-Expression -Command $RunCondition
        if ($result) {
            $resultTest = $true
            $msg = "- will run"
        } else {
            $resultTest = $false
            $msg = "- will not run"
        }
        Write-Log -Info "RunCondition result: $result $msg"
        return $resultTest
    }
    return $true
    
}