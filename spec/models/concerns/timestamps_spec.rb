require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Pupa::Concerns::Timestamps do
  let :klass do
    Class.new do
      include Pupa::Model
      include Pupa::Concerns::Timestamps

      def save
        run_callbacks(:save) do
          unless created_at
            run_callbacks(:create) do
            end
          end
        end
      end
    end
  end

  it 'should set created_at and updated_at on create' do
    object = klass.new
    object.save
    expect(object.created_at).to be_within(1).of(Time.now.utc)
    expect(object.updated_at).to be_within(1).of(Time.now.utc)
  end

  it 'should set updated_at on save' do
    object = klass.new(created_at: Time.new(2000))
    object.save
    expect(object.created_at).to eq(Time.new(2000))
    expect(object.updated_at).to be_within(1).of(Time.now.utc)
  end
end
