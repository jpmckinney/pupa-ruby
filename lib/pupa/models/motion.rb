module Pupa
  # A formal step to introduce a matter for consideration by an organization.
  class Motion
    include Model

    self.schema = File.expand_path(File.join('..', '..', '..', 'schemas', 'popolo', 'motion.json'), __dir__)

    include Concerns::Timestamps
    include Concerns::Sourceable

    attr_accessor :organization_id, :legislative_session_id, :creator_id, :text, :classification, :date, :requirement, :result
    dump          :organization_id, :legislative_session_id, :creator_id, :text, :classification, :date, :requirement, :result

    foreign_key :organization_id, :legislative_session_id, :creator_id

    # Returns the motion's text and organization ID.
    #
    # @return [String] the motion's text and organization ID
    def to_s
      "#{text} in #{organization_id}"
    end
  end
end
