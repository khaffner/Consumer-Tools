$APIToken = ''
$UserAgent = ''
$username = ''
$password = ''

Function Get-KolonialItems {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]$Filter
    )

    Begin { 
    }
    Process {
        #Because UTF-8 bug in powershell?
        $Content = Invoke-WebRequest -Uri https://kolonial.no/api/v1/search/?q=$Filter -UserAgent $UserAgent -Headers @{'X-Client-Token'=$APIToken} -ContentType 'application/json;charset=utf-8' | select -ExpandProperty Content
        $CorrectedContent = $Content -replace 'Ã¦','æ' -replace 'Ã†','Æ' -replace 'Ã¸','ø' -replace 'Ã˜','Ø' -replace 'Ã¥','å' -replace 'Ã…','Å'
        $CorrectedContent | ConvertFrom-Json | select -ExpandProperty products
        #Invoke-RestMethod -Uri https://kolonial.no/api/v1/search/?q=$Filter -UserAgent $UserAgent -Headers @{'X-Client-Token'=$Token} -ContentType 'application/json' | select -ExpandProperty products
    }
    End {
    }
}

Function Get-KolonialSessionID {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)][string]$UserName,
        [Parameter(Mandatory)][string]$Password
    )

    Begin { 
    }
    Process {
        $Response = Invoke-RestMethod -Uri https://kolonial.no/api/v1/user/login/ -Method Post -UserAgent $UserAgent -Headers @{'X-Client-Token'=$APIToken} -Body @{'username'=$UserName;'password'=$Password}
        return $Response.sessionID
    }
    End {
    }
}

Function Get-KolonialCart {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)][string]$SessionToken
    )

    Begin {
        $Cookie = New-Object System.Net.Cookie
        $Cookie.Name   = 'sessionid'
        $Cookie.Value  = $SessionToken
        $Cookie.Domain = "kolonial.no"

        $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $WebSession.Cookies.Add($Cookie)
    }
    Process {
        $Response = Invoke-RestMethod -Uri https://kolonial.no/api/v1/cart -Method Get -UserAgent $UserAgent -Headers @{'X-Client-Token'=$APIToken} -WebSession $WebSession
    }
    End {
        return $Response
    }
}

Function Add-KolonialCartItem {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)][string]$SessionToken,
        [Parameter(Mandatory)][int]$ProductID,
                              [int]$Quantity = 1
    )

    Begin {
        $Cookie = New-Object System.Net.Cookie
        $Cookie.Name   = 'sessionid'
        $Cookie.Value  = $SessionToken
        $Cookie.Domain = "kolonial.no"

        $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $WebSession.Cookies.Add($Cookie)
    }
    Process {
        $Response = Invoke-RestMethod -Uri https://kolonial.no/api/v1/cart/items -Method Post -Body @{'items'=@{'product_id'=$ProductID;'quantity'=$Quantity}}  -UserAgent $UserAgent -Headers @{'X-Client-Token'=$APIToken} -WebSession $WebSession
    }
    End {
        return $Response
    }
}

$SessionID = Get-KolonialSessionID -UserName $username -Password $password

Get-KolonialCart -SessionToken $SessionID | select -ExpandProperty items

Add-KolonialCartItem -SessionToken $SessionID -ProductID 26276 -Quantity 3