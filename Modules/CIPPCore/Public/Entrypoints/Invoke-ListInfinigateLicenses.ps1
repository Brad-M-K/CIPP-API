function Invoke-ListInfinigateLicenses {
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

    try {
        $Result = Get-InfinigateCurrentSubscription -TenantFilter $TenantFilter
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $Result = 'Unable to retrieve Infinigate subscriptions, ensure that you have enabled the Infinigate integration and mapped the tenant in the integration settings.'
        $StatusCode = [HttpStatusCode]::BadRequest
    }

    return [HttpResponseContext]@{
        StatusCode = $StatusCode
        Body       = @($Result)
    }

}
