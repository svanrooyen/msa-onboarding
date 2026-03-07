<#
MSA Entra Onboarding - Chunked PowerShell
Version: 0.14.0

GOAL
- Manual-run onboarding from CSV export of MS Form spreadsheet.
- Safe by default: supports -WhatIf and -SkipExisting.
- Decouples campus defaults from M365 templates by storing them in config (later can be moved to SharePoint Lists).

NOTES
- Uses Microsoft Graph PowerShell SDK.
- Designed to be run manually in controlled stages before any scheduling.

FUTURE ROADMAP (Tracked Enhancements)
--------------------------------------
The following items are intentionally NOT implemented yet, but planned.
This section acts as a living backlog to prevent logic creep inside the core script.

0) Personal Email Capture in Entra (Privacy Review Required)
   - Evaluate storing personal email in user.otherMails.
   - Confirm organisational stance on privacy and visibility.
   - Decide on convention:
       - Is first otherMails entry always personal email?
       - Or should we search by value rather than rely on index position?
   - Ensure email is only used for onboarding + payslip delivery purposes.
   - Consider future reporting and offboarding implications.

1) Multi-Campus Parsing
   - Support semicolon or comma-separated campus values in CSV.
   - Normalise each campus key individually.
   - Apply fuzzy "Did you mean" suggestion per campus token.
   - Add user to multiple campus baseline groups safely.

2) Exception Flags (Driven by Source CSV, NOT hard-coded logic)
   - AllCampuses = Y/N
     -> If Y, add to group: MSA-Exception-AllCampuses (if exists).
   - NeedsMSVAccess = Y/N
     -> If Y, add to group: MSA-Exception-MSV-Access (if exists).
   - Any future exception types must be expressed as CSV flags first,
     then mapped to explicit named groups.

3) Onboarding Email Automation (MVP Completion Step)
   - Generate onboarding email body automatically.
   - Send to personal email address.
   - CC new work email.
   - CC state-based HR Recruitment shared mailbox.
   - Include: UPN, temporary password, first sign-in instructions.
   - Optional: attach PDF quick-start guide.

4) Manager Field Population
   - Accept manager UPN or email from CSV.
   - Set manager relationship via Graph.
   - Future bulk-update script for tenant-wide org chart population.

5) Shared Mailbox Send Model (Email Governance)
   - Option to send onboarding email from dedicated unmonitored shared mailbox.
   - Evaluate audit, reply handling, and ownership model.
   - Decide whether sender identity is:
       - Named IT staff member
       - Generic IT function (preferred long-term)

6) Role-Based Licence Mapping
   - Replace single A3 assignment with role-driven licence map.
   - Controlled mapping table in config or external list.

7) Structured Logging
   - Add file-based logging alongside console output.
   - Log path configurable via Config (e.g. C:\Temp\MsaOnboarding-yyyy-MM-dd.log).
   - Log levels: INFO, WARN, ERROR.
   - Capture: user creation, licence assignment, group membership, skips, errors.
   - Consider transcript-based approach (Start-Transcript) as interim quick win.

8) CSV Input Validation (NEXT PRIORITY)
   - Validate all rows before processing any (fail-fast, no partial runs).
   - Required fields: First Name, Surname, Campus, Mobile, Personal Email Address.
   - Warn on optional missing fields (e.g. Job Title).
   - Validate campus exists in CampusDefaults before hitting Graph.
   - Validate mobile number format is parseable.
   - Output a clear pass/fail summary per row so the CSV can be fixed and re-run.
   - Consider wrapping individual user creation in try/catch to prevent one bad row
     from killing the rest of the batch (similar to licence failure handling).

Design Principle:
Keep core onboarding deterministic and minimal.
Push variation to structured input (CSV flags, mapping tables), not inline conditional logic.

- You MUST fill in SKU IDs and (optionally) Group IDs.

CHANGELOG
- 0.14.0: Replaced Get-Random with cryptographic RNG in New-SecurePassword; fleshed out all campus
           group mappings with placeholder IDs; wired email template into onboarding loop to output
           per-user HTML files for manual send; added logging roadmap item (7); added LogPath and
           OnboardingEmailOutputDir to config.
- 0.13.0: Fixed syntax errors (duplicate param block in Get-UniqueUpn, orphaned code in Resolve-CampusDefaults,
           misplaced brace in Invoke-MsaEntraOnboardingFromCsv), removed dead code in Get-ClosestCampusKey,
           added Normalise-MobileNumber stub, cached verified domains, fixed UPN collision domain bug,
           fixed Olympic Park postcode, cleaned up roadmap duplicates, fixed usage block syntax.
- 0.12.0: Wired TEST domain to sslvrnet.onmicrosoft.com and set Business Basic (O365_BUSINESS_ESSENTIALS) SKUId for personal-tenant test runs.
- 0.10.0: Added multi-domain UPN logic (QLD/VIC/NSW/TAS) with state-based selection and verified-domain guard; added fixed-domain override for personal-tenant testing.
- 0.9.0: Added selectable default licence SKU key (A3 vs Business Basic) for easy personal-tenant testing.
- 0.8.0: Converted QLD onboarding email template to formatted HTML (headings, bold sections, bullet list, hyperlinks).
- 0.7.0: Added onboarding email template generator (QLD variant) and roadmap item for shared mailbox send model.
- 0.6.0: Added roadmap item to evaluate storing personal email in Entra (otherMails) including privacy considerations and ordering convention.
- 0.5.0: Added structured FUTURE ROADMAP section in comments to track planned enhancements (multi-campus parsing, exception flags, onboarding email automation, manager population, role-based licence mapping).
- 0.4.0: Added fuzzy campus name guard with closest-match suggestion to prevent mis-typed campus values.
- 0.3.0: Added campus key normalisation and mobile number normalisation scaffolding; commented out NZ campus per org boundary preference.
- 0.2.0: Added -WhatIf and -SkipExisting design; refactored into functions; added safer logging scaffolding.
- 0.1.0: Initial draft.
#>

