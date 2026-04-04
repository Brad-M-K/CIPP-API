function Get-InfinigateCatalog {
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomerId,
        [string]$TenantFilter
    )

    if ($TenantFilter) {
        $TenantFilter = (Get-Tenants -TenantFilter $TenantFilter).customerId
        $CustomerId = Get-ExtensionMapping -Extension 'Infinigate' | Where-Object { $_.RowKey -eq $TenantFilter } | Select-Object -ExpandProperty IntegrationId
    }

    if (![string]::IsNullOrEmpty($CustomerId)) {
        Write-Information "Getting Infinigate catalog for customer $CustomerId"
        $Auth = Get-InfinigateAuthentication
        $AllProducts = [System.Collections.Generic.List[object]]::new()
        $Offset = 0
        $Limit = 100

        do {
            $Uri = "$($Auth.BaseURL)/products?offset=$Offset&limit=$Limit"
            $Response = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Auth.Headers
            foreach ($Product in $Response.data) {
                $AllProducts.Add($Product)
            }
            $Offset += $Limit
        } while ($Offset -lt $Response.pagination.total)

        return $AllProducts
    } else {
        throw 'No Infinigate mapping found'
    }
}
