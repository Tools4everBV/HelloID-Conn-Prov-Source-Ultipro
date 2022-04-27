[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$InformationPreference = 'Continue'

## Settings ##
if($null -eq $configuration){
    $config = [ordered]@{
        ClientAccessKey = "" # CUSTOMER API KEY
        UserAccessKey = "" # USER API KEY -- Not used
        UserName = "HelloID"
        Password = ""
        per_page = 100 # Default 100
        EmployeeNumber_Override_CSV = ''
    }
}
else {
    $config = ConvertFrom-Json $configuration
}

$apiToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $config.UserName,$config.Password)))

$person_url = "https://service4.ultipro.com/personnel/v1/person-details?per_Page={0}" -f $config.per_page
$employment_url = "https://service4.ultipro.com/personnel/v1/employment-details?per_Page={0}" -f $config.per_page
$org_levels_url = "https://service4.ultipro.com/configuration/v1/org-levels"
$locations_url = "https://service4.ultipro.com/configuration/v1/locations"
$jobs_url = "https://service4.ultipro.com/configuration/v1/jobs"
$job_families_url = "https://service4.ultipro.com/configuration/v1/code-tables/JOBFAMILY"

# Pull Person Demographics
$mc = Measure-Command {
$page = 1
$persons = [System.Collections.Generic.List[psobject]]::new()
do {
    $splat = @{
        Method = 'GET'
        Uri = "{0}&page={1}" -f $person_url,$page++
        Headers = @{'US-Customer-Api-Key' = $config.ClientAccessKey
                    Authorization = "Basic " + $apiToken}
        ContentType = 'application/json'
		ErrorAction = 'Stop'
    }

	try {
		$_result = Invoke-RestMethod @splat
	} catch
	{
		Write-Information ('Error Caught.  Retrying.  Error was: {0}' -f $_)
		Start-Sleep -seconds 5
		$_result = Invoke-RestMethod @splat
	}
    $persons.AddRange([psobject[]]$_result)
    Write-Information ("  Pulling Persons: {0}" -f $persons.count)

} while ($_result.count -gt 0)
}
Write-Information "Retrieved Person Record(s). $($persons.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

# Pull Employment Details
$mc = Measure-Command {
$page = 1
$employments = [System.Collections.Generic.List[psobject]]::new()
do {
    $splat = @{
        Method = 'GET'
        Uri = "{0}&page={1}" -f $employment_url,$page++
        Headers = @{'US-Customer-Api-Key' = $config.ClientAccessKey
                    Authorization = "Basic " + $apiToken}
        ContentType = 'application/json'
		ErrorAction = 'Stop'
    }

	try {
		$_result = Invoke-RestMethod @splat
	} catch
	{
		Write-Information ('Error Caught.  Retrying.  Error was: {0}' -f $_)
		Start-Sleep -seconds 5
		$_result = Invoke-RestMethod @splat
	}
    $employments.AddRange([psobject[]]$_result)
    Write-Information ("  Pulling Employments: {0}" -f $employments.count)

} while ($_result.count -gt 0)
}
Write-Information "Retrieved Employment Record(s). $($employments.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

# Pull Org Units (Note: This call does not use Pages)
$mc = measure-command {
$org_levels = [system.collections.generic.list[psobject]]::new()
$splat = @{
    method = 'get'
    uri = "{0}" -f $org_levels_url
	headers = @{'us-customer-api-key' = $config.clientaccesskey
                authorization = "basic " + $apitoken}
	contenttype = 'application/json'
}

$_result = invoke-restmethod @splat
$org_levels.addrange([psobject[]]$_result)
}
Write-Information "Retrieved org level record(s). $($org_levels.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

# Pull Locations (Note: This call does not use Pages)
$mc = Measure-Command {
$locations = [System.Collections.Generic.List[psobject]]::new()
$splat = @{
    Method = 'GET'
    Uri = "{0}" -f $locations_url
    Headers = @{'US-Customer-Api-Key' = $config.ClientAccessKey
                Authorization = "Basic " + $apiToken}
    ContentType = 'application/json'
}
$_result = Invoke-RestMethod @splat
$locations.AddRange([psobject[]]$_result)

}
Write-Information "Retrieved Location Record(s). $($locations.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

# Pull Jobs (Note: This call does not use Pages)
$mc = Measure-Command {
$jobs = [System.Collections.Generic.List[psobject]]::new()
$splat = @{
    Method = 'GET'
    Uri = "{0}" -f $jobs_url
    Headers = @{'US-Customer-Api-Key' = $config.ClientAccessKey
                Authorization = "Basic " + $apiToken}
    ContentType = 'application/json'
}

$_result = Invoke-RestMethod @splat
$jobs.AddRange([psobject[]]$_result)
}
Write-Information "Retrieved Job Record(s). $($jobs.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

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
Write-Information "Retrieved Job Family Code Table Record(s). $($job_families.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

