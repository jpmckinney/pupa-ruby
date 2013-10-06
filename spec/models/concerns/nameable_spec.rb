require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Nameable do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Nameable
    end
  end

  let :object do
    klass.new
  end

  describe '#add_name' do
    it 'should add a name' do
      object.add_name('Mr. Ziggy Q. Public, Esq.', start_date: '1920-01', end_date: '1949-12-31', note: 'Birth name')
      object.other_names.should == [{name: 'Mr. Ziggy Q. Public, Esq.', start_date: '1920-01', end_date: '1949-12-31', note: 'Birth name'}]
    end

    it 'should not add a name without a name' do
      object.add_name(nil)
      object.add_name('')
      object.other_names.blank?.should == true
    end
  end
end
