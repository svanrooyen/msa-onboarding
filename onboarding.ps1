<#
MSA Entra Onboarding - Chunked PowerShell
Version: 0.15.0

GOAL
- Manual-run onboarding from CSV export of MS Form spreadsheet.
- Safe by default: supports -WhatIf and -SkipExisting.
- Decouples campus defaults from M365 templates by storing them in config (later can be moved to SharePoint Lists).

NOTES
- Uses Microsoft Graph PowerShell SDK.
- Designed to be run manually in controlled stages before any scheduling.
- Config is split into separate files in the .\config\ subfolder for maintainability.

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

9) Cross-Domain UPN Uniqueness (PRE-GO-LIVE CHECK)
   - Confirm with Damon whether duplicate UPN prefixes across domains are acceptable
     e.g. steven.v@msa.qld.edu.au AND steven.v@msa.nsw.edu.au.
   - Entra allows this (full UPN is the unique key), but MailNickname must also be
     unique — current script sets it from the UPN prefix, so cross-domain duplicates
     would collide on MailNickname.
   - Practical concerns: GAL/People Picker confusion, future domain consolidation risk.
   - If cross-domain duplicates are allowed: update Get-UniqueUpn to check all MSA
     domains (not just the target campus domain) and warn when a cross-domain match
     exists. Also handle MailNickname uniqueness separately.
   - If not allowed: update Get-UniqueUpn to check all domains and treat a match on
     any domain as a collision requiring suffix expansion.

Design Principle:
Keep core onboarding deterministic and minimal.
Push variation to structured input (CSV flags, mapping tables), not inline conditional logic.

CHANGELOG
- 0.15.0: Split config into separate files in .\config\ subfolder (tenant, licences, groups,
           teams-chat-map, campus-defaults, email-templates). Main script now loads config via
           dot-sourcing. No functional changes.
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
Import-Module Microsoft.Graph.Mail

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================
# CONFIG (loaded from .\config\ subfolder)
# =========================

$Script:Config = [ordered]@{}

$configPath = Join-Path $PSScriptRoot 'config'
if (-not (Test-Path $configPath)) {
  throw "Config folder not found at '$configPath'. Ensure the .\config\ subfolder exists alongside this script."
}
Get-ChildItem -Path $configPath -Filter '*.ps1' | ForEach-Object { . $_.FullName }

# Cached verified domains (populated by Connect-MsaGraph)
$Script:VerifiedDomains = @()

