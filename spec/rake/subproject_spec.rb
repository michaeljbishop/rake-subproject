require 'spec_helper'
require 'tempfile'

include Rake::DSL

gem_root = Pathname.new(File.dirname(__FILE__) + "/../..").expand_path.to_path
$stderr.puts "gem_root = #{gem_root}"
$stderr.puts `find #{gem_root}`

def foo_bar_task(str)
  File.write("foo/Rakefile",<<-RAKE)
    task 'bar' do |t|
      #{str}
    end
  RAKE
  subproject "foo"
end
    
def foo_bar_baz_task(str)
  File.write("foo/bar/Rakefile",<<-RAKE)
    task 'baz' do |t|
      #{str}
    end
  RAKE
end
    
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
      File.write("foo/Gemfile", "gem 'rake-subproject', :path => \'#{gem_root}\'")
      FileUtils.mkdir("foo/bar")
    end
    
    after do
      Dir.chdir(prev_dir)
      Rake.application.clear
      # remove the directory.
      FileUtils.remove_entry dir
    end
    
    it "executes the test task" do
      foo_bar_task(<<-RAKE)
        touch t.name, verbose:false
      RAKE
      Rake::Task['foo:bar'].invoke
      expect(File.exist?('foo/bar')).to be_truthy
    end
    
    it "waits for the test task" do
      task_time = 0.5
      subproject_delay = 0.4
      foo_bar_task(<<-RAKE)
        sleep #{task_time}
      RAKE
      end_time = Time.now.to_f + task_time
      Rake::Task['foo:bar'].invoke
      expect(Time.now.to_f).to be_between(end_time, end_time+subproject_delay)
    end
    
    it "propagates exceptions in one level" do
      foo_bar_task(<<-RAKE)
        raise
      RAKE
      expect { Rake::Task['foo:bar'].invoke }.to raise_error(Rake::Subproject::Error)
    end
 
    describe "with two-levels of hierarchy" do
      before do
        File.write("foo/Rakefile",<<-RAKE)
          require 'rake/subproject'
          subproject "bar"
        RAKE
        subproject "foo"
      end
    
      it "propagates exceptions" do
        foo_bar_baz_task(<<-RAKE)
          raise
        RAKE
        begin
          Rake::Task['foo:bar:baz'].invoke
        rescue Rake::Subproject::Error => e
          expect(e.backtrace[0]).to match("foo/bar/Rakefile:2")
        end
      end
    end
  end
end
