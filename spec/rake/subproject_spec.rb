require 'spec_helper'
require 'tempfile'

include Rake::DSL

describe Rake::Subproject do
  it 'has a version number' do
    expect(Rake::Subproject::VERSION).to_not be_nil
  end
  
  describe "#subproject" do
  
    let(:prev_dir){Dir.pwd}
    let(:dir){Dir.mktmpdir}

    before do
      Dir.chdir(dir)
      FileUtils.mkdir("foo")
    end
    
    after do
      Dir.chdir(prev_dir)
      Rake.application.clear
      # remove the directory.
      FileUtils.remove_entry dir
    end
    
    it "executes the test task" do
      File.write("foo/Rakefile",<<-RAKE)
        task 'foo.txt' do |t|
          touch t.name, verbose:false
        end
      RAKE
      subproject "foo"
      Rake::Task['foo/foo.txt'].invoke
      expect(File.exist?('foo/foo.txt')).to be_truthy
    end
    
    it "waits for the test task" do
      File.write("foo/Rakefile",<<-RAKE)
        task 'foo.txt' do |t|
          touch t.name, verbose:false
        end
      RAKE
      subproject "foo"
      Rake::Task['foo/foo.txt'].invoke
      expect(File.exist?('foo/foo.txt')).to be_truthy
    end
    
    it "propagates exceptions" do
      File.write("foo/Rakefile",<<-RAKE)
        task 'exception' do |t|
          raise
        end
      RAKE
      subproject "foo"
      expect { Rake::Task['foo:exception'].invoke }.to raise_error(Rake::Subproject::Error)
    end

  end
  
end
