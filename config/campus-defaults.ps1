# config/campus-defaults.ps1
# Campus address blocks — populates Entra user profile fields on creation.
# Keys must be lowercase and match the normalised campus name from the CSV.
# "Office" is intentionally left blank per M365 admin template convention.

$Script:Config.CampusDefaults = @{

    beenleigh = @{
      Department    = 'Beenleigh'
      Office        = ''
      OfficePhone   = '(07) 3386 3308'
      StreetAddress = '24 Tansey St'
      City          = 'Beenleigh'
      State         = 'QLD'
      PostalCode    = '4207'
      Country       = 'Australia'
    }

    bundoora = @{
      Department    = 'Bundoora'
      Office        = ''
      OfficePhone   = '(03) 9109 7811'
      StreetAddress = 'Terrace 14, 53 Ernest Jones Drive'
      City          = 'Macleod'
      State         = 'VIC'
      PostalCode    = '3085'
      Country       = 'Australia'
    }

    cairns = @{
      Department    = 'Cairns'
      Office        = ''
      OfficePhone   = '(07) 4243 3399'
      StreetAddress = '23 Aplin St'
      City          = 'Cairns'
      State         = 'QLD'
      PostalCode    = '4870'
      Country       = 'Australia'
    }

    coolangatta = @{
      Department    = 'Coolangatta'
      Office        = ''
      OfficePhone   = '(07) 5551 4080'
      StreetAddress = '72-80 Marine Parade'
      City          = 'Coolangatta'
      State         = 'QLD'
      PostalCode    = '4225'
      Country       = 'Australia'
    }

    launceston = @{
      Department    = 'Launceston'
      Office        = ''
      OfficePhone   = '(03) 6351 6730'
      StreetAddress = 'University of Tasmania, Newnham Campus, Building X, Newnham Drive'
      City          = 'Newnham'
      State         = 'TAS'
      PostalCode    = '7248'
      Country       = 'Australia'
    }

    mitchelton = @{
      Department    = 'Mitchelton'
      Office        = ''
      OfficePhone   = '(07) 2115 7009'
      StreetAddress = '53 Prospect Rd'
      City          = 'Gaythorne'
      State         = 'QLD'
      PostalCode    = '4051'
      Country       = 'Australia'
    }

    olympicpark = @{
      Department    = 'Olympic Park'
      Office        = ''
      OfficePhone   = '(02) 7238 0988'
      StreetAddress = '10 Parkview Dr'
      City          = 'Sydney Olympic Park'
      State         = 'NSW'
      PostalCode    = '2127'
      Country       = 'Australia'
    }

    southport = @{
      Department    = 'Southport'
      Office        = ''
      OfficePhone   = '(07) 5689 3553'
      StreetAddress = '105 Scarborough St'
      City          = 'Southport'
      State         = 'QLD'
      PostalCode    = '4215'
      Country       = 'Australia'
    }

    springfield = @{
      Department    = 'Springfield'
      Office        = ''
      OfficePhone   = '(07) 3870 4690'
      StreetAddress = '37 Sinnathamby Blvd'
      City          = 'Springfield'
      State         = 'QLD'
      PostalCode    = '4300'
      Country       = 'Australia'
    }

    varsity = @{
      Department    = 'Varsity'
      Office        = ''
      OfficePhone   = '(07) 5513 1434'
      StreetAddress = '15 Lake Street'
      City          = 'Varsity Lakes'
      State         = 'QLD'
      PostalCode    = '4227'
      Country       = 'Australia'
    }

    corporate = @{
      Department    = 'Corporate'
      Office        = ''
      OfficePhone   = '(07) 5513 1434'
      StreetAddress = '15 Lake Street'
      City          = 'Varsity Lakes'
      State         = 'QLD'
      PostalCode    = '4227'
      Country       = 'Australia'
    }

    # arapaki = @{   # NZ campus — not managed by MSA IT
    #   Department    = 'Arapaki'
    #   Office        = ''
    #   OfficePhone   = '03 365 5022'
    #   StreetAddress = '8A Kennedy Place'
    #   City          = 'Hillsborough, Christchurch'
    #   State         = 'NZ'
    #   PostalCode    = '8022'
    #   Country       = 'New Zealand'
    # }

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