#region Get Employee Cell Phones
#region Get Authentication Token
try {
  $splat = @{
    Method = 'Post'
    Uri = "https://service4.ultipro.com/services/LoginService"
    Body = @"
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:log="http://www.ultipro.com/services/loginservice" xmlns:con="http://www.ultipro.com/contracts">
   <soap:Header xmlns:wsa="http://www.w3.org/2005/08/addressing">
      <log:UserName>{0}</log:UserName>
      <log:UserAccessKey>{1}</log:UserAccessKey>
      <log:Password>{2}</log:Password>
      <log:ClientAccessKey>{3}</log:ClientAccessKey>
   <wsa:Action>http://www.ultipro.com/services/loginservice/ILoginService/Authenticate</wsa:Action></soap:Header>
   <soap:Body>
      <con:TokenRequest/>
   </soap:Body>
</soap:Envelope>
"@ -f $config.UserName,$config.UserAccessKey,$config.Password,$config.ClientAccessKey
    Headers = @{
      'Content-Type' = 'application/soap+xml;charset=UTF-8;Action="http://www.ultipro.com/services/loginservice/ILoginService/Authenticate"'
    }
  }
  $result = Invoke-RestMethod @splat
  $authenticationToken = $result.Envelope.Body.TokenResponse.Token.'#text'
}
catch {
  $_ | Select-Object * -ExpandProperty ErrorDetails | Select-Object -ExpandProperty Message
}
#endregion Get Authentication Token

#region Employee Phone Service Lookup
$splat = @{
    uri = "https://service4.ultipro.com/services/employeephoneinformation"
    Method = 'Post'
    headers = @{
        'Content-Type' = 'application/soap+xml;charset=UTF-8;Action="http://www.ultipro.com/services/employeephoneinformation/IEmployeePhoneInformation/FindPhoneInformations"'
    }
	ErrorAction = 'Stop'
}

$pageNumber = 1
$result_phones = [System.Collections.Generic.List[object]]::new()
do{
$splat['body'] = @"
    <s:Envelope xmlns:a="http://www.w3.org/2005/08/addressing" xmlns:s="http://www.w3.org/2003/05/soap-envelope">
        <s:Header>
        <a:Action s:mustUnderstand="1">http://www.ultipro.com/services/employeephoneinformation/IEmployeePhoneInformation/FindPhoneInformations</a:Action>
        <UltiProToken xmlns="http://www.ultimatesoftware.com/foundation/authentication/ultiprotoken">{0}</UltiProToken>
        <ClientAccessKey xmlns="http://www.ultimatesoftware.com/foundation/authentication/clientaccesskey">{1})</ClientAccessKey>
        </s:Header>
        <s:Body>
        <FindPhoneInformations xmlns="http://www.ultipro.com/services/employeephoneinformation">
            <query xmlns:b="http://www.ultipro.com/contracts" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
              <b:PageNumber>{2}</b:PageNumber>
              <b:PageSize>{3}</b:PageSize>
            </query>
        </FindPhoneInformations>
        </s:Body>
    </s:Envelope>
