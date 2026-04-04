function Invoke-ExecInfinigateLicense {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.Directory.ReadWrite
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)
    $Headers = $Request.Headers

    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Body.tenantFilter
    $Action = $Request.Body.Action
    $ProductId = $Request.Body.ProductId.value ?? $Request.Body.ProductId

    try {
        if ($Action -eq 'Add') {
            $null = Set-InfinigateSubscription -Headers $Headers -TenantFilter $TenantFilter -ProductId $ProductId -Add $Request.Body.Add
        }

        if ($Action -eq 'Remove') {
            $null = Set-InfinigateSubscription -Headers $Headers -TenantFilter $TenantFilter -ProductId $ProductId -Remove $Request.Body.Remove
        }

        if ($Action -eq 'NewSub') {
            $null = Set-InfinigateSubscription -Headers $Headers -TenantFilter $TenantFilter -ProductId $ProductId -Quantity $Request.Body.Quantity
        }
        if ($Action -eq 'Cancel') {
            $null = Remove-InfinigateSubscription -Headers $Headers -TenantFilter $TenantFilter -SubscriptionIds $Request.Body.SubscriptionIds
        }
        $Result = 'Infinigate license change executed successfully.'
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $Result = "Failed to execute Infinigate license change. Error: $_"
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    return [HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = $Result
    }

}
