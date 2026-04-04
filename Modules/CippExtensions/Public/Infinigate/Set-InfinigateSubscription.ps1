function Set-InfinigateSubscription {
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [Parameter(Mandatory = $true)]
        [string]$ProductId,
        [int]$Quantity,
        [int]$Add,
        [int]$Remove,
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
    $ExistingSubscription = Get-InfinigateCurrentSubscription -CustomerId $CustomerId | Where-Object { $_.id -eq $ProductId -or $_.productId -eq $ProductId }

    if (-not $ExistingSubscription) {
        if ($Add -or $Remove) {
            throw "Unable to Add or Remove. No existing subscription with product '$ProductId' found."
        }

        if (-not $Quantity -or $Quantity -le 0) {
            throw 'A valid Quantity must be specified to create a new subscription when none currently exists.'
        }
        $OrderBody = @{
            customerId = $CustomerId
            type       = 'sales'
            items      = @(
                @{
                    productId = $ProductId
                    quantity  = $Quantity
                }
            )
        } | ConvertTo-Json -Depth 10

        $OrderUri = "$($Auth.BaseURL)/orders"
        $Order = Invoke-RestMethod -Uri $OrderUri -Method POST -Headers $Auth.Headers -Body $OrderBody
        return $Order

    } else {
        $SubscriptionId = $ExistingSubscription[0].id
        $CurrentQuantity = $ExistingSubscription[0].quantity

        if ($Add) {
            $FinalQuantity = $CurrentQuantity + $Add
        } elseif ($Remove) {
            $FinalQuantity = $CurrentQuantity - $Remove
            if ($FinalQuantity -lt 0) {
                throw "Cannot remove more licenses than currently allocated. Current: $CurrentQuantity, Attempting to remove: $Remove."
            }
        } else {
            if (-not $Quantity -or $Quantity -le 0) {
                throw 'A valid Quantity must be specified if Add/Remove are not used.'
            }
            $FinalQuantity = $Quantity
        }
        $Body = @{
            customerId = $CustomerId
            type       = 'change'
            items      = @(
                @{
                    subscriptionId = $SubscriptionId
                    quantity       = $FinalQuantity
                }
            )
        } | ConvertTo-Json -Depth 10

        $Uri = "$($Auth.BaseURL)/orders"
        $Update = Invoke-RestMethod -Uri $Uri -Method POST -Headers $Auth.Headers -Body $Body
        return $Update
    }
}
