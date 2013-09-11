require 'active_support/concern'

require 'pupa/scraper'

require 'pupa/models/base'
require 'pupa/models/contact_detail_list'
require 'pupa/models/person'
require 'pupa/models/membership'
require 'pupa/models/organization'

Pupa::Scraper.register(:people)
Pupa::Scraper.register(:memberships)
Pupa::Scraper.register(:organizations)
