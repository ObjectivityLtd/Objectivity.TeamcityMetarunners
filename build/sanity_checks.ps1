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

$licenseText = @"
<#
The MIT License (MIT)
`
Copyright (c) 2015 Objectivity Bespoke Software Specialists
`
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
`
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
`
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
"@ -replace "`r`n", "`n" -replace "`n", [Environment]::NewLine

# we additionally accept different years
$licenseTexts = @($licenseText, ($licenseText -replace '2015', '2016'), ($licenseText -replace '2015', '2017'))

$customSources = Get-ChildItem -Path "$PSScriptRoot\..\ObjectivityTeamcityMetarunners" -File -Filter "*.ps*1" -Recurse | 
                 Select-Object -ExpandProperty FullName |
                 Where-Object { $_ -inotmatch '(baseModules)' }


$licenseNotMatching = New-Object -TypeName System.Collections.ArrayList
$tabsNotMatching = New-Object -TypeName System.Collections.ArrayList

foreach ($file in $customSources) {
    $content = Get-Content -Path $file -ReadCount 0 | Out-String
    $licenseTextOk = $false
    foreach ($acceptedLicenseText in $licenseTexts) { 
        if ($content.StartsWith($acceptedLicenseText)) {
            $licenseTextOk = $true
            break
        }
    }
    if (!$licenseTextOk) {
        [void]($licenseNotMatching.Add($file))
    }
    if ($content -match '\t') {
        [void]($tabsNotMatching.Add($file))
    }
}

$errMsg = @()
if ($licenseNotMatching) {
    $errMsg += 'There are {0} file(s) without valid license header - please use license header from any other file: {1}' -f $licenseNotMatching.Count, ($licenseNotMatching -join ', ')
}
if ($tabsNotMatching) {
    $errMsg += 'There are {0} file(s) with tabs - please convert all tabs to spaces: {1}' -f $tabsNotMatching.Count, ($tabsNotMatching -join ', ')
}

if ($errMsg) {
    throw ($errMsg -join "`r`n")   
}

Write-Host ('Checked {0} files - all files passed sanity checks.' -f $customSources.Count)

