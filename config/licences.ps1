# =========================
# LICENCE CONFIG
# =========================
# SKU IDs and default licence assignment.
# Future: migrate to SharePoint List.

# Default licence to assign during onboarding.
# For MSA production: keep A3.
# For personal tenant testing: switch to M365_BUSINESS_BASIC.
# $Script:Config.DefaultLicenceSkuKey = 'M365_A3_FACULTY'
$Script:Config.DefaultLicenceSkuKey = 'M365_BUSINESS_BASIC'

# Licence SKU IDs (fill these from your tenant)
# Get-MgSubscribedSku | Select SkuPartNumber,SkuId
$Script:Config.Sku = [ordered]@{
  M365_A3_FACULTY        = '00000000-0000-0000-0000-000000000000'  # TODO
  M365_BUSINESS_BASIC    = '3b555118-da6a-4418-894f-7df1e2096870'  # Business Basic (O365_BUSINESS_ESSENTIALS)
}