"@ -f $authenticationToken,$config.ClientAccessKey,$pageNumber,$config.per_page

    #
	try {
		$_result = Invoke-RestMethod @splat #-Method Post -Uri $uri -Headers $headers -Body $xml
	} catch
	{
		Write-Information ('Error Caught.  Retrying.  Error was: {0}' -f $_)
		Start-Sleep -seconds 5
		$_result = Invoke-RestMethod @splat #-Method Post -Uri $uri -Headers $headers -Body $xml
	}
    if($null -ne $_result.Envelope.Body.FindPhoneInformationsResponse.FindPhoneInformationsResult.Results.EmployeePhoneInformation)
    {
        $result_phones.AddRange($_result.Envelope.Body.FindPhoneInformationsResponse.FindPhoneInformationsResult.Results.EmployeePhoneInformation)
    }
    Write-Information ("Page {0} - Count: {1}" -f $pageNumber++,$result_phones.Count)
} while ($_result.Envelope.Body.FindPhoneInformationsResponse.FindPhoneInformationsResult.Results.EmployeePhoneInformation -ne $null `
        -AND $_result.Envelope.Body.FindPhoneInformationsResponse.FindPhoneInformationsResult.Results.EmployeePhoneInformation.Count -eq $config.per_page)

$phones = [System.Collections.Generic.List[object]]::new()
foreach ($phone in $result_phones){
    if($null -ne $phone.PhoneInformations.PhoneInformation.AlternateNumbers.AlternateNumber)
    {
        $row = [ordered]@{
            CompanyCode = $phone.CompanyCode
            EmployeeNumber = $phone.EmployeeNumber
            FirstName = $phone.FirstName
            LastName = $phone.LastName
        }
        foreach ($an in $phone.PhoneInformations.PhoneInformation.AlternateNumbers.AlternateNumber) {
            if($an.Type -eq 'CEL')
            {
                $row['Type'] = $an.Type
                $row['IsPrivate'] = $an.IsPrivate
                $row['Number'] = $an.Number
            }
        }
        $phones.add([pscustomobject]$row)
    }
}
#endregion Employee Phone Service Lookup
#endregion Get Employee Cell Phones

##  Process Person Returns
$employments_ht = $employments | Group-Object employeeID -AsHashTable
$org_levels | % {$_ | Add-Member -NotePropertyName 'Key' -NotePropertyValue ('{0}-{1}' -f $_.code,$_.level)}
$org_levels_ht = $org_levels | Group-Object Key -AsHashTable
$locations_ht = $locations | Group-Object locationCode -AsHashTable
$jobs_ht = $jobs | Group-Object jobCode -AsHashTable
$job_families_ht = $job_families | Group-Object code -AsHashTable
$phones_ht = $phones | Group-Object 'EmployeeNumber' -AsHashTable
$supervisors_ht = $employments | ? {![string]::IsNullOrEmpty($_.supervisorID) -and ($_.employeeStatusCode -ne "T")} | Group-Object 'supervisorID' -AsHashTable

$person_fields = @("employeeId","companyId","userName","firstName","middleName","lastName","preferredName","emailAddress","emailAddressAlternate","homePhone","homePhoneCountry","addressLine1","addressLine2",
                    "addressLine3","addressLine4","addressCity","addressState","addressZipCode","addressCountry","addressCounty","dateOfBirth","gender")
$employment_fields = @("companyID","companyCode","companyName","employeeID","jobDescription","payGroupDescription","primaryJobCode","orgLevel1Code","orgLevel2Code",
                        "orgLevel3Code","orgLevel4Code","originalHireDate","lastHireDate","fullTimeOrPartTimeCode","primaryWorkLocationCode","languageCode","primaryProjectCode",
                        "workPhoneNumber","workPhoneExtension","workPhoneCountry","employeeTypeCode","employeeStatusCode","employeeNumber","supervisorID","supervisorEmployeeNumber",
                        "supervisorFirstName","supervisorLastName","dateOfTermination","mailstop","positionCode","scheduledFTE","scheduledWorkHrs","unionLocal","unionNational")

$return = [System.Collections.Generic.List[psobject]]::new()
$mc = Measure-Command {
    foreach ($p in $persons) {
        
        $person = [ordered]@{
            ExternalId = $p.employeeID
            DisplayName = "{0} {1} - ({2})" -f $p.firstName,$p.lastName,$p.employeeId
        }

        foreach($prop in $p.PSObject.properties)
        {
            if($person_fields -Contains $prop.Name)
            {
                $person[$prop.Name] = "{0}" -f $prop.Value
            }
        }

        $person['Contracts'] = [System.Collections.Generic.List[psobject]]::new()

        foreach ($c in $employments_ht[$p.employeeID])
        {
            $contract = [ordered]@{
                ExternalId = "{0}-{1}-{2}" -f $c.employeeId,$c.primaryJobCode,$c.lastHireDate
            }
            foreach($prop in $c.PSObject.properties)
            {
                if($employment_fields -Contains $prop.Name)
                {
                    $contract[$prop.Name] = "{0}" -f $prop.Value
                }
            }
            $contract["orgLevel1"] = "{0}" -f $org_levels_ht["{0}-1" -f ($contract["orgLevel1Code"])].description
            $contract["orgLevel2"] = "{0}" -f $org_levels_ht["{0}-2" -f ($contract["orgLevel2Code"])].description
            $contract["orgLevel3"] = "{0}" -f $org_levels_ht["{0}-3" -f ($contract["orgLevel3Code"])].description
            $contract["orgLevel4"] = "{0}" -f $org_levels_ht["{0}-4" -f ($contract["orgLevel4Code"])].description
            $contract["jobFamilyCode"] = "{0}" -f $jobs_ht[$contract["primaryJobCode"]].jobFamilyCode
            $contract["jobFamilyDescription"] = "{0}" -f $(if($null -ne $jobs_ht[$contract["primaryJobCode"]]){$job_families_ht[$jobs_ht[$contract["primaryJobCode"]].jobFamilyCode].description}else{""})
            $contract['primaryWorkLocation'] = $locations_ht[$c.primaryWorkLocationCode][0]
            $contract['Mobile'] = ''

            # Add Mobile Number if not marked Private
            if($null -ne $phones_ht[$c.employeeNumber] -AND $phones_ht[$c.employeeNumber][0].IsPrivate -eq 'false')
            {
                $contract['Mobile'] = $phones_ht[$c.employeeNumber][0].Number
            }
          
            # 2Add 'HasDirectReports' to queue all accounts with direct reports
            $contract["HasDirectReports"] = $supervisors_ht.keys -contains $p.employeeID.toString()


            $person.Contracts.Add($contract)
        }
        $return.add($person)
    }
}

Write-Information "Processed Core Person Return: $($return.count) returned in $($mc.days):$($mc.hours):$($mc.minutes):$($mc.seconds).$($mc.milliseconds)"

$return | %{ Write-Output ($_ | ConvertTo-Json -Depth 10) }
Write-Information ("Finished Processing Persons: {0}" -f $return.count)
