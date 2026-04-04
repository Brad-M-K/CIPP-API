function Get-InfinigateAuthentication {
    $Table = Get-CIPPTable -TableName Extensionsconfig
    $Config = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).Infinigate
    $APIKey = Get-ExtensionAPIKey -Extension 'Infinigate'

    $BaseURL = $Config.BaseURL.TrimEnd('/')

    $AuthBody = @{
        username = $Config.Username
        password = $APIKey
    } | ConvertTo-Json

    $TokenHeaders = @{
        'Content-Type'       = 'application/json'
        'X-Subscription-Key' = $Config.SubscriptionKey
    }

    $Token = (Invoke-RestMethod -Uri "$BaseURL/token" -Method POST -Headers $TokenHeaders -Body $AuthBody).access_token
    $Result = @{
        Headers = @{
            Authorization        = "Bearer $Token"
            'X-Subscription-Key' = $Config.SubscriptionKey
            'Content-Type'       = 'application/json'
        }
        BaseURL = $BaseURL
    }

    return $Result
}
