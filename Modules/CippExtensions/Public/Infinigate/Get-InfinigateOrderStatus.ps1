function Get-InfinigateOrderStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OrderId
    )
    $Auth = Get-InfinigateAuthentication
    $Uri = "$($Auth.BaseURL)/orders/$OrderId"
    $Order = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Auth.Headers
    return $Order
}
