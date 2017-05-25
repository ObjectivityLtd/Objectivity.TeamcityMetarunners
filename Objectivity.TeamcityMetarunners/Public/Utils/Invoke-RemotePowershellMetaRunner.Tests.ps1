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

Import-Module -Name "$PSScriptRoot\..\..\Objectivity.TeamcityMetarunners.psd1" -Force

Describe "Invoke-RemotePowershellMetaRunner" {
    InModuleScope Objectivity.TeamcityMetarunners {
       
        $testFilePath = "Invoke-RemotePowershellMetaRunnerTests.temp.ps1"
        $testFileRemotePath = "c:\test\Invoke-RemotePowershellMetaRunnerTests.temp.ps1"

        if ($Env:WinRmUser) {
            $cred = ConvertTo-PSCredential -User $Env:WinRmUser -Password $Env:WinRmPassword
            $connectionParams = New-ConnectionParameters -Nodes 'localhost' -Credential $cred
        }
        else {
            $connectionParams = New-ConnectionParameters -Nodes 'localhost'
        }

        try { 
            $testExpectedResult = 'TEST'
            $testScriptBody = "Write-Output '$testExpectedResult'"
            New-Item -Path $testFilePath -Force -Value $testScriptBody -ItemType File
            New-Item -Path $testFileRemotePath -Force -Value $testScriptBody -ItemType File

            Context "when neither ScriptFile nor ScriptBody is specified" {
                It "should throw exception" {
                    try { 
                        Invoke-RemotePowershellMetaRunner -ConnectionParams (New-ConnectionParameters)
                    } catch {
                        return
                    }
                    throw 'Expected exception'
                }
            }

            Context "when run locally with no user specified" {

                It "should invoke script locally for ScriptFile" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFilePath -ConnectionParams $connectionParams

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptFile with ScriptFileIsRemotePath" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFileRemotePath -ConnectionParams $connectionParams -ScriptFileIsRemotePath

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptBody with arguments" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody 'param($x) Write-Output $x' -ConnectionParams $connectionParams -ScriptArguments 'TEST'

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for 2 ScriptFiles" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile @($testFilePath,$testFilePath) -ConnectionParams $connectionParams

                   $result.Count | Should be 2
                   $result[0] | Should Be $testExpectedResult
                   $result[1] | Should Be $testExpectedResult
                }

                It "should invoke script locally for 2 ScriptFiles with ScriptFileIsRemotePath" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile @($testFileRemotePath,$testFileRemotePath) -ConnectionParams $connectionParams -ScriptFileIsRemotePath

                   $result.Count | Should be 2
                   $result[0] | Should Be $testExpectedResult
                   $result[1] | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptBody" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody $testScriptBody -ConnectionParams $connectionParams

                   $result | Should Be $testExpectedResult
                }
            }

            # this test is ignored because there is no common user we can hardcode
            <#Context "when run locally with user specified" {

                $cred = ConvertTo-PSCredential -User 'CIUser' -Password ''
                $connectionParams = New-ConnectionParameters -Credential $cred

                It "should invoke script locally for ScriptFile" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFilePath -ConnectionParams $connectionParams

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptBlock" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody $testScriptBody -ConnectionParams $connectionParams

                   $result | Should Be $testExpectedResult
                }
            }#>

            Context "when run remotely" {

                It "should throw exception when ScriptFile does not exist" {
                    try { 
                        Invoke-RemotePowershellMetaRunner -ScriptFile "${testFilePath}.wrong" -ConnectionParams $connectionParams
                    } catch {
                        return
                    }
                    throw 'Expected exception'
                }

                It "should invoke script for ScriptFile" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFilePath -ConnectionParams $connectionParams

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script for ScriptFile with ScriptFileIsRemotePath" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFileRemotePath -ConnectionParams $connectionParams -ScriptFileIsRemotePath

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script for ScriptBlock" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody $testScriptBody -ConnectionParams $connectionParams

                   $result | Should Be $testExpectedResult
                }
            }

            Context "when a scriptblock with non-zero lastexitcode is invoked" {

                It "should fail with error" {
                    try { 
                        $result = Invoke-RemotePowershellMetaRunner -ScriptBody "cmd /c 'exit 1'" -ConnectionParams $connectionParams
                    } catch {
                        return
                    }
                    throw 'Expected exception'
                }
            }

            Context "when a scriptblock with non-zero lastexitcode is invoked and FailOnNonZeroExitCode is false" {

                It "should not fail" {
                    $result = Invoke-RemotePowershellMetaRunner -ScriptBody "cmd /c 'exit 1'" -ConnectionParams $connectionParams -FailOnNonZeroExitCode:$false
                }
            }

        } finally {
            Remove-Item -LiteralPath $testFilePath -Force 
            Remove-Item -LiteralPath $testFileRemotePath -Force 
        }
    }
}
       