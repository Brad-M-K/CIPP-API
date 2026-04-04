function Get-InfinigateCustomers {
    $Auth = Get-InfinigateAuthentication
    $AllCustomers = [System.Collections.Generic.List[object]]::new()
    $Offset = 0
    $Limit = 100

    do {
        $Uri = "$($Auth.BaseURL)/customers?offset=$Offset&limit=$Limit"
        $Response = Invoke-RestMethod -Uri $Uri -Method GET -Headers $Auth.Headers
        foreach ($Customer in $Response.data) {
            $AllCustomers.Add($Customer)
        }
        $Offset += $Limit
    } while ($Offset -lt $Response.pagination.total)

    return $AllCustomers
}
