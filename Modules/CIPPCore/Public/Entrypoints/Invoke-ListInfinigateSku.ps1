function Invoke-ListInfinigateSku {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.Directory.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)
    # Interact with query parameters or the body of the request.
    $TenantFilter = $Request.Query.tenantFilter
    $CurrentSkuOnly = $Request.Query.currentSkuOnly

    try {
        if ($CurrentSkuOnly) {
            $GraphRequest = Get-InfinigateCurrentSubscription -TenantFilter $TenantFilter
        } else {
            $GraphRequest = Get-InfinigateCatalog -TenantFilter $TenantFilter
        }
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $GraphRequest = [PSCustomObject]@{
            name = @(@{value = 'Error getting catalog' })
            sku  = $_.Exception.Message
        }
        $StatusCode = [HttpStatusCode]::InternalServerError
    }

    return [HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = @($GraphRequest)
    }

}
