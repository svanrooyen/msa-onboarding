# =========================
# COMPASS IMPORT CONFIG
# =========================
# Compass base role mapping and CSV generation settings.
# Future: migrate to SharePoint List. Expand role mappings as needed.

# Job title -> Compass base role mapping
$Script:Config.CompassBaseRoleMap = @{
  'Assistant Teacher' = 'CompassStaff'
  'Support Worker'    = 'CompassNurse'
  'Teacher'           = 'CompassTeachingStaff'
}

# Default base role if job title not found in mapping
$Script:Config.CompassDefaultBaseRole = 'CompassStaff'
