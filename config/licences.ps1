# config/licences.ps1
# Licence SKU configuration for MSA onboarding.
# SKU GUIDs populated from: Get-MgSubscribedSku | Select SkuPartNumber, SkuId

# Default licence to assign during onboarding.
# For MSA production: M365EDU_A3_FACULTY (standard for almost all staff).
# For personal tenant testing: switch to M365_BUSINESS_BASIC.
$Script:Config.DefaultLicenceSkuKey = 'M365EDU_A3_FACULTY'
# $Script:Config.DefaultLicenceSkuKey = 'M365_BUSINESS_BASIC'

$Script:Config.Sku = [ordered]@{

  # ── Primary onboarding SKU ──────────────────────────────────────────
  M365EDU_A3_FACULTY                    = '4b590615-0888-425a-a965-b3bf7789848d'

  # ── Other education SKUs ────────────────────────────────────────────
  M365EDU_A3_STUUSEBNFT                 = '18250162-5d87-4436-a834-d795c15c80f3'
  M365EDU_A5_FACULTY                    = 'e97c048c-37a4-45fb-ab50-922fbf07a370'
  M365EDU_A5_FACULTY_CALLINGMINUTES     = 'ea73fc9b-3f94-418d-b128-1181dc9fb125'
  STANDARDWOFFPACK_FACULTY              = '94763226-9b3c-4e75-a931-5c89701abe66'   # Office 365 A1 for Faculty
  STANDARDWOFFPACK_STUDENT              = '314c4481-f395-4525-be8b-2ec4bb1e9d91'   # Office 365 A1 for Students

  # ── Add-ons & standalone ────────────────────────────────────────────
  M365_DISC0VER_RESPOND_FACULTY         = '5edc39e9-59c5-4fd4-8bea-aca8cc66b5e6'
  MCOEV_FACULTY                         = 'd979703c-028d-4de5-acbf-7955566b69b9'   # Teams Phone System
  Microsoft_365_Copilot_EDU             = 'ad9c22b3-52d7-4e7e-973c-88121ea96436'
  Teams_Premium_for_Faculty             = '960a972f-d017-4a17-8f64-b42c8035bc7d'
  THREAT_INTELLIGENCE_FAC               = 'a1c4e22f-6305-4a9d-8832-49dc2670aff1'

  # ── Project & Visio ─────────────────────────────────────────────────
  PROJECTESSENTIALS_FACULTY             = 'e433b246-63e7-4d0b-9efa-7940fa3264d6'
  PROJECTPROFESSIONAL_FACULTY           = '46974aed-363e-423c-9e6a-951037cec495'
  VISIOCLIENT_FACULTY                   = 'bf95fd32-576a-4742-8d7a-6dc4940b9532'

  # ── Power Platform ──────────────────────────────────────────────────
  FLOW_FREE                             = 'f30db892-07e9-47e9-837c-80727f46fd3d'
  POWER_BI_PRO_FACULTY                  = 'de5f128b-46d7-4cfc-b915-a89ba060ea56'
  POWER_BI_STANDARD                     = 'a403ebcc-fae0-4ca2-8c8c-7a907fd6c235'
  Power_Pages_vTrial_for_Makers         = '3f9f06f5-3c31-472c-985f-62d9c10ec167'
  POWERAPPS_DEV                         = '5b631642-bd26-49fe-bd20-1daaa972ef80'
  POWERAUTOMATE_ATTENDED_RPA            = 'eda1941c-3c4f-4995-b5eb-e85a42175ab9'

  # ── Other ───────────────────────────────────────────────────────────
  SharePoint_advanced_management_plan_1 = '6ee9b90c-0a7a-46c4-bc96-6698aa3bf8d2'
  WINDOWS_STORE                         = '6470687e-a428-4b7a-bef2-8a291ad947c9'

  # ── Personal tenant testing (not in MSA prod) ───────────────────────
  # M365_BUSINESS_BASIC                 = '3b555118-da6a-4418-894f-7df1e2096870'
}
