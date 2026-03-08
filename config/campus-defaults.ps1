# =========================
# CAMPUS DEFAULTS CONFIG
# =========================
# Campus address blocks, phone numbers, state mapping.
# Replaces M365 admin portal templates.
# Future: migrate to SharePoint List.

$Script:Config.CampusDefaults = @{
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
