require 'spec_helper'
require 'tempfile'

include Rake::DSL

gem_root = Pathname.new(File.dirname(__FILE__) + "/../..").expand_path.to_path

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

    pending "handles a non-starting server"

    pending "times out when the server goes down"

    pending "interoperates with ruby 1.9 and rake 0.9"

    it "allows the subproject to depend on a separate gemset" do
      File.write("foo/Gemfile", "source 'https://rubygems.org'\ngem 'multi_json', '~> 1.10.1'\n")
      File.write("foo/Rakefile",<<-RAKE)
        require 'multi_json'
        task 'bar' do
        end
      RAKE
      Bundler.with_clean_env do
        sh "bundle install", {chdir: "foo"}, {}
      end
      subproject "foo"
    end

    describe "with two-levels of hierarchy" do
      before do
        File.write("foo/Gemfile", "source 'https://rubygems.org'\ngem 'rake-subproject', :path => \'#{gem_root}\'")
        Bundler.with_clean_env do
          sh "bundle install", {chdir: "foo"}, {}
        end
        File.write("foo/Rakefile",<<-RAKE)
          require 'rake/subproject'
          subproject "bar"
        RAKE
      end
    
      it "propagates exceptions" do
        foo_bar_baz_task(<<-RAKE)
          raise
        RAKE
        subproject "foo"
        begin
          Rake::Task['foo:bar:baz'].invoke
        rescue Rake::Subproject::Error => e
          expect(e.backtrace[0]).to match("foo/bar/Rakefile:2")
        end
      end
    end
  end
end