# Cached current user UPN for Graph calls that need it (e.g. Mail.ReadWrite)
$Script:CurrentUserUpn = $null

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
    'Chat.ReadWrite.All',
    'Mail.ReadWrite'
  )

  Connect-MgGraph -Scopes $scopes | Out-Null

  # Cache current user UPN for Graph calls (e.g. creating Outlook drafts)
  $Script:CurrentUserUpn = (Get-MgContext).Account
  if ([string]::IsNullOrWhiteSpace($Script:CurrentUserUpn)) {
    Write-Warning "Could not determine current user UPN from Graph context. -AddToDrafts may not work."
  }

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
    [switch]$SkipExisting,
    [switch]$AddToDrafts
  )

  if (-not (Test-Path $CsvPath)) { throw "CSV not found: $CsvPath" }

  $rows = Import-Csv -Path $CsvPath
  if (-not $rows -or $rows.Count -eq 0) { throw 'No rows found in CSV.' }

  $licenceFailures = New-Object System.Collections.Generic.List[object]

  # Collect users for Phase 2 (Teams chat additions after all creations)
  $chatQueue = New-Object System.Collections.Generic.List[object]
  $newUsersCreated = $false

  # Collect Compass import data per campus (written as CSV at end of run)
  $compassData = @{}

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

      # Generate onboarding email HTML file(s) for manual send
      $emailDir = $Script:Config.OnboardingEmailOutputDir
      if (-not (Test-Path $emailDir)) {
        New-Item -Path $emailDir -ItemType Directory -Force | Out-Null
      }
      $safeUpn = $upn -replace '[\\/:*?"<>|]', '_'
      $senderName  = $Script:Config.SenderName
      $senderTitle = $Script:Config.SenderTitle
      $campusState = $c.State.ToString().Trim().ToUpper()

      # Primary onboarding email (MSA or MSV based on state)
      if ($campusState -eq 'VIC') {
        $emailSubject = 'MSV IT Onboarding'
        $emailBody = New-MsvOnboardingEmailBody -FirstName $firstName -Upn $upn -TempPassword $password -SenderName $senderName -SenderTitle $senderTitle
      } else {
        $emailSubject = 'MSA IT Onboarding'
        $emailBody = New-MsaOnboardingEmailBody -FirstName $firstName -Upn $upn -TempPassword $password -SenderName $senderName -SenderTitle $senderTitle
      }
      $emailPath = Join-Path $emailDir "$safeUpn.html"
      $emailBody | Out-File -FilePath $emailPath -Encoding UTF8
      Write-Host "  Email draft saved: $emailPath" -ForegroundColor DarkGray

      # Build CC list: work email + state recruitment mailbox
      $ccList = @(@{ EmailAddress = @{ Address = $upn } })
      if ($Script:Config.RecruitmentMailboxByState.ContainsKey($campusState)) {
        $ccList += @{ EmailAddress = @{ Address = $Script:Config.RecruitmentMailboxByState[$campusState] } }
      }

      # Add primary onboarding email to Outlook Drafts via Graph
      if ($AddToDrafts -and -not [string]::IsNullOrWhiteSpace($personalEmail)) {
        try {
          $toRecipients = @(@{ EmailAddress = @{ Address = $personalEmail } })
          New-MgUserMessage -UserId $Script:CurrentUserUpn `
            -Subject $emailSubject `
            -Body @{ ContentType = 'HTML'; Content = $emailBody } `
            -ToRecipients $toRecipients `
            -CcRecipients $ccList | Out-Null
          Write-Host "  Outlook draft created: $emailSubject -> $personalEmail (CC: $upn, recruitment)" -ForegroundColor DarkGray
        } catch {
          Write-Warning "Could not create Outlook draft for $displayName : $($_.Exception.Message)"
        }
      }

      # VIC mandatory training email (second email for MSV staff only)
      if ($campusState -eq 'VIC') {
        $trainingSubject = 'Mandatory Training - MSV Staff'
        $trainingBody = New-MsvMandatoryTrainingEmailBody -FirstName $firstName -SenderName $senderName -SenderTitle $senderTitle
        $trainingPath = Join-Path $emailDir "$safeUpn-mandatory-training.html"
        $trainingBody | Out-File -FilePath $trainingPath -Encoding UTF8
        Write-Host "  VIC training email draft saved: $trainingPath" -ForegroundColor DarkGray

        # Add VIC training email to Outlook Drafts via Graph
        if ($AddToDrafts -and -not [string]::IsNullOrWhiteSpace($personalEmail)) {
          try {
            $toRecipients = @(@{ EmailAddress = @{ Address = $personalEmail } })
            $trainingCc = @(@{ EmailAddress = @{ Address = $upn } })
            New-MgUserMessage -UserId $Script:CurrentUserUpn `
              -Subject $trainingSubject `
              -Body @{ ContentType = 'HTML'; Content = $trainingBody } `
              -ToRecipients $toRecipients `
              -CcRecipients $trainingCc | Out-Null
            Write-Host "  Outlook draft created: $trainingSubject -> $personalEmail (CC: $upn)" -ForegroundColor DarkGray
          } catch {
            Write-Warning "Could not create VIC training Outlook draft for $displayName : $($_.Exception.Message)"
          }
        }
      }

      # Collect Compass import data for this user
      $campusKey = $campus.Trim().ToLower()
      $compassRole = if ($Script:Config.CompassBaseRoleMap.ContainsKey($jobTitle)) {
        $Script:Config.CompassBaseRoleMap[$jobTitle]
      } else {
        $Script:Config.CompassDefaultBaseRole
      }
      $homeAddress = @($r.'Street Address', $r.Suburb, $r.State, $r.'Post Code') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
      $compassEntry = [pscustomobject]@{
        firstName   = $firstName
        lastName    = $surname
        dateOfBirth = $r.'Date of Birth'
        gender      = $r.Gender
        mobileNumber = $mobile
        email       = $personalEmail
        schoolEmail = $upn
        address     = ($homeAddress -join ', ')
        baseRole    = $compassRole
      }
      if (-not $compassData.ContainsKey($campusKey)) {
        $compassData[$campusKey] = New-Object System.Collections.Generic.List[object]
      }
      $compassData[$campusKey].Add($compassEntry)

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
      # Wait for all newly created users to propagate through Entra before adding to Teams chats
      Write-Host ''
      Write-Host '===== WAITING FOR ENTRA PROPAGATION =====' -ForegroundColor Cyan
      $maxAttempts = 5
      $delaySeconds = 30
      $allReady = $false

      for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        Write-Host "  Attempt $attempt/$maxAttempts - waiting $delaySeconds seconds..." -ForegroundColor Cyan
        Start-Sleep -Seconds $delaySeconds

        $notReady = @()
        foreach ($cu in $chatQueue) {
          $check = Get-MgUser -UserId $cu.UserId -ErrorAction SilentlyContinue
          if (-not $check) {
            $notReady += $cu.DisplayName
          }
        }

        if ($notReady.Count -eq 0) {
          Write-Host "  All $($chatQueue.Count) user(s) confirmed in Entra." -ForegroundColor Green
          $allReady = $true
          break
        } else {
          Write-Host "  Still waiting on $($notReady.Count) user(s): $($notReady -join ', ')" -ForegroundColor Yellow
        }
      }

      if (-not $allReady) {
        Write-Warning "Some users did not propagate after $maxAttempts attempts ($($maxAttempts * $delaySeconds) seconds). Proceeding anyway — some chat additions may fail. Re-run the script to retry."
      }
      Write-Host '=========================================' -ForegroundColor Cyan
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

  # ===== PHASE 3: Compass import CSV generation =====
  if ($compassData.Count -gt 0) {
    $emailDir = $Script:Config.OnboardingEmailOutputDir
    if (-not (Test-Path $emailDir)) {
      New-Item -Path $emailDir -ItemType Directory -Force | Out-Null
    }

    Write-Host ''
    Write-Host '===== COMPASS IMPORT FILES =====' -ForegroundColor Cyan
    foreach ($campus in $compassData.Keys) {
      $compassPath = Join-Path $emailDir "CompassImport-$campus.csv"
      $compassData[$campus] | Export-Csv -Path $compassPath -NoTypeInformation -Encoding UTF8
      Write-Host "  $($compassData[$campus].Count) user(s) -> $compassPath" -ForegroundColor DarkGray
    }
    Write-Host '=================================' -ForegroundColor Cyan
  }
}

