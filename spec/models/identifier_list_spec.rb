require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::IdentifierList do
  let :object do
    Pupa::IdentifierList.new([
      {
        identifier: '123456789',
        scheme: 'DUNS',
      },
      {
        identifier: 'US0123456789',
        scheme: 'ISIN',
      },
    ])
  end

  describe '#find_by_scheme' do
    it 'should return the first identifier matching the scheme' do
      object.find_by_scheme('ISIN').should == 'US0123456789'
    end

    it 'should return nil if no identifier matches the scheme' do
      Pupa::IdentifierList.new.find_by_scheme('ISIN').should == nil
    end
  end
end
