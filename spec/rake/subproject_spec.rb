require 'spec_helper'

include Rake::DSL

describe Rake::Subproject do
  it 'should have a version number' do
    Rake::Subproject::VERSION.should_not be_nil
  end

  it 'should do something useful' do
    false.should eq(true)
  end

  it "accepts the #subproject call" do
    subproject('test')
  end
end
