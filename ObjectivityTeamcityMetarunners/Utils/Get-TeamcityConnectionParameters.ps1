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

function Get-TeamcityConnectionParameters {

    <#
    .SYNOPSIS
    Creates an universal connection parameters object that can be conveniently used for opening connections.

    .PARAMETER Nodes
    Names of remote nodes where the connection will be established.

    .PARAMETER User
    User that will be used for opening remote connection.

    .PARAMETER Password
    Password that will be used for opening remote connection.

    .PARAMETER Authentication
    Defines type of authentication that will be used to establish remote conncetion.

    .PARAMETER Port
    Defines the port used for establishing remote connection.

    .PARAMETER UseHttps
    If true, HTTPS will be used (HTTP otherwise).

    .EXAMPLE
    Get-TeamcityConnectionParameters -Nodes $nodes -User '%user%'
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]
        $Nodes,

        [Parameter(Mandatory=$false)]
        [string] 
        $User,

        [Parameter(Mandatory=$false)]
        [string] 
        $Password,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'Basic', 'NTLM', 'Credssp', 'Default', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [string]
        $Authentication,

        [Parameter(Mandatory=$false)]
        [string]
        $Port,

        [Parameter(Mandatory=$false)]
        [switch]
        $UseHttps
    )

    if ($User -and !$Password) {
        throw "Please specify password for given user ('$User')."
    }

    $params = @{
        Nodes = $Nodes
        Authentication = $Authentication
        Port = $Port
    }
    if ($User) {
        $params.Credential = ConvertTo-PSCredential -User $User -Password $Password
    }
    if ($UseHttps) {
        $params.Protocol = 'HTTPS'
    }

    return New-ConnectionParameters @params
}