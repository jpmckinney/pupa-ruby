require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Pupa::Logger do
  Pupa::Logger.new('spec', level: 'DEBUG', logdev: io)
end
