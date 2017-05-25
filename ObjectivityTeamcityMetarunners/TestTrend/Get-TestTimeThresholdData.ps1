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

function Get-TestTimeThresholdData {
    <#
    .SYNOPSIS
    Reads CSV file with test time thresholds.

    .PARAMETER InputThresholdCsvPath
    Path to the CSV with test time thresholds - columns TestName,PassedTime,FailedTime.

    .EXAMPLE
    $testTimeThresholdData = Get-TestTimeThresholdData -InputThresholdCsvPath $InputThresholdCsvPath
    #>

    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $InputThresholdCsvPath
    )

    if (!$InputThresholdCsvPath) {
        return @{}
    }
    if (!(Test-Path -Path $InputThresholdCsvPath)) {
        throw "Cannot find input threshold CSV at '$InputThresholdCsvPath' (current directory: $((Get-Location).Path))."
    }
    Write-Log -Info "Reading input threshold CSV file '$InputThresholdCsvPath'"
    $testTimeThresholdData = Get-CsvData -CsvPath $InputThresholdCsvPath -CsvDelimiter ','
    if (!$testTimeThresholdData) {
        Write-Log -Warn "File contains no rows."
        return @{}
    } else {
        $props = $testTimeThresholdData[0].PSObject.Properties
        if (!$props.Item('TestName') -or !$props.Item('PassedTime') -or !$props.Item('FailedTime')) {
            throw "Invalid file format - CSV file '$InputThresholdCsvPath' must contain columns TestName, PassedTime and FailedTime"
        }
    }
    $result = @{}
    foreach ($row in $testTimeThresholdData) {
        $result[$row.TestName] = [PSCustomObject]@{
            PassedTime = $row.PassedTime
            FailedTime = $row.FailedTime
        }
    }
    return $result
}