# Import only the Graph sub-modules this script needs (much faster than loading the full Microsoft.Graph module)
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Teams

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================
# CONFIG
# =========================

$Script:Config = [ordered]@{
  TenantDomain   = 'msa.qld.edu.au'
  UsageLocation  = 'AU'

  # Output directory for per-user onboarding email HTML files
  # Each file can be opened and copy-pasted into an Outlook draft
  OnboardingEmailOutputDir = '.\outputs'

  # TODO (Roadmap item 7): Structured log file path
  # LogPath = 'C:\Temp\MsaOnboarding.log'

  # UPN Domain selection mode
  # - AutoByCampusState: Choose domain based on the campus defaults 'State' field (QLD/VIC/NSW/TAS)
  # - Fixed: Always use FixedTenantDomain (recommended for personal-tenant testing)
  UpnDomainMode = 'AutoByCampusState'
  # UpnDomainMode = 'Fixed'

  # Fixed-domain override (personal tenant testing)
  FixedTenantDomain = 'sslvrnet.onmicrosoft.com'  # Personal tenant (Steve)

  # MSA domains by state
  TenantDomainsByState = [ordered]@{
    QLD  = 'msa.qld.edu.au'
    VIC  = 'msv.vic.edu.au'
    NSW  = 'msa.nsw.edu.au'
    TAS  = 'msa.tas.edu.au'
    TEST = 'sslvrnet.onmicrosoft.com'  # Lab / personal tenant (Steve)
  }

  # Default licence to assign during onboarding.
  # For MSA production: keep A3.
  # For personal tenant testing: switch to M365_BUSINESS_BASIC.
  # DefaultLicenceSkuKey = 'M365_A3_FACULTY'
  DefaultLicenceSkuKey = 'M365_BUSINESS_BASIC'

  # Licence SKU IDs (fill these from your tenant)
  # Get-MgSubscribedSku | Select SkuPartNumber,SkuId
  Sku = [ordered]@{
    M365_A3_FACULTY        = '00000000-0000-0000-0000-000000000000'  # TODO
    M365_BUSINESS_BASIC    = '3b555118-da6a-4418-894f-7df1e2096870'  # Business Basic (O365_BUSINESS_ESSENTIALS)
  }

  # Optional: Group IDs (fill in if desired)
  Groups = [ordered]@{
    # Campus groups
    CAMPUS_BEENLEIGH     = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_BUNDOORA      = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_CAIRNS        = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_COOLANGATTA   = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_LAUNCESTON    = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_MITCHELTON    = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_OLYMPICPARK   = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_SOUTHPORT     = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_SPRINGFIELD   = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_VARSITY       = '00000000-0000-0000-0000-000000000000' # TODO
    CAMPUS_CORPORATE     = '00000000-0000-0000-0000-000000000000' # TODO
    # CAMPUS_ARAPAKI     = '00000000-0000-0000-0000-000000000000' # NZ - not managed by MSA IT

    # Role groups
    ROLE_ASSISTANT_TEACHER  = '00000000-0000-0000-0000-000000000000' # TODO
    ROLE_PERSONAL_ASSISTANT = '00000000-0000-0000-0000-000000000000' # TODO
  }

  # Campus name -> group key mapping
  # Keys here must match the normalised campus name (lowercase) used in CampusDefaults
  CampusToGroupKey = [ordered]@{
    beenleigh   = 'CAMPUS_BEENLEIGH'
    bundoora    = 'CAMPUS_BUNDOORA'
    cairns      = 'CAMPUS_CAIRNS'
    coolangatta = 'CAMPUS_COOLANGATTA'
    launceston  = 'CAMPUS_LAUNCESTON'
    mitchelton  = 'CAMPUS_MITCHELTON'
    olympicpark = 'CAMPUS_OLYMPICPARK'
    southport   = 'CAMPUS_SOUTHPORT'
    springfield = 'CAMPUS_SPRINGFIELD'
    varsity     = 'CAMPUS_VARSITY'
    corporate   = 'CAMPUS_CORPORATE'
    # arapaki   = 'CAMPUS_ARAPAKI'  # NZ - not managed by MSA IT
  }

  # Job title -> role group mapping (optional)
  JobTitleToRoleGroupKey = [ordered]@{
    'Assistant Teacher'  = 'ROLE_ASSISTANT_TEACHER'
    'Personal Assistant' = 'ROLE_PERSONAL_ASSISTANT'
  }

  # Teams Chat Group Mapping (keyed by campus from CSV, NOT Entra City field)
  # Each campus has up to 3 chats: KeyMessages, StudentSupport (all staff), SupportWorkerChat (Support Workers only)
  # Cross-campus chats are listed separately
  TeamsChatMap = @{
    beenleigh = @{
      KeyMessages        = '19:322e7c475eb541eaae21328de4fe474e@thread.v2'
      StudentSupport     = '19:dcb8b3ba4cf64688bbfca7036a7be9b4@thread.v2'
      SupportWorkerChat  = '19:cbc55fd2a693451aabd91032c900e8a4@thread.v2'
    }
    bundoora = @{
      KeyMessages        = '19:013ee319d4c144438d2aed527da5c1e7@thread.v2'
      StudentSupport     = '19:0decbc87714043eeaa1d852cb387d437@thread.v2'
      SupportWorkerChat  = '19:ed7bb3c6437545c5a1500a3e927accab@thread.v2'
    }
    cairns = @{
      KeyMessages        = '19:687e612cbe5e446b8d60c37bf0e795d8@thread.v2'
      StudentSupport     = '19:fdada149eea54196aea7f714171304f9@thread.v2'
      SupportWorkerChat  = '19:5223e1ded38548d28f164f2d4b09fb55@thread.v2'
    }
    coolangatta = @{
      KeyMessages        = '19:ee68afa24bc647e19d60bcdb61eeaf41@thread.v2'
      StudentSupport     = '19:5cfc5748aebb4ac7aab4c52759603cd9@thread.v2'
      SupportWorkerChat  = '19:f993f08ef3494c00b80d01b06980aba2@thread.v2'
    }
    launceston = @{
      KeyMessages        = '19:84b7e7d7105b4381ae4179eb3ec7aacd@thread.v2'
      StudentSupport     = '19:6d2ccc3982e049d8b9051ec2fb1b957c@thread.v2'
      SupportWorkerChat  = '19:2a03802a944948dc8e3a1b1b7af5f7ba@thread.v2'
    }
    mitchelton = @{
      KeyMessages        = '19:2446451eea024d66b68732169877322d@thread.v2'
      StudentSupport     = '19:256e46dde1114c929ca705027e100eeb@thread.v2'
      SupportWorkerChat  = '19:7608cee226104a2e88692f5facf694d7@thread.v2'
    }
    olympicpark = @{
      KeyMessages        = '19:a02a7e0a3f1644c3ad3a3a720f6735cc@thread.v2'
      StudentSupport     = '19:2f55d3a950ce4f3ebc0561076148ee0e@thread.v2'
      SupportWorkerChat  = '19:5025aeef392442fea9cd2da6d666933c@thread.v2'
    }
    southport = @{
      KeyMessages        = '19:6f3abb8c849e4561abbf5874c5c9cb1e@thread.v2'
      StudentSupport     = '19:5bbe7ef24d2d41fc9ec7a0e96816d7c4@thread.v2'
      SupportWorkerChat  = '19:dc452b5659a64440a17ebbfa97294b66@thread.v2'
    }
    springfield = @{
      KeyMessages        = '19:55b17e7c8a9e44728bb9e3d879319a38@thread.v2'
      StudentSupport     = '19:6daef91d38894daf84b2a1205d2e5d58@thread.v2'
      SupportWorkerChat  = '19:6cf4d4910f97404594e0fd817d38debc@thread.v2'
    }
    varsity = @{
      KeyMessages        = '19:c69262d84a534cc3b72ea1bc678d9795@thread.v2'
      StudentSupport     = '19:4dcb5a2564c344e086725c693db9ef27@thread.v2'
      SupportWorkerChat  = '19:b18bf8a872d74b4aba96e0d2c587e4d7@thread.v2'
    }
    # Test campus - uses a single chat for all rules (personal tenant testing)
    test = @{
      KeyMessages        = '19:0b4e46a8890e43ea869573cc72fe50a0@thread.v2'
      StudentSupport     = '19:0b4e46a8890e43ea869573cc72fe50a0@thread.v2'
      SupportWorkerChat  = '19:0b4e46a8890e43ea869573cc72fe50a0@thread.v2'
    }
  }

  # Cross-campus Teams chat groups
  TeamsChatCrossCampus = @{
    SupportWorkers = '19:cross-campus-support-workers-thread-id@thread.v2'  # TODO: get actual thread ID from MSA
  }

  # Job titles that qualify for Support Worker chat groups
  SupportWorkerTitles = @('Support Worker')

  # Campus defaults (replaces portal templates)
  CampusDefaults = @{
    beenleigh = @{
      Department    = 'Beenleigh'
      Office        = 'Beenleigh'
      OfficePhone   = '(07) 3386 3308'
      StreetAddress = '24 Tansey St'
      City          = 'Beenleigh'
      State         = 'QLD'
      PostalCode    = '4207'
      Country       = 'Australia'
    }

    bundoora = @{
      Department    = 'Bundoora'
      Office        = 'Bundoora'
      OfficePhone   = '(03) 9109 7811'
      StreetAddress = 'Terrace 14, Ernest Jones Drive, La Trobe University Bundoora Campus'
      City          = 'Macleod'
      State         = 'VIC'
      PostalCode    = '3085'
      Country       = 'Australia'
    }

    cairns = @{
      Department    = 'Cairns'
      Office        = 'Cairns'
      OfficePhone   = '(07) 4243 3399'
      StreetAddress = '23 Aplin Street'
      City          = 'Cairns City'
      State         = 'QLD'
      PostalCode    = '4870'
      Country       = 'Australia'
    }

    coolangatta = @{
      Department    = 'Coolangatta'
      Office        = 'Coolangatta'
      OfficePhone   = '(07) 5551 4080'
      StreetAddress = 'Level 1 / 72-80 Marine Parade'
      City          = 'Coolangatta'
      State         = 'QLD'
      PostalCode    = '4225'
      Country       = 'Australia'
    }

    launceston = @{
      Department    = 'Launceston'
      Office        = 'Launceston'
      OfficePhone   = '(03) 6351 6730'
      StreetAddress = 'University of Tasmania, Newnham Campus, Sir Raymond Ferral Centre, Building X, Newnham Drive'
      City          = 'Newnham'
      State         = 'TAS'
      PostalCode    = '7248'
      Country       = 'Australia'
    }

    mitchelton = @{
      Department    = 'Mitchelton'
      Office        = 'Mitchelton'
      OfficePhone   = '(07) 2115 7009'
      StreetAddress = 'Building 3, Level 2, 53 Prospect Road'
      City          = 'Gaythorne'
      State         = 'QLD'
      PostalCode    = '4051'
      Country       = 'Australia'
    }

    # arapaki = @{   # NZ campus intentionally commented out (treated separately operationally)
    #   Department    = 'Arapaki'
    #   Office        = 'Arapaki'
    #   OfficePhone   = '03 365 5022'
    #   StreetAddress = '8A Kennedy Place'
    #   City          = 'Hillsborough, Christchurch'
    #   State         = 'NZ'
    #   PostalCode    = '8022'
    #   Country       = 'New Zealand'
    # }

    olympicpark = @{
      Department    = 'Olympic Park'
      Office        = 'Olympic Park'
      OfficePhone   = '(02) 7238 0988'
      StreetAddress = 'Level 3, 10 Parkview Drive, Quad 4'
      City          = 'Sydney Olympic Park'
      State         = 'NSW'
      PostalCode    = '2127'
      Country       = 'Australia'
    }

    southport = @{
      Department    = 'Southport'
      Office        = 'Southport'
      OfficePhone   = '(07) 5689 3553'
      StreetAddress = '105 Scarborough Street'
      City          = 'Southport'
      State         = 'QLD'
      PostalCode    = '4215'
      Country       = 'Australia'
    }

    springfield = @{
      Department    = 'Springfield'
      Office        = 'Springfield'
      OfficePhone   = '(07) 3870 4690'
      StreetAddress = '37 Sinnathamby Blvd'
      City          = 'Springfield Central'
      State         = 'QLD'
      PostalCode    = '4300'
      Country       = 'Australia'
    }

    varsity = @{
      Department    = 'Varsity'
      Office        = 'Varsity'
      OfficePhone   = '(07) 5513 1434'
      StreetAddress = '15 Lake Street'
      City          = 'Varsity Lakes'
      State         = 'QLD'
      PostalCode    = '4227'
      Country       = 'Australia'
    }

    corporate = @{
      Department    = 'Corporate'
      Office        = 'Corporate'
      OfficePhone   = '(07) 5513 1434'
      StreetAddress = '15 Lake Street'
      City          = 'Varsity Lakes'
      State         = 'QLD'
      PostalCode    = '4227'
      Country       = 'Australia'
    }

    test = @{  # Lab / personal tenant safe defaults
      Department    = 'TEST'
      Office        = 'TEST'
      OfficePhone   = '0000 000 000'
      StreetAddress = '1 Test Street'
      City          = 'Testtown'
      State         = 'TEST'
      PostalCode    = '0000'
      Country       = 'Australia'
    }
  }
}

