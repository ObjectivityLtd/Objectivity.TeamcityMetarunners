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

function New-TeamcityTrendReport {
    <#
    .SYNOPSIS
    Generates Teamcity tests trend reports (CSV / HTML) basing on data available in TeamCity database.

    .DESCRIPTION
    It runs a sql command directly in TeamCity database and generates csv / html reports basing on that.

    .PARAMETER TeamcityBuildId
    Id of currently running Teamcity build (%teamcity.build.id%).

    .PARAMETER TeamcityDbConnectionString
    Connection string that will be used to connect to TeamCity database.

    .PARAMETER TeamcityCurrentBuildNumber
    Current Teamcity build number (%build.number%) - required for reporting test results for current build.

    .PARAMETER OutputDir
    Output directory where .html / .png / .csv files will be generated.

    .PARAMETER TestNameConversionRegex
    Regex for shortening test names, e.g. if test is named 'Category: LongName-TestName', and you provide
    regex 'Category: LongName-(.*)', only 'TestName' will be displayed.

    .PARAMETER TestNameIncludeRegex
    Regex for filtering tests - only names matching this regex will be included.

    .PARAMETER TestNameExcludeRegex
    Regex for filtering tests - names matching this regex will be excluded.

    .PARAMETER OutputCsvName
    Name of output csv file.

    .PARAMETER OutputHtmlName
    Name of output html file.

    .PARAMETER InputThresholdCsvPath
    Path to the CSV with test time thresholds - columns TestName,PassedTime,FailedTime.
    Tests with time <= PassedTime will be marked green, Passed Time < time < FailedTime amber, and time >= FailedTime red.

    .PARAMETER NumberOfLastBuilds
    Number of builds that will be trended - all earlier builds will be ignored.

    .PARAMETER GenerateCsvFile
    If true, CSV file will be generated.

    .EXAMPLE
    New-TeamcityTrendReport TestNames @('test1','test2') -TeamcityBuildTypeId 'Client_Project_ConfName' -TeamcityDbServer 'Teamcity' -TeamcityDbUser 'TeamCityExtensions' -TeamcityDbPassword 'XXX' -OutputCsvPath 'c:\output\jmeter-trend.csv' -OutputHtmlPath 'c:\output\jmeter-trend.html'
    #>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $TeamcityBuildId,

        [Parameter(Mandatory=$true)]
        [string]
        $TeamcityDbConnectionString,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputDir,

        [Parameter(Mandatory=$false)]
        [string[]]
        $TestNameConversionRegex,

        [Parameter(Mandatory=$false)]
        [string]
        $TestNameIncludeRegex,

        [Parameter(Mandatory=$false)]
        [string]
        $TestNameExcludeRegex,

        [Parameter(Mandatory=$false)]
        [string]
        $OutputCsvName = 'TestTrendReport.csv',

        [Parameter(Mandatory=$false)]
        [string]
        $OutputHtmlName = 'TestTrendReport.html',

        [Parameter(Mandatory=$false)]
        [string]
        $InputThresholdCsvPath,

        [Parameter(Mandatory=$false)]
        [int]
        $NumberOfLastBuilds = 30,

        [Parameter(Mandatory=$false)]
        [switch]
        $GenerateCsvFile
    )

    $testTimeThresholdData = Get-TestTimeThresholdData -InputThresholdCsvPath $InputThresholdCsvPath

    if (!(Test-Path -LiteralPath $OutputDir)) {
        Write-Log -Info "Creating directory '$OutputDir'"
        [void](New-Item -Path $OutputDir -ItemType Directory)
    }
    $csvOutputPath = Join-Path -Path $OutputDir -ChildPath $OutputCsvName
    $htmlOutputPath = Join-Path -Path $OutputDir -ChildPath $OutputHtmlName

    $sql = Get-TeamCityTrendReportSql
    $sql = $sql -f $TeamcityBuildId, $NumberOfLastBuilds

    Write-Log -Info "Getting trend data from TeamCity database, BuildId: '$TeamcityBuildId', NumberOfLastBuilds: $NumberOfLastBuilds"
    $sqlResult = Invoke-Sql -ConnectionString $TeamcityDbConnectionString -Query $sql
    if (!$sqlResult -or !$sqlResult.Tables -or $sqlResult.Tables.Count -lt 2) {
        Write-Log -Warn "No trend data returned from TeamCity database. Please ensure parameters are correct. Sql: $sql"
        return
    }
    $sqlResult = $sqlResult.Tables

    # there are two tables returned from sql - buildIdData (containing build id - build name - success) and trendData (containing pivoted build_id / test_name -> duration table)
    $buildIdData = $sqlResult[0]
    $trendData = $sqlResult[1]

    if ($TestNameConversionRegex) {
        foreach ($entry in $trendData) {
            foreach ($regex in $TestNameConversionRegex) { 
                if ($entry.test_name -imatch $regex -and $matches[1]) {
                    $entry.test_name = $matches[1]
                }
            }
        }
    }

    if ($TestNameIncludeRegex) {
        $trendData = $trendData | Where-Object { $_.test_name -imatch $TestNameIncludeRegex }
    }
    if ($TestNameExcludeRegex) {
        $trendData = $trendData | Where-Object { $_.test_name -inotmatch $TestNameExcludeRegex }
    }

    $buildIdMap = @{}
    foreach ($row in $buildIdData) { 
        $buildIdMap[[string]($row.build_id)] = $row 
    }


    Write-Log -Info "Generating html report"
    if ($GenerateCsvFile) {
        ConvertTo-CsvInBuildNameOrder -BuildIdMap $buildIdMap -TrendData $trendData -CsvOutputPath $csvOutputPath
    }

    $htmlChartData = $trendData | ConvertTo-EnhancedHTMLFragmentRickshawJavascriptData -JavascriptVariableName 'TestData' -PropertySeriesName 'test_name' -BuildIdMap $buildIdMap `
        -PrefixCode "var palette = new Rickshaw.Color.Palette({ scheme: 'munin' } );"

    $htmlTestTimeThresholdData = $testTimeThresholdData | ConvertTo-EnhancedHTMLFragmentJavascriptHashtable -JavascriptVariableName 'TestTimeThresholdData'

    $htmlChart = ConvertTo-EnhancedHTMLFragmentRickshawChart -JavascriptDataVariableName 'TestData' -JavascriptTestTimeThresholdDataVariableName 'TestTimeThresholdData'

    $javascriptUri= @('http://code.jquery.com/jquery-1.11.3.min.js', 'http://cdn.datatables.net/1.10.9/js/jquery.dataTables.min.js',
        'http://cdn.datatables.net/fixedcolumns/3.1.0/js/dataTables.fixedColumns.min.js',
        'http://cdnjs.cloudflare.com/ajax/libs/d3/3.5.6/d3.min.js', 'https://code.jquery.com/ui/1.11.4/jquery-ui.min.js', 
        'http://cdnjs.cloudflare.com/ajax/libs/rickshaw/1.5.1/rickshaw.min.js')

    Write-Log -Info "Generating Test Trend HTML report at '$htmlOutputPath'."

    $params = @{'HTMLFragments' = @($htmlChartData, $htmlTestTimeThresholdData, $htmlChart);
                'JavascriptUri' = $javascriptUri;
                'CssStyleSheet' = @((Get-DefaultJqueryDataTableCss), (Get-DefaultRickshawCss));
                'CssUri' = @('http://cdn.datatables.net/1.10.9/css/jquery.dataTables.css', 
                    'https://cdn.datatables.net/fixedcolumns/3.1.0/css/fixedColumns.dataTables.min.css',
                    'http://ajax.googleapis.com/ajax/libs/jqueryui/1.11.4/themes/smoothness/jquery-ui.min.css')
               }

    ConvertTo-EnhancedHTML @params | Out-File -FilePath $htmlOutputPath -Encoding UTF8

}

function ConvertTo-CsvInBuildNameOrder {

     <#
    .SYNOPSIS
    Generates a CSV file containing trend data.

    .DESCRIPTION
    The columns in CSV file are ordered by build names.

    .PARAMETER BuildIdMap
    Hashmap mapping build_id to sql row.

    .PARAMETER TrendData
    Raw trend data as taken from sql command.

    .PARAMETER CsvOutputPath
    Path to the output CSV file.

    .EXAMPLE
    ConvertTo-CsvInBuildNameOrder -BuildIdMap $buildIdMap -TrendData $trendData -CsvOutputPath $csvOutputPath
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $BuildIdMap,

        [Parameter(Mandatory=$true)]
        [object[]]
        $TrendData,

        [Parameter(Mandatory=$true)]
        [string]
        $CsvOutputPath
    )
    Write-Log -Info "Generating Test Trend CSV report at '$csvOutputPath'."
    $trendData | Foreach-Object { 
        $newRow = New-Object PSObject
        $row = $_
        Add-Member -InputObject $newRow -Name 'test_name' -Value $_['test_name'] -MemberType NoteProperty
        Get-Member -InputObject $row -MemberType Properties | Where-Object { $_.Name -ne 'test_name' } | `
            Foreach-Object { Add-Member -InputObject $newRow -Name $BuildIdMap[$_.Name].build_number -Value $row[$_.Name] -MemberType NoteProperty }
        $newRow
    } | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $CsvOutputPath

}


