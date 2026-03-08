# =========================
# SECURITY GROUPS CONFIG
# =========================
# Group IDs and campus/role key mappings.
# Future: migrate to SharePoint List.

# Group IDs (fill in from your tenant)
$Script:Config.Groups = [ordered]@{
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
$Script:Config.CampusToGroupKey = [ordered]@{
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

# Job title -> role group mapping
$Script:Config.JobTitleToRoleGroupKey = [ordered]@{
  'Assistant Teacher'  = 'ROLE_ASSISTANT_TEACHER'
  'Personal Assistant' = 'ROLE_PERSONAL_ASSISTANT'
}