# Cached verified domains (populated by Connect-MsaGraph)
$Script:VerifiedDomains = @()

# =========================
# GRAPH CONNECT
# =========================

function Connect-MsaGraph {
  [CmdletBinding()]
  param()

  $scopes = @(
    'User.ReadWrite.All',
    'Group.ReadWrite.All',
    'Directory.ReadWrite.All',
    'Chat.ReadWrite.All'
  )

  Connect-MgGraph -Scopes $scopes | Out-Null

  # Cache verified domains once per session to avoid repeated Graph calls
  $Script:VerifiedDomains = @(Get-MgDomain | Where-Object { $_.IsVerified -eq $true } | Select-Object -ExpandProperty Id)

  if ($Script:VerifiedDomains.Count -eq 0) {
    throw 'No verified domains found in the connected tenant. Check your permissions.'
  }

  Write-Host "Connected. Verified domains: $($Script:VerifiedDomains -join ', ')" -ForegroundColor Green

  # Domain guard: helps prevent accidentally running in the wrong tenant.
  if ($Script:Config.UpnDomainMode -eq 'Fixed') {
    if ($Script:Config.FixedTenantDomain -notin $Script:VerifiedDomains) {
      throw "Configured FixedTenantDomain '$($Script:Config.FixedTenantDomain)' is not a verified domain in the currently connected tenant. Verified domains: $($Script:VerifiedDomains -join ', ')"
    }
  }

  if ($Script:Config.UpnDomainMode -eq 'AutoByCampusState') {
    foreach ($kv in $Script:Config.TenantDomainsByState.GetEnumerator()) {
      if ($kv.Value -notin $Script:VerifiedDomains) {
        Write-Warning "Domain '$($kv.Value)' (state=$($kv.Key)) is not verified in the connected tenant. If you onboard a user for that state, the script will stop."
      }
    }
  }
}

