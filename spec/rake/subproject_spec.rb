require 'spec_helper'

include Rake::DSL

describe Rake::Subproject do
  it 'should have a version number' do
    Rake::Subproject::VERSION.should_not be_nil
  end

  it "accepts the #subproject call" do
    Dir.chdir("#{SUPPORT_DIR}/exceptions") do
      load "Rakefile"
      expect { Rake.application.lookup(:exception).invoke }.to raise_error(Rake::Subproject::Error)
    end
  end
end
