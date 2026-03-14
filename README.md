# MSA Entra Onboarding

PowerShell script for manually onboarding new staff into Microsoft Entra ID (Azure AD) from a CSV export of the MSA onboarding MS Form.

Designed to be run manually in controlled stages. Safe by default — supports `-WhatIf` for dry runs and `-SkipExisting` to safely re-run against a batch that was partially processed.

---

## How It Works

The script processes a CSV of new starters and, for each row:

1. **Resolves campus defaults** — looks up the campus key against `config/campus-defaults.ps1` to get address, phone, state, and department values
2. **Determines the UPN domain** — either fixed (for testing) or auto-selected by campus state (QLD/VIC/NSW/TAS)
3. **Generates a unique UPN** — uses the MSA naming convention (`firstname.{progressive surname letters}`) and checks Entra for collisions before settling on a UPN
4. **Creates the Entra user** — sets all profile fields from the CSV and campus defaults; stores personal email in `otherMails`
5. **Assigns a licence** — assigns the configured default SKU (M365 A3 for production, Business Basic for testing)
6. **Adds to security groups** — role+campus group (e.g. Assistant Teachers at Beenleigh) based on job title and campus, driven by a composite mapping table in config
7. **Generates onboarding email HTML** — state-aware template (MSA vs MSV); VIC staff also get a mandatory training email
8. **Optionally creates Outlook drafts** — via Graph API using `-AddToDrafts`; drafts are addressed to personal email, CC'd to new work email and state recruitment mailbox
9. **Generates Compass import CSV** — per-campus staff import file for the school management system
10. **Adds to Teams chats** — after all users are created, adds each to their campus group chats (Key Messages, Student Support, Support Worker Chat where applicable); waits for Entra propagation before attempting

Phases 1–9 run per-user in a loop. Teams chat additions (Phase 2 in the script) run as a separate pass after all users are created, with a propagation wait to avoid Graph timing issues.

---

## Folder Structure

```
msa-onboarding/
├── onboarding.ps1          # Main script — dot-source this to load everything
├── onboarding.csv          # Input CSV (gitignored — contains personal data)
├── config/
│   ├── campus-defaults.ps1 # Campus address blocks, phone numbers, state mapping
│   ├── compass.ps1         # Compass base role mappings
│   ├── email-templates.ps1 # MSA and MSV onboarding email template functions
│   ├── groups.ps1          # Security group IDs (role+campus), composite mapping table
│   ├── licences.ps1        # Licence SKU IDs and default SKU key
│   ├── teams-chat-map.ps1  # Teams chat thread IDs by campus; support worker titles
│   └── tenant.ps1          # Tenant domain, UPN mode, sender details, recruitment mailboxes
└── outputs/                # Generated email HTML files and Compass CSVs (gitignored)
```

Config is split by concern so each file can be maintained independently. The main script dot-sources all `config/*.ps1` files at startup — no imports needed beyond that.

---

## Prerequisites

Install the required Graph SDK modules once per machine:

```powershell
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Users, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement, Microsoft.Graph.Teams, Microsoft.Graph.Mail -Scope CurrentUser
```

---

## Running the Script

See the `# USAGE` block at the bottom of `onboarding.ps1` for the full step-by-step reference. Summary:

```powershell
# 1. Dot-source to load functions and config
cd C:\path\to\msa-onboarding
. .\onboarding.ps1

# 2. Connect (once per session)
Connect-MsaGraph

# 3. Dry run — shows what would happen, touches nothing
Invoke-MsaEntraOnboardingFromCsv -SkipExisting -WhatIf

# 4. Real run — creates users, generates HTML email files
Invoke-MsaEntraOnboardingFromCsv -SkipExisting

# 5. Real run + create Outlook drafts via Graph
Invoke-MsaEntraOnboardingFromCsv -SkipExisting -AddToDrafts
```

**Testing against a personal tenant:** Set `UpnDomainMode = 'Fixed'` and configure `FixedTenantDomain` in `config/tenant.ps1`. Uncomment `M365_BUSINESS_BASIC` in `config/licences.ps1` and set it as `DefaultLicenceSkuKey`. Use campus `test` in the CSV.

---

## Config Reference

### `tenant.ps1`
| Key | Purpose |
|-----|---------|
| `UpnDomainMode` | `AutoByCampusState` (production) or `Fixed` (testing) |
| `FixedTenantDomain` | Domain to use when mode is `Fixed` |
| `TenantDomainsByState` | State → domain mapping for `AutoByCampusState` mode |
| `SenderName` / `SenderTitle` | Appears in the onboarding email body — update before running |
| `RecruitmentMailboxByState` | CC recipients on onboarding emails by state |
| `OnboardingEmailOutputDir` | Where HTML files and Compass CSVs are written (default: `.\outputs`) |