function Resolve-UpnDomain {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$CampusDefaults
  )

  if ($Script:Config.UpnDomainMode -eq 'Fixed') {
    return $Script:Config.FixedTenantDomain
  }

  $state = if ($CampusDefaults.State) { $CampusDefaults.State.ToString().Trim().ToUpper() } else { '' }
  if ([string]::IsNullOrWhiteSpace($state)) {
    throw 'Campus defaults are missing a State value; cannot determine UPN domain.'
  }

  if (-not $Script:Config.TenantDomainsByState.Contains($state)) {
    throw "No tenant domain mapping found for state '$state'. Add it to TenantDomainsByState."
  }

  $domain = $Script:Config.TenantDomainsByState[$state]

  # Guard: ensure selected domain is verified (using cached domains from Connect-MsaGraph)
  if ($domain -notin $Script:VerifiedDomains) {
    throw "Selected UPN domain '$domain' (state=$state) is not verified in the currently connected tenant. Verified domains: $($Script:VerifiedDomains -join ', ')"
  }

  return $domain
}

# =========================
# HELPERS
# =========================

function New-SecurePassword {
  [CmdletBinding()]
  param(
    [int]$Length = 16
  )

  # Cryptographically secure password generation using RNGCryptoServiceProvider.
  # Character set excludes ambiguous chars (0/O, 1/l/I) for readability.
  $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%&*?'
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  $bytes = New-Object byte[] $Length
  $rng.GetBytes($bytes)
  $password = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
  $rng.Dispose()
  return $password
}

