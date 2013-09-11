require 'active_support/concern'

require 'pupa/processor'

require 'pupa/models/concerns/contactable'
require 'pupa/models/concerns/identifiable'
require 'pupa/models/concerns/linkable'
require 'pupa/models/concerns/metadata'
require 'pupa/models/concerns/nameable'

require 'pupa/models/base'
require 'pupa/models/contact_detail_list'
require 'pupa/models/membership'
require 'pupa/models/organization'
require 'pupa/models/person'
require 'pupa/models/post'

Pupa::Processor.add_extract_task(:memberships)
Pupa::Processor.add_extract_task(:organizations)
Pupa::Processor.add_extract_task(:people)
Pupa::Processor.add_extract_task(:posts)