### `licences.ps1`
| Key | Purpose |
|-----|---------|
| `DefaultLicenceSkuKey` | Key into `Sku` table — which licence to assign. Default: `M365EDU_A3_FACULTY` |
| `Sku` | All tenant SKU part names → GUID mappings. Refresh from: `Get-MgSubscribedSku \| Select SkuPartNumber,SkuId` |

### `groups.ps1`
Group GUIDs are in `Groups`, keyed as `AT_CAMPUS` / `SW_CAMPUS` (e.g. `AT_BEENLEIGH`, `SW_CAIRNS`). Groups are mail-enabled security groups. Get IDs from: `Get-MgGroup -Filter "displayName eq 'GroupName'" | Select Id`

Mapping:
- `RoleCampusToGroupKey` — composite `"JobTitle|campus"` key → group key (e.g. `"Assistant Teacher|beenleigh"` → `AT_BEENLEIGH`). The script builds the lookup key from the CSV row. Job title + campus combos not in the map are skipped gracefully.

### `campus-defaults.ps1`
Each campus key (lowercase) maps to a hashtable of address/contact/state fields. These populate the Entra user profile on creation and replace the need for M365 admin portal templates. `Office` is intentionally left blank per M365 admin template convention — only `Department` is populated with the campus name.

### `teams-chat-map.ps1`
Chat thread IDs keyed by campus. Keyed by campus name from the CSV, not the Entra `City` field. `SupportWorkerTitles` controls which job titles get added to support worker chats.

---

## CSV Format

The input CSV should match the MS Form field names. Required fields:

| Field | Notes |
|-------|-------|
| `First Name` | |
| `Surname` | |
| `Campus` | Must match a key in `CampusDefaults` (case-insensitive). Fuzzy suggestion on mismatch. |
| `Mobile` | Normalised to `0XXX XXX XXX` format automatically |
| `Personal Email Address` | Used for email drafts and `otherMails` in Entra |
| `Job Title` | Used for role group mapping and Teams chat routing |

Optional fields (warn if missing, don't fail): `Street Address`, `Suburb`, `State`, `Post Code`, `Date of Birth`, `Gender` — used for Compass import CSV only.

---

## Design Principles

- **Safe by default** — `-WhatIf` and `-SkipExisting` prevent accidents; licence failures are caught and summarised without stopping the batch
- **Config-driven, not logic-driven** — campus addresses, group mappings, exception flags, and role mappings all live in config files; the core script stays minimal and deterministic
- **95% coverage over edge-case perfection** — handle the common case cleanly; edge cases (multi-campus users, unusual names) are logged for manual follow-up rather than blocking the run
- **Maintainable by anyone with PowerShell knowledge** — no external dependencies beyond the Graph SDK; no databases, no Dataverse, no orchestration platforms

---

## Backlog

Intentionally not yet implemented. Items here should be built as separate PRs, not bolted into the core loop.

| # | Item | Notes |
|---|------|-------|
| 0 | Personal email in Entra (`otherMails`) — privacy review | Evaluate org stance; decide on convention for index position vs value search |
| 1 | Multi-campus parsing | Support semicolon/comma-separated campus values |
| 2 | Exception flags from CSV | `AllCampuses`, `NeedsMSVAccess` — CSV-driven, mapped to named groups |
| 3 | Automated email send | Send directly rather than generating HTML + drafts; shared mailbox governance decision needed |
| 4 | Manager field population | Accept manager UPN from CSV; set via Graph |
| 5 | Shared mailbox send model | Evaluate sender identity, audit trail, reply handling |
| 6 | Role-based licence mapping | Replace single default SKU with job-title-driven mapping table |
| 7 | Structured logging | File-based log with INFO/WARN/ERROR levels; `Start-Transcript` as quick win |
| 8 | **CSV input validation** ← **next priority** | Fail-fast validation before any Graph calls; per-row pass/fail summary |
| 9 | ~~Cross-domain UPN uniqueness~~ | ✅ Done — `Get-UniqueUpn` now checks `mailNickname` across all domains |
| 10 | Replace temp passwords with Temporary Access Pass (TAP) | Current flow embeds a plaintext temp password in the onboarding email HTML and Outlook draft. Works, but the password is visible to anyone with access to the `outputs/` folder or the sending mailbox drafts. HR also receives the password via the CC'd onboarding email — arguably unnecessary since HR is notified when the FreshWorks ticket is closed. TAP would be more secure and time-limited. |

---

## Changelog

See `onboarding.ps1` header for the full version history.
