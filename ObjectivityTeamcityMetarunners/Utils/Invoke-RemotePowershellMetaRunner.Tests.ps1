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

Import-Module -Name "$PSScriptRoot\..\..\..\PSCI.psd1" -Force

Describe -Tag "PSCI.unit" "Invoke-RemotePowershellMetaRunner" {
    InModuleScope PSCI.teamcityExtensions {

        Mock Write-Log { 
            if ($Critical) {
                throw $Message
            }
        }
        
        $testFilePath = "Invoke-RemotePowershellMetaRunnerTests.temp.ps1"
        $testFileRemotePath = "c:\test\Invoke-RemotePowershellMetaRunnerTests.temp.ps1"

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

                $connParams = New-ConnectionParameters

                It "should invoke script locally for ScriptFile" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFilePath -ConnectionParams $connParams

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptFile with ScriptFileIsRemotePath" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFileRemotePath -ConnectionParams $connParams -ScriptFileIsRemotePath

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptBody with arguments" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody 'param($x) Write-Output $x' -ConnectionParams $connParams -ScriptArguments 'TEST'

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for 2 ScriptFiles" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile @($testFilePath,$testFilePath) -ConnectionParams $connParams

                   $result.Count | Should be 2
                   $result[0] | Should Be $testExpectedResult
                   $result[1] | Should Be $testExpectedResult
                }

                It "should invoke script locally for 2 ScriptFiles with ScriptFileIsRemotePath" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile @($testFileRemotePath,$testFileRemotePath) -ConnectionParams $connParams -ScriptFileIsRemotePath

                   $result.Count | Should be 2
                   $result[0] | Should Be $testExpectedResult
                   $result[1] | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptBody" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody $testScriptBody -ConnectionParams $connParams

                   $result | Should Be $testExpectedResult
                }
            }

            # this test is ignored because there is no common user we can hardcode
            <#Context "when run locally with user specified" {

                $cred = ConvertTo-PSCredential -User 'CIUser' -Password ''
                $connParams = New-ConnectionParameters -Credential $cred

                It "should invoke script locally for ScriptFile" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFilePath -ConnectionParams $connParams

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script locally for ScriptBlock" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody $testScriptBody -ConnectionParams $connParams

                   $result | Should Be $testExpectedResult
                }
            }#>

            Context "when run remotely" {

                $connParams = New-ConnectionParameters -Nodes 'localhost'

                It "should throw exception when ScriptFile does not exist" {
                    try { 
                        Invoke-RemotePowershellMetaRunner -ScriptFile "${testFilePath}.wrong" -ConnectionParams $connParams
                    } catch {
                        return
                    }
                    throw 'Expected exception'
                }

                It "should invoke script for ScriptFile" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFilePath -ConnectionParams $connParams

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script for ScriptFile with ScriptFileIsRemotePath" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptFile $testFileRemotePath -ConnectionParams $connParams -ScriptFileIsRemotePath

                   $result | Should Be $testExpectedResult
                }

                It "should invoke script for ScriptBlock" {
                   $result = Invoke-RemotePowershellMetaRunner -ScriptBody $testScriptBody -ConnectionParams $connParams

                   $result | Should Be $testExpectedResult
                }
            }

            Context "when a scriptblock with non-zero lastexitcode is invoked" {

                $connParams = New-ConnectionParameters

                It "should fail with error" {
                    try { 
                        $result = Invoke-RemotePowershellMetaRunner -ScriptBody "cmd /c 'exit 1'" -ConnectionParams $connParams
                    } catch {
                        return
                    }
                    throw 'Expected exception'
                }
            }

            Context "when a scriptblock with non-zero lastexitcode is invoked and FailOnNonZeroExitCode is false" {

                $connParams = New-ConnectionParameters

                It "should not fail" {
                    $result = Invoke-RemotePowershellMetaRunner -ScriptBody "cmd /c 'exit 1'" -ConnectionParams $connParams -FailOnNonZeroExitCode:$false
                }
            }

        } finally {
            Remove-Item -LiteralPath $testFilePath -Force 
            Remove-Item -LiteralPath $testFileRemotePath -Force 
        }
    }
}
       