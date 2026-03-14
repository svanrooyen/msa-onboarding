# =========================
# SECURITY GROUPS CONFIG
# =========================
# Group IDs and campus/role key mappings.
# Groups are mail-enabled security groups.
# Future: migrate to SharePoint List.

# Group IDs
# Role groups are keyed as ROLE_CAMPUS (e.g. AT_BEENLEIGH = Assistant Teachers at Beenleigh)
$Script:Config.Groups = [ordered]@{
  # ── Assistant Teachers (per campus) ─────────────────────────────────
  AT_BEENLEIGH         = 'b49c1bf9-1b5b-4fd2-8096-61f2534618d8'  # Assistant Teachers (Beenleigh)
  AT_BUNDOORA          = 'c56e27bb-e1bd-479d-af7a-6d74dfc4bcc3'  # Assistant Teachers (Bundoora)
  AT_CAIRNS            = 'd8f18523-af9d-40b0-b033-f7a7249f1bb7'  # Assistant Teachers (Cairns)
  AT_COOLANGATTA       = 'f6e3b8a3-bb15-484a-bb10-e55a97d012c5'  # Assistant Teachers Coolangatta
  AT_LAUNCESTON        = '90cbe4bc-3f0f-48f3-becf-cf549d574ef3'  # Assistant Teachers (Launceston)
  AT_MITCHELTON        = 'f522aa15-a89e-4b91-aa57-1621c7730884'  # Assistant Teachers (Mitchelton)
  AT_OLYMPICPARK       = '6ec6f1cc-540e-45f4-88cb-97d18294803b'  # Assistant Teachers (Olympic Park)
  AT_SOUTHPORT         = '6cc16087-b27f-413c-95ff-f73d1248b7f5'  # Assistant Teachers Southport
  AT_SPRINGFIELD       = 'c9757a86-0aff-44e8-9db2-bfc137aba640'  # Assistant Teachers Springfield
  AT_VARSITY           = '9863fed1-6bc4-4a1a-bf3b-c5e411577604'  # Assistant Teachers (Varsity)

  # ── Support Workers (per campus) ────────────────────────────────────
  SW_BEENLEIGH         = 'df28a773-cbfc-458e-a84f-5cc95a657c4e'  # Support Workers (Beenleigh)
  SW_BUNDOORA          = 'daebdce7-af79-47c1-b2cb-b21ff2977e87'  # Support Workers (Bundoora)
  SW_CAIRNS            = '4c075682-b89a-418f-9dc7-5fdaaa7c1d21'  # Support Workers (Cairns)
  SW_COOLANGATTA       = '7b3fd237-a973-4fe8-b781-e9aa7118c494'  # Support Workers (Coolangatta)
  SW_LAUNCESTON        = '755fdd74-3503-440c-84e3-f2a9b322c561'  # Support Workers (Launceston)
  SW_MITCHELTON        = 'b5ce335f-0236-4f69-80fa-dd80e5549512'  # Support Workers (Mitchelton)
  SW_OLYMPICPARK       = '16f62cb1-7d4c-44ab-9abe-0c806adb0725'  # Support Workers (Olympic Park)
  SW_SOUTHPORT         = 'a244f693-8636-4210-bb49-63ca7cb48e25'  # Support Workers (Southport)
  SW_SPRINGFIELD       = 'a8b57a8e-830f-49b8-83ee-3a3cdac16e6e'  # Support Workers (Springfield)
  SW_VARSITY           = 'a7ec50a1-1126-4aa3-b287-f511354fbba9'  # Support Workers (Varsity)

  # ── Teachers (per campus) ──────────────────────────────────────────
  T_BEENLEIGH          = '597155a0-6dbb-4bff-947c-2bb1072d7107'  # Teachers (Beenleigh)
  T_BUNDOORA           = 'a9036e4c-eb59-469b-9fd1-901c961ea03f'  # Teachers (Bundoora)
  T_CAIRNS             = '2ad2ab80-e758-4bdc-b02c-5b5a8b51727a'  # Teachers (Cairns)
  T_COOLANGATTA        = '82b2eb0a-5342-4639-85aa-8075d10c6354'  # Teachers Coolangatta
  T_LAUNCESTON         = '5f3f228d-f7e3-4e31-8b84-2c4f7a2b4dd6'  # Teachers (Launceston)
  T_MITCHELTON         = '1cb51e81-61a4-4d55-b408-584bafc880bf'  # Teachers (Mitchelton)
  T_OLYMPICPARK        = '6eaede9b-4fb3-4740-93e4-2933b13365b7'  # Teachers (Olympic Park)
  T_SOUTHPORT          = 'e03e6653-6764-4568-89e4-492108d95ecc'  # Teachers Southport
  T_SPRINGFIELD        = 'd4992e49-512d-4731-a31d-4790e4914ea9'  # Teachers Springfield
  T_VARSITY            = 'cd2881c9-31df-4171-af07-59bb072ac09f'  # Teachers (Varsity)
}

# Job title + campus -> role group key mapping
# Keyed as "JobTitle|campus" (lowercase campus). Script builds the lookup key
# from the CSV row: "$($jobTitle)|$($campus.ToLower())"
$Script:Config.RoleCampusToGroupKey = [ordered]@{
  'Assistant Teacher|beenleigh'   = 'AT_BEENLEIGH'
  'Assistant Teacher|bundoora'    = 'AT_BUNDOORA'
  'Assistant Teacher|cairns'      = 'AT_CAIRNS'
  'Assistant Teacher|coolangatta' = 'AT_COOLANGATTA'
  'Assistant Teacher|launceston'  = 'AT_LAUNCESTON'
  'Assistant Teacher|mitchelton'  = 'AT_MITCHELTON'
  'Assistant Teacher|olympicpark' = 'AT_OLYMPICPARK'
  'Assistant Teacher|southport'   = 'AT_SOUTHPORT'
  'Assistant Teacher|springfield' = 'AT_SPRINGFIELD'
  'Assistant Teacher|varsity'     = 'AT_VARSITY'

  'Support Worker|beenleigh'     = 'SW_BEENLEIGH'
  'Support Worker|bundoora'      = 'SW_BUNDOORA'
  'Support Worker|cairns'        = 'SW_CAIRNS'
  'Support Worker|coolangatta'   = 'SW_COOLANGATTA'
  'Support Worker|launceston'    = 'SW_LAUNCESTON'
  'Support Worker|mitchelton'    = 'SW_MITCHELTON'
  'Support Worker|olympicpark'   = 'SW_OLYMPICPARK'
  'Support Worker|southport'     = 'SW_SOUTHPORT'
  'Support Worker|springfield'   = 'SW_SPRINGFIELD'
  'Support Worker|varsity'       = 'SW_VARSITY'

  'Teacher|beenleigh'            = 'T_BEENLEIGH'
  'Teacher|bundoora'             = 'T_BUNDOORA'
  'Teacher|cairns'               = 'T_CAIRNS'
  'Teacher|coolangatta'          = 'T_COOLANGATTA'
  'Teacher|launceston'           = 'T_LAUNCESTON'
  'Teacher|mitchelton'           = 'T_MITCHELTON'
  'Teacher|olympicpark'          = 'T_OLYMPICPARK'
  'Teacher|southport'            = 'T_SOUTHPORT'
  'Teacher|springfield'          = 'T_SPRINGFIELD'
  'Teacher|varsity'              = 'T_VARSITY'
}

# Legacy mapping retained for any roles that are campus-independent (none currently)
# $Script:Config.JobTitleToRoleGroupKey = [ordered]@{}