function Normalise-NamePart {
  [CmdletBinding()]
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  ($Value.Trim() -replace "[^a-zA-Z0-9\-']", '')
}

function Normalise-MobileNumber {
  [CmdletBinding()]
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }

  $digitsOnly = ($Value.Trim() -replace '[^\d]', '')

  if ([string]::IsNullOrWhiteSpace($digitsOnly)) { return '' }

  # Normalise to 10-digit local format starting with 04
  if ($digitsOnly.Length -eq 11 -and $digitsOnly.StartsWith('614')) {
    $digitsOnly = '0' + $digitsOnly.Substring(2)   # +61412... -> 0412...
  } elseif ($digitsOnly.Length -eq 9 -and $digitsOnly.StartsWith('4')) {
    $digitsOnly = '0' + $digitsOnly                 # 412...   -> 0412...
  }

  # Format as 0XXX XXX XXX (4-3-3 spacing)
  if ($digitsOnly.Length -eq 10 -and $digitsOnly.StartsWith('04')) {
    return $digitsOnly.Substring(0,4) + ' ' + $digitsOnly.Substring(4,3) + ' ' + $digitsOnly.Substring(7,3)
  }

  Write-Warning "Mobile number '$Value' could not be normalised to 0XXX XXX XXX format. Storing as-is."
  return $digitsOnly
}

function Get-UniqueUpn {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$Surname,
    [Parameter(Mandatory)][string]$TenantDomain
  )

  $fn = (Normalise-NamePart $FirstName).ToLowerInvariant()

  # For UPN surname: use first part of hyphenated names, strip apostrophes/special chars
  $snRaw = $Surname.Trim()
  if ($snRaw -match '-') {
    $snRaw = ($snRaw -split '-')[0]
  }
  $sn = ($snRaw -replace "[^a-zA-Z0-9]", '').ToLowerInvariant()

  if ([string]::IsNullOrWhiteSpace($fn) -or [string]::IsNullOrWhiteSpace($sn)) {
    throw 'Cannot generate UPN: first name or surname missing.'
  }

  # MSA naming convention: firstname.{progressive surname letters}
  # e.g. steven.v -> steven.ve -> steven.vel -> steven.vell -> steven.vella
  for ($i = 1; $i -le $sn.Length; $i++) {
    $suffix = $sn.Substring(0, $i)
    $upn = "$fn.$suffix@$TenantDomain"
    $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if (-not $existing) {
      Write-Host "  UPN available: $upn" -ForegroundColor DarkGray
      return $upn
    }
    Write-Host "  UPN taken: $upn - trying next suffix" -ForegroundColor DarkGray
  }

  # Safety valve: full surname exhausted, flag for manual intervention
  throw "Could not generate unique UPN for $FirstName $Surname — all surname suffix combinations taken at domain $TenantDomain. Manual intervention required."
}

function Get-ExistingUserByUpnOrMail {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Upn,
    [string]$PersonalEmail
  )

  # Fast path: check UPN
  $u = Get-MgUser -Filter "userPrincipalName eq '$Upn'" -ErrorAction SilentlyContinue
  if ($u) { return $u }

  # Optional: if your org stores personal email in an attribute, we can query it.
  # NOTE: In your current screenshot, personal email is collected by the form but not necessarily stored in Entra.
  # If you decide to store it (e.g. in 'otherMails'), we can use it for matching.
  if (-not [string]::IsNullOrWhiteSpace($PersonalEmail)) {
    $mail = $PersonalEmail.Replace("'","''")
    $u2 = Get-MgUser -Filter "otherMails/any(x:x eq '$mail')" -ErrorAction SilentlyContinue
    if ($u2) { return $u2 }
  }

  return $null
}

