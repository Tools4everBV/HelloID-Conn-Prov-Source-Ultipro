[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

## Settings ##
if($null -eq $configuration){
    $config = [ordered]@{
        ClientAccessKey = "" # CUSTOMER API KEY
        UserAccessKey = "" # USER API KEY -- Not used
        UserName = "HelloID"
        Password = ""
        per_page = 100 # Default 100
    }
}
else {
    $config = ConvertFrom-Json $configuration
}

$apiToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $config.UserName,$config.Password)))

$person_url = "https://service4.ultipro.com/personnel/v1/person-details?per_Page={0}" -f $per_page
$employment_url = "https://service4.ultipro.com/personnel/v1/employment-details?per_Page={0}" -f $per_page
$org_levels_url = "https://service4.ultipro.com/configuration/v1/org-levels"
$locations_url = "https://service4.ultipro.com/configuration/v1/locations"
$jobs_url = "https://service4.ultipro.com/configuration/v1/jobs"
$job_families_url = "https://service4.ultipro.com/configuration/v1/code-tables/JOBFAMILY"

# Pull Job Families (Note: This call does not use Pages)
$mc = Measure-Command {
$job_families = [System.Collections.Generic.List[psobject]]::new()
$splat = @{
    Method = 'GET'
    Uri = "{0}" -f $job_families_url
    Headers = @{'US-Customer-Api-Key' = $config.ClientAccessKey
                Authorization = "Basic " + $apiToken}
    ContentType = 'application/json'
}

$_result = Invoke-RestMethod @splat
$job_families.AddRange([psobject[]]$_result)
}
Write-Verbose -Verbose "Retrieved Job Family Code Table Record(s). $($job_families.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

$return = [System.Collections.Generic.List[psobject]]::new()
$mc = Measure-Command {
Foreach ($row in $job_families)
{
    $item = @{
        ExternalId = "{0}" -f $row.code
        DisplayName = "{0}" -f $row.description
    }
    $return.add($item)
}
}

Write-Verbose -Verbose "Processed Department Return to HelloID: $($return.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

$return | %{ Write-Output ($_ | ConvertTo-Json -Depth 10) }