# =========================
# USAGE
# =========================

<#
0) Prerequisites (once per machine):
   Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Teams, Microsoft.Graph.Mail -Scope CurrentUser

1) Folder structure (ensure config folder sits alongside onboarding.ps1):
   msa-onboarding\
   ├── onboarding.ps1
   ├── onboarding.csv
   └── config\
       ├── campus-defaults.ps1
       ├── compass.ps1
       ├── email-templates.ps1
       ├── groups.ps1
       ├── licences.ps1
       ├── teams-chat-map.ps1
       └── tenant.ps1

2) Dot-source to load functions and config into session:
   cd C:\path\to\msa-onboarding
   . .\onboarding.ps1

3) Connect once per session (yes, MsaGraph, not Connect-MgGraph - this sets up cached domains and current user context for the script's logic):
   Connect-MsaGraph

4) Dry run:
   Invoke-MsaEntraOnboardingFromCsv -SkipExisting -WhatIf

5) Real run (HTML files only):
   Invoke-MsaEntraOnboardingFromCsv -SkipExisting

6) Real run (HTML files + Outlook drafts via Graph):
   Invoke-MsaEntraOnboardingFromCsv -SkipExisting -AddToDrafts

7) Re-run to catch up Teams chat additions for existing users:
   Invoke-MsaEntraOnboardingFromCsv -SkipExisting
#>