function Get-TeamCityTrendReportSql {

    <#
    .SYNOPSIS
    Returns a sql that returns trend data from Teamcity database.

    .EXAMPLE
    $sql = Get-TeamCityTrendReportSql

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return @"
    -- Test Trend Report (PSCI / New-TeamcityTrendReport)
    SET QUOTED_IDENTIFIER ON
    SET NOCOUNT ON

    DECLARE @cols AS NVARCHAR(MAX),
        @query  AS NVARCHAR(MAX)

    if object_id('tempdb..#builds') is not null
        drop table #builds;

    if object_id('tempdb..#tests') is not null
        drop table #tests;

    select top {1}
        build_id,
        build_number,
        cast(row_number() over (partition by build_number order by build_number) as varchar) as build_row,
        count(build_number) over (partition by build_number order by build_number) non_distinct_build_numbers,
        success
    into
        #builds
    from (
        select
            build_id, 
            build_number,
            cast(1 as bit) as success
        from
            dbo.running r
        where 
            build_id = {0}
        union all
        select
            h.build_id, 
            h.build_number,
            cast(case when h.status = 1 then 1 else 0 end as bit) as success
        from
            dbo.history h
        inner join
            (select 
                build_type_id
             from
                dbo.running 
             where
                build_id = {0}
             union
             select
                build_type_id
             from
                dbo.history
             where
                build_id = {0}
           ) currentBuild
        on currentBuild.build_type_id = h.build_type_id
        where
            h.status <> 0 -- cancelled
    ) x
    where 
        exists (select 1 from dbo.test_info where build_id = x.build_id)
    order by 
        build_id desc;

    select
        build_id,
        case when non_distinct_build_numbers = 1 then b.build_number else b.build_number + '_' + build_row end build_number,
        success
    from
        #builds b

    select
        b.build_id,
        tn.test_name,
        ti.duration
    into
        #tests
    from
        #builds b
    inner join
        dbo.test_info ti
    on ti.build_id = b.build_id
    inner join
        dbo.test_names tn
    on tn.id = ti.test_name_id
    /*inner join
        dbo.test_info tiFilter
    on  tiFilter.test_name_id = tn.id
    and tiFilter.build_id = (select top 1 build_id from #builds order by build_id desc)*/
    where
        ti.status <> 0 -- ignored tests

    select @cols = STUFF((SELECT  ',' + QUOTENAME(build_id) 
                        from #tests
                        group by build_id
                        order by build_id
                FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)') 
            ,1,1,'')

    
    set @query = 'select test_name, ' + @cols + '
                  from 
                 (
                    select test_name, build_id, duration
                    from #tests
                ) x
                pivot 
                (
                    max(duration)
                    for build_id in (' + @cols + ')
                ) p 
                order by test_name'

    execute(@query)
"@

}
