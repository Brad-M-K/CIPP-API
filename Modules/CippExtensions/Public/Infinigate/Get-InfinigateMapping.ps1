function Get-InfinigateMapping {
    [CmdletBinding()]
    param (
        $CIPPMapping
    )

    $ExtensionMappings = Get-ExtensionMapping -Extension 'Infinigate'

    $Tenants = Get-Tenants -IncludeErrors
    $Mappings = foreach ($Mapping in $ExtensionMappings) {
        $Tenant = $Tenants | Where-Object { $_.customerId -eq $Mapping.RowKey }
        if ($Tenant) {
            [PSCustomObject]@{
                TenantId        = $Tenant.customerId
                Tenant          = $Tenant.displayName
                TenantDomain    = $Tenant.defaultDomainName
                IntegrationId   = $Mapping.IntegrationId
                IntegrationName = $Mapping.IntegrationName
            }
        }
    }
    try {
        $InfinigateCustomers = Get-InfinigateCustomers | ForEach-Object {
            [PSCustomObject]@{
                name  = $_.name
                value = "$($_.id)"
            }
        }
    } catch {
        $Message = if ($_.ErrorDetails.Message) {
            Get-NormalizedError -Message $_.ErrorDetails.Message
        } else {
            $_.Exception.message
        }

        Write-LogMessage -Message "Could not get Infinigate Customers, error: $Message " -Level Error -tenant 'CIPP' -API 'InfinigateMapping'
        $InfinigateCustomers = @(@{name = "Could not get Infinigate Customers, error: $Message"; value = '-1' })
    }

    $MappingObj = [PSCustomObject]@{
        Companies = @($InfinigateCustomers)
        Mappings  = @($Mappings)
    }

    return $MappingObj
}
