# =========================
# TENANT & SENDER CONFIG
# =========================
# Domains, UPN mode, sender details, recruitment mailboxes.
# Future: migrate to SharePoint List or Azure App Configuration.

$Script:Config.TenantDomain   = 'msa.qld.edu.au'
$Script:Config.UsageLocation  = 'AU'

# Output directory for per-user onboarding email HTML files
$Script:Config.OnboardingEmailOutputDir = '.\outputs'

# Sender details for onboarding emails (change to your own name before running)
$Script:Config.SenderName  = 'Steve'
$Script:Config.SenderTitle = 'IT Technical Officer'

# State-based HR Recruitment shared mailboxes (CC'd on onboarding emails)
$Script:Config.RecruitmentMailboxByState = @{
  QLD  = 'recruitment@msa.qld.edu.au'
  NSW  = 'recruitment@msa.nsw.edu.au'
  TAS  = 'recruitment@msa.tas.edu.au'
  VIC  = 'recruitment@msv.vic.edu.au'
  TEST = 'recruitment@msa.qld.edu.au'  # Uses QLD recruitment for demo/testing
}

# TODO (Roadmap item 7): Structured log file path
# $Script:Config.LogPath = 'C:\Temp\MsaOnboarding.log'

# UPN Domain selection mode
# - AutoByCampusState: Choose domain based on the campus defaults 'State' field (QLD/VIC/NSW/TAS)
# - Fixed: Always use FixedTenantDomain (recommended for personal-tenant testing)
$Script:Config.UpnDomainMode = 'AutoByCampusState'
# $Script:Config.UpnDomainMode = 'Fixed'

# Fixed-domain override (personal tenant testing)
$Script:Config.FixedTenantDomain = 'sslvrnet.onmicrosoft.com'  # Personal tenant (Steve)

# MSA domains by state
$Script:Config.TenantDomainsByState = [ordered]@{
  QLD  = 'msa.qld.edu.au'
  VIC  = 'msv.vic.edu.au'
  NSW  = 'msa.nsw.edu.au'
  TAS  = 'msa.tas.edu.au'
  TEST = 'sslvrnet.onmicrosoft.com'  # Lab / personal tenant (Steve)
}