function Add-UserToGroupIfConfigured {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$UserId,
    [Parameter(Mandatory)][string]$GroupId
  )

  if ([string]::IsNullOrWhiteSpace($GroupId) -or $GroupId -like '00000000-0000-0000-0000-000000000000') {
    return
  }

  try {
    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId | Out-Null
  } catch {
    Write-Warning "Group add warning: $($_.Exception.Message)"
  }
}

function Add-UserToChatIfMissing {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$ChatId,
    [Parameter(Mandatory)][string]$UserId,
    [Parameter(Mandatory)][string]$DisplayName,
    [string]$ChatLabel = ''
  )

  try {
    $members = Get-MgChatMember -ChatId $ChatId
    $memberIds = $members | ForEach-Object { $_.AdditionalProperties["userId"] }

    if ($memberIds -contains $UserId) {
      Write-Host "    $DisplayName already in chat: $ChatLabel" -ForegroundColor DarkGray
      return
    }

    $params = @{
      "@odata.type"     = "#microsoft.graph.aadUserConversationMember"
      roles             = @("owner")
      "user@odata.bind" = "https://graph.microsoft.com/v1.0/users/$UserId"
    }

    New-MgChatMember -ChatId $ChatId -BodyParameter $params | Out-Null
    Write-Host "    Added to chat: $ChatLabel" -ForegroundColor DarkGray
  } catch {
    Write-Warning "Teams chat add failed ($ChatLabel): $($_.Exception.Message)"
  }
}

function Add-UserToTeamsChats {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$UserId,
    [Parameter(Mandatory)][string]$DisplayName,
    [Parameter(Mandatory)][string]$CampusKey,
    [Parameter(Mandatory)][string]$JobTitle
  )

  $isSupportWorker = $JobTitle -in $Script:Config.SupportWorkerTitles

  # Campus chats (keyed by campus from CSV, not Entra City field)
  if ($Script:Config.TeamsChatMap.ContainsKey($CampusKey)) {
    $campusChats = $Script:Config.TeamsChatMap[$CampusKey]

    # Key Messages - all staff
    if ($campusChats.KeyMessages) {
      Add-UserToChatIfMissing -ChatId $campusChats.KeyMessages -UserId $UserId -DisplayName $DisplayName -ChatLabel "$CampusKey Key Messages"
    }

    # Student Support - all staff
    if ($campusChats.StudentSupport) {
      Add-UserToChatIfMissing -ChatId $campusChats.StudentSupport -UserId $UserId -DisplayName $DisplayName -ChatLabel "$CampusKey Student Support"
    }

    # Support Worker Chat - Support Workers only
    if ($isSupportWorker -and $campusChats.SupportWorkerChat) {
      Add-UserToChatIfMissing -ChatId $campusChats.SupportWorkerChat -UserId $UserId -DisplayName $DisplayName -ChatLabel "$CampusKey Support Worker Chat"
    }
  } else {
    Write-Warning "No Teams chat mapping found for campus '$CampusKey'. Skipping chat group additions."
  }

  # Cross-campus: Support Workers group
  if ($isSupportWorker) {
    $crossCampusId = $Script:Config.TeamsChatCrossCampus.SupportWorkers
    if ($crossCampusId -and $crossCampusId -notlike '*TODO*') {
      Add-UserToChatIfMissing -ChatId $crossCampusId -UserId $UserId -DisplayName $DisplayName -ChatLabel "Support Workers (cross-campus)"
    }
  }
}

function Get-ClosestCampusKey {
  param([string]$InputKey)

  $keys = $Script:Config.CampusDefaults.Keys

  # Simple Levenshtein implementation
  function Get-LevenshteinDistance($s, $t) {
    $n = $s.Length; $m = $t.Length
    $d = New-Object 'int[,]' ($n+1), ($m+1)
    for ($i=0; $i -le $n; $i++) { $d[$i,0] = $i }
    for ($j=0; $j -le $m; $j++) { $d[0,$j] = $j }
    for ($i=1; $i -le $n; $i++) {
      for ($j=1; $j -le $m; $j++) {
        $cost = if ($s[$i-1] -eq $t[$j-1]) { 0 } else { 1 }
        $d[$i,$j] = [Math]::Min(
          [Math]::Min($d[$i-1,$j] + 1, $d[$i,$j-1] + 1),
          $d[$i-1,$j-1] + $cost
        )
      }
    }
    return $d[$n,$m]
  }

  $scored = foreach ($k in $keys) {
    [pscustomobject]@{
      Key = $k
      Distance = Get-LevenshteinDistance $InputKey $k
    }
  }

  return ($scored | Sort-Object Distance | Select-Object -First 1).Key
}

function Resolve-CampusDefaults {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Campus
  )

  $campusKey = $Campus.Trim().ToLower()

  if (-not $Script:Config.CampusDefaults.ContainsKey($campusKey)) {
    $suggestion = Get-ClosestCampusKey -InputKey $campusKey
    throw "Campus '$Campus' (normalised='$campusKey') not found. Did you mean '$suggestion'?"
  }

  return $Script:Config.CampusDefaults[$campusKey]
}

# =========================
# CORE: ONBOARD FROM CSV
# =========================

