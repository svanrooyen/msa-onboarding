# =========================
# TEAMS CHAT GROUP CONFIG
# =========================
# Chat thread IDs for campus and cross-campus groups.
# Keyed by campus name from CSV, NOT Entra City field.
# Future: migrate to SharePoint List.

$Script:Config.TeamsChatMap = @{
  beenleigh = @{
    KeyMessages        = '19:322e7c475eb541eaae21328de4fe474e@thread.v2'
    StudentSupport     = '19:dcb8b3ba4cf64688bbfca7036a7be9b4@thread.v2'
    SupportWorkerChat  = '19:cbc55fd2a693451aabd91032c900e8a4@thread.v2'
  }
  bundoora = @{
    KeyMessages        = '19:013ee319d4c144438d2aed527da5c1e7@thread.v2'
    StudentSupport     = '19:0decbc87714043eeaa1d852cb387d437@thread.v2'
    SupportWorkerChat  = '19:ed7bb3c6437545c5a1500a3e927accab@thread.v2'
  }
  cairns = @{
    KeyMessages        = '19:687e612cbe5e446b8d60c37bf0e795d8@thread.v2'
    StudentSupport     = '19:fdada149eea54196aea7f714171304f9@thread.v2'
    SupportWorkerChat  = '19:5223e1ded38548d28f164f2d4b09fb55@thread.v2'
  }
  coolangatta = @{
    KeyMessages        = '19:ee68afa24bc647e19d60bcdb61eeaf41@thread.v2'
    StudentSupport     = '19:5cfc5748aebb4ac7aab4c52759603cd9@thread.v2'
    SupportWorkerChat  = '19:f993f08ef3494c00b80d01b06980aba2@thread.v2'
  }
  launceston = @{
    KeyMessages        = '19:84b7e7d7105b4381ae4179eb3ec7aacd@thread.v2'
    StudentSupport     = '19:6d2ccc3982e049d8b9051ec2fb1b957c@thread.v2'
    SupportWorkerChat  = '19:2a03802a944948dc8e3a1b1b7af5f7ba@thread.v2'
  }
  mitchelton = @{
    KeyMessages        = '19:2446451eea024d66b68732169877322d@thread.v2'
    StudentSupport     = '19:256e46dde1114c929ca705027e100eeb@thread.v2'
    SupportWorkerChat  = '19:7608cee226104a2e88692f5facf694d7@thread.v2'
  }
  olympicpark = @{
    KeyMessages        = '19:a02a7e0a3f1644c3ad3a3a720f6735cc@thread.v2'
    StudentSupport     = '19:2f55d3a950ce4f3ebc0561076148ee0e@thread.v2'
    SupportWorkerChat  = '19:5025aeef392442fea9cd2da6d666933c@thread.v2'
  }
  southport = @{
    KeyMessages        = '19:6f3abb8c849e4561abbf5874c5c9cb1e@thread.v2'
    StudentSupport     = '19:5bbe7ef24d2d41fc9ec7a0e96816d7c4@thread.v2'
    SupportWorkerChat  = '19:dc452b5659a64440a17ebbfa97294b66@thread.v2'
  }
  springfield = @{
    KeyMessages        = '19:55b17e7c8a9e44728bb9e3d879319a38@thread.v2'
    StudentSupport     = '19:6daef91d38894daf84b2a1205d2e5d58@thread.v2'
    SupportWorkerChat  = '19:6cf4d4910f97404594e0fd817d38debc@thread.v2'
  }
  varsity = @{
    KeyMessages        = '19:c69262d84a534cc3b72ea1bc678d9795@thread.v2'
    StudentSupport     = '19:4dcb5a2564c344e086725c693db9ef27@thread.v2'
    SupportWorkerChat  = '19:b18bf8a872d74b4aba96e0d2c587e4d7@thread.v2'
  }
  # Test campus - uses a single chat for all rules (personal tenant testing)
  test = @{
    KeyMessages        = '19:0b4e46a8890e43ea869573cc72fe50a0@thread.v2'
    StudentSupport     = '19:0b4e46a8890e43ea869573cc72fe50a0@thread.v2'
    SupportWorkerChat  = '19:0b4e46a8890e43ea869573cc72fe50a0@thread.v2'
  }
}

# Cross-campus Teams chat groups
$Script:Config.TeamsChatCrossCampus = @{
  SupportWorkers = '19:d8d84084e7fc4eea9326d88a2cc8a831@thread.v2'
}

# Job titles that qualify for Support Worker chat groups
$Script:Config.SupportWorkerTitles = @('Support Worker')
