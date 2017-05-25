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

Describe "Get-TeamcityHashtableParameter" {
    InModuleScope Objectivity.TeamcityMetarunners {
        Context "when supplied a string with escaped commas" {
            It "should return one-element hashtable" {
               $result = Get-TeamcityHashtableParameter -Param 'key=value1\,key2=va\\lue2'

               $result | Should Not Be $null
               $result.Count | Should Be 1
               $result.key | Should Be 'value1,key2=va\lue2'
            }
        }
        
        Context "when supplied a string with unescaped ," {
            It "should return two-element hashtable without \n" {
               $result = Get-TeamcityHashtableParameter -Param "key1=value1,key2=value2\\,key3=value3"

               $result | Should Not Be $null
               $result.Count | Should Be 3
               $result.key1 | Should Be 'value1'
               $result.key2 | Should Be 'value2\'
               $result.key3 | Should Be 'value3'
            }
        }

        Context "when supplied a string with \n" {
            It "should return two-element hashtable without \n" {
               $result = Get-TeamcityHashtableParameter -Param "key1=value1`nkey2=value2"

               $result | Should Not Be $null
               $result.Count | Should Be 2
               $result.key1 | Should Be 'value1'
               $result.key2 | Should Be 'value2'
            }
        }

        Context "when supplied a string with \n and empty lines" {
            It "should return two-element hashtable without empty lines" {
               $result = Get-TeamcityHashtableParameter -Param "key1=value1`n`nkey2=value2"

               $result | Should Not Be $null
               $result.Count | Should Be 2
               $result.key1 | Should Be 'value1'
               $result.key2 | Should Be 'value2'
            }
        }

        Context "when supplied a string with \r\n" {
            It "should return two-element hashtable without \r\n" {
               $result = Get-TeamcityHashtableParameter -Param "key1=value1`r`nkey2=value2"

               $result | Should Not Be $null
               $result.Count | Should Be 2
               $result.key1 | Should Be 'value1'
               $result.key2 | Should Be 'value2'
            }
        }

        Context "when supplied a string with special characters" {
            It "should return proper hashtable" {
               $result = Get-TeamcityHashtableParameter -Param "key1=&\x:\,?/!"

               $result | Should Not Be $null
               $result.Count | Should Be 1
               $result.key1 | Should Be '&\x:,?/!'
            }
        }
    }
}
       