function Invoke-MsaEntraOnboardingFromCsv {
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
    [string]$CsvPath = '.\onboarding.csv',
    [switch]$SkipExisting
  )

  if (-not (Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }

  $rows = Import-Csv -Path $CsvPath
  if (-not $rows -or $rows.Count -eq 0) { throw 'No rows found in CSV.' }

  $licenceFailures = New-Object System.Collections.Generic.List[object]

  # Collect users for Phase 2 (Teams chat additions after all creations)
  $chatQueue = New-Object System.Collections.Generic.List[object]
  $newUsersCreated = $false

  # ===== PHASE 1: User creation, licence, groups, email =====
  foreach ($r in $rows) {
    $campus  = $r.Campus
    $jobTitle = $r.'Job Title'
    $firstName = $r.'First Name'
    $surname   = $r.Surname
    $mobile    = Normalise-MobileNumber $r.Mobile
    $personalEmail = $r.'Personal Email Address'

    if ([string]::IsNullOrWhiteSpace($campus)) { throw 'Campus is required.' }

    $c = Resolve-CampusDefaults -Campus $campus

    $tenantDomain = Resolve-UpnDomain -CampusDefaults $c
    $upn = Get-UniqueUpn -FirstName $firstName -Surname $surname -TenantDomain $tenantDomain
    $displayName = "$firstName $surname".Trim()

    if ($SkipExisting) {
      $existing = Get-ExistingUserByUpnOrMail -Upn $upn -PersonalEmail $personalEmail
      if ($existing) {
        Write-Host "SkipExisting: user already exists: $displayName ($($existing.UserPrincipalName))" -ForegroundColor Yellow

        # Queue for Phase 2 chat check (no propagation delay needed)
        $chatQueue.Add([pscustomobject]@{
          UserId      = $existing.Id
          DisplayName = $displayName
          CampusKey   = $campus.Trim().ToLower()
          JobTitle    = $jobTitle
        })

        continue
      }
    }

    $password = New-SecurePassword

    $actionLabel = "Create user $displayName ($upn)"

    if ($PSCmdlet.ShouldProcess($upn, $actionLabel)) {

      # Create user
      $user = New-MgUser -AccountEnabled:$true `
        -DisplayName $displayName `
        -GivenName $firstName `
        -Surname $surname `
        -UserPrincipalName $upn `
        -MailNickname ($upn.Split('@')[0]) `
        -PasswordProfile @{
          Password = $password
          ForceChangePasswordNextSignIn = $true
        } `
        -UsageLocation $Script:Config.UsageLocation `
        -JobTitle $jobTitle `
        -Department $c.Department `
        -OfficeLocation $c.Office `
        -MobilePhone $mobile `
        -BusinessPhones @($c.OfficePhone) `
        -StreetAddress $c.StreetAddress `
        -City $c.City `
        -State $c.State `
        -PostalCode $c.PostalCode `
        -Country $c.Country

      # OPTIONAL: store personal email in otherMails to help matching later
      if (-not [string]::IsNullOrWhiteSpace($personalEmail)) {
        try {
          Update-MgUser -UserId $user.Id -OtherMails @($personalEmail) | Out-Null
        } catch {
          Write-Warning "Could not set otherMails: $($_.Exception.Message)"
        }
      }

      # Assign default licence (if configured)
      $skuKey = $Script:Config.DefaultLicenceSkuKey
      $skuId = $null
      if ($skuKey -and $Script:Config.Sku.Contains($skuKey)) {
        $skuId = $Script:Config.Sku[$skuKey]
      }

      if ($skuId -and $skuId -notlike '00000000-0000-0000-0000-000000000000') {
        try {
          $addLicences = @(@{ SkuId = $skuId })
          Set-MgUserLicense -UserId $user.Id -AddLicenses $addLicences -RemoveLicenses @() | Out-Null
        } catch {
          $licenceFailures.Add([pscustomobject]@{
            DisplayName = $displayName
            UPN         = $upn
            SkuKey      = $skuKey
            Error       = $_.Exception.Message
          })
          Write-Warning "Licence assignment failed for $displayName ($upn): $($_.Exception.Message)"
        }
      } else {
        Write-Warning "Licence SKU not set for '$skuKey'. Skipping licence assignment."
      }

      # Add campus group
      $campusKey = $campus.Trim().ToLower()
      if ($Script:Config.CampusToGroupKey.Contains($campusKey)) {
        $gKey = $Script:Config.CampusToGroupKey[$campusKey]
        if ($Script:Config.Groups.Contains($gKey)) {
          Add-UserToGroupIfConfigured -UserId $user.Id -GroupId $Script:Config.Groups[$gKey]
        }
      }

      # Add role group
      if ($Script:Config.JobTitleToRoleGroupKey.Contains($jobTitle)) {
        $roleKey = $Script:Config.JobTitleToRoleGroupKey[$jobTitle]
        if ($Script:Config.Groups.Contains($roleKey)) {
          Add-UserToGroupIfConfigured -UserId $user.Id -GroupId $Script:Config.Groups[$roleKey]
        }
      }

      # Queue for Phase 2 chat additions
      $chatQueue.Add([pscustomobject]@{
        UserId      = $user.Id
        DisplayName = $displayName
        CampusKey   = $campusKey
        JobTitle    = $jobTitle
      })
      $newUsersCreated = $true

      # Generate onboarding email HTML file for manual send
      $emailDir = $Script:Config.OnboardingEmailOutputDir
      if (-not (Test-Path $emailDir)) {
        New-Item -Path $emailDir -ItemType Directory -Force | Out-Null
      }
      $safeUpn = $upn -replace '[\\/:*?"<>|]', '_'
      $emailPath = Join-Path $emailDir "$safeUpn.html"
      $emailBody = New-MsaQldOnboardingEmailBody -FirstName $firstName -Upn $upn -TempPassword $password
      $emailBody | Out-File -FilePath $emailPath -Encoding UTF8
      Write-Host "  Email draft saved: $emailPath" -ForegroundColor DarkGray

      Write-Host "Created: $displayName ($upn)" -ForegroundColor Green

    } else {
      # WhatIf path
      Write-Host "[WhatIf] $actionLabel" -ForegroundColor Cyan
      Write-Host "         Campus=$campus JobTitle=$jobTitle Dept=$($c.Department) Office=$($c.Office)" -ForegroundColor Cyan
    }
  }

  # ===== PHASE 2: Teams chat group additions =====
  if ($chatQueue.Count -gt 0) {
    if ($newUsersCreated) {
      Write-Host ''
      Write-Host "Waiting 15 seconds for Entra propagation before Teams chat additions..." -ForegroundColor Cyan
      Start-Sleep -Seconds 15
    }

    Write-Host ''
    Write-Host "===== TEAMS CHAT GROUP ADDITIONS =====" -ForegroundColor Cyan
    foreach ($cu in $chatQueue) {
      Write-Host "  Processing: $($cu.DisplayName)" -ForegroundColor Cyan
      Add-UserToTeamsChats -UserId $cu.UserId -DisplayName $cu.DisplayName -CampusKey $cu.CampusKey -JobTitle $cu.JobTitle
    }
    Write-Host "=======================================" -ForegroundColor Cyan
  }

  Write-Host ''
  Write-Host "Email drafts saved to: $($Script:Config.OnboardingEmailOutputDir)" -ForegroundColor Green

  # Licence failure summary
  if ($licenceFailures.Count -gt 0) {
    Write-Host ''
    Write-Host '===== LICENCE ASSIGNMENT FAILURES =====' -ForegroundColor Red
    Write-Host "The following $($licenceFailures.Count) user(s) were created but could NOT be assigned a licence:" -ForegroundColor Red
    foreach ($lf in $licenceFailures) {
      Write-Host "  - $($lf.DisplayName) ($($lf.UPN))" -ForegroundColor Yellow
    }
    Write-Host 'These users will need licences assigned manually in the M365 admin centre.' -ForegroundColor Red
    Write-Host '========================================' -ForegroundColor Red
  }
}

# =========================
# EMAIL TEMPLATE (QLD MVP)
# =========================

function New-MsaQldOnboardingEmailBody {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$Upn,
    [Parameter(Mandatory)][string]$TempPassword
  )

@"
<html>
<body style="font-family: Calibri, Arial, sans-serif; font-size: 11pt;">

<p>Hi $FirstName,</p>

<p><strong>Welcome to the MSA Team!</strong> My name is Steve. I am an IT Technical Officer servicing all MSA schools. There are just a few more things needed to get you started with us.</p>

<p><strong>Please see below your MSA email account which is accessible via Microsoft:</strong></p>

<p>
<a href="https://office.com/">Microsoft Account Access (https://office.com/)</a><br/>
<br/>
<strong>Username:</strong> $Upn<br/>
<strong>Password:</strong> $TempPassword
</p>

<p>If you have any issues accessing your MSA email account, please let me know. Any future emails from IT or the school will come to your MSA email.</p>

<hr/>

<p><strong>Cyber Security Training</strong></p>

<p>On your first day, you will be issued Cyber Security training as part of your employment at MSA. This training is compulsory for all staff and must be completed within the allocated time frame of three weeks. New training programs are issued three times per term and this will be for the entirety of your employment. Ensuring staff are equipped with the skills necessary to identify criminal cyber activity is paramount to the protection of MSA.</p>

<hr/>

<p><strong>Connecting with MSA</strong></p>

<p>With this onboarding email comes access to our IT Help Platform, hosted by Freshworks, that will give you all the basics of connecting to our wireless network, printers and other services. Firstly, you'll need to follow the guide to sign into the Freshworks system utilising your Microsoft account details. Once logged in, you'll be able to see our primary portal offering you various services such as lodging help tickets for support, browsing our support articles or making requests for computers or tools.</p>

<p>Our recommended reading articles are:</p>

<ul>
<li>How to Connect to MSA WiFi Networks</li>
<li>Logging into MSA Computers</li>
<li>Logging IT Service Tickets</li>
<li>How to Login to Compass</li>
<li>How to Get Microsoft Office</li>
<li>MSA Email Groups</li>
<li>Phone Line Extensions</li>
</ul>

<p>If you have any questions, please do not hesitate to email <a href="mailto:ITService@msa.qld.edu.au">ITService@msa.qld.edu.au</a> to submit a ticket and receive support from our team.</p>

</body>
</html>
"@
}

# =========================
# USAGE
# =========================

<#
0) Prerequisites (once per machine):
   Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
   
1) Dot-source to load functions into session:
   . .\onboarding.ps1

2) Connect once per session:
   Connect-MsaGraph

3) Dry run:
   Invoke-MsaEntraOnboardingFromCsv -SkipExisting -WhatIf

4) Real run:
   Invoke-MsaEntraOnboardingFromCsv -SkipExisting
#>
