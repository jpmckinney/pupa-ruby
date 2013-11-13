require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require File.dirname(__FILE__) + '/../../lib/pupa/refinements/opencivicdata'

describe Pupa::Refinements do
  module Music
    class Band
      include Pupa::Model

      def save
        run_callbacks(:save) do
        end
      end
    end
  end

  module Pupa
    class Committee < Organization
      def save
        run_callbacks(:save) do
        end
      end
    end
  end

  it 'should demodulize the type of new models' do
    object = Music::Band.new
    object.save
    object._type.should == 'band'
  end

  it 'should demodulize the type of existing models' do
    object = Pupa::Committee.new
    object.save
    object._type.should == 'committee'
  end
end
