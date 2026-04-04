function Remove-InfinigateSubscription {
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [Parameter(Mandatory = $true)]
        [string[]]$SubscriptionIds,
        [string]$TenantFilter,
        $Headers
    )

    if ($Headers) {
        # Get extension config and check for AllowedCustomRoles
        $Table = Get-CIPPTable -TableName Extensionsconfig
        $ExtensionConfig = (Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json
        $Config = $ExtensionConfig.Infinigate

        $AllowedRoles = $Config.AllowedCustomRoles.value
        if ($AllowedRoles -and $Headers.'x-ms-client-principal') {
            $UserRoles = Get-CIPPAccessRole -Headers $Headers
            $Allowed = $false
            foreach ($Role in $UserRoles) {
                if ($AllowedRoles -contains $Role) {
                    Write-Information "User has allowed CIPP role: $Role"
                    $Allowed = $true
                    break
                }
            }
            if (-not $Allowed) {
                throw 'This user is not allowed to modify Infinigate subscriptions.'
            }
        }
    }

    if ($TenantFilter) {
        $TenantFilter = (Get-Tenants -TenantFilter $TenantFilter).customerId
        $CustomerId = Get-ExtensionMapping -Extension 'Infinigate' | Where-Object { $_.RowKey -eq $TenantFilter } | Select-Object -ExpandProperty IntegrationId
    }
    $Auth = Get-InfinigateAuthentication

    $Results = foreach ($SubId in $SubscriptionIds) {
        $Body = @{
            customerId = $CustomerId
            type       = 'cancellation'
            items      = @(
                @{
                    subscriptionId = $SubId
                }
            )
        } | ConvertTo-Json -Depth 10

        $Uri = "$($Auth.BaseURL)/orders"
        Invoke-RestMethod -Uri $Uri -Method POST -Headers $Auth.Headers -Body $Body
    }
    return $Results
}
