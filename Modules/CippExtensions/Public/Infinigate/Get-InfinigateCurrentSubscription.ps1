function Get-InfinigateCurrentSubscription {
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantFilter,
        [string]$CustomerId,
        [string]$SubscriptionId,
        [string]$ProductName
    )
    if ($TenantFilter) {
        $TenantFilter = (Get-Tenants -TenantFilter $TenantFilter).customerId
        $CustomerId = Get-ExtensionMapping -Extension 'Infinigate' | Where-Object { $_.RowKey -eq $TenantFilter } | Select-Object -ExpandProperty IntegrationId
    }

    Write-Information "Getting current Infinigate subscriptions for customer $CustomerId"
    $Auth = Get-InfinigateAuthentication
    $AllSubscriptions = [System.Collections.Generic.List[object]]::new()
    $Offset = 0
    $Limit = 100

    do {
        $Uri = "$($Auth.BaseURL)/subscriptions?offset=$Offset&limit=$Limit"
        $Response = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Auth.Headers
        foreach ($Sub in $Response.data) {
            $AllSubscriptions.Add($Sub)
        }
        $Offset += $Limit
    } while ($Offset -lt $Response.pagination.total)

    if ($SubscriptionId) {
        return $AllSubscriptions | Where-Object { $_.id -eq $SubscriptionId }
    } elseif ($ProductName) {
        return $AllSubscriptions | Where-Object { $_.productName -eq $ProductName }
    } else {
        return $AllSubscriptions
    }
}
