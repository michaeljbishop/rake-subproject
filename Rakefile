require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/clean'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

['Client', 'Server'].each do |name|
  dir = "lib/rake/subproject/#{name.downcase}"
  directory dir
  CLEAN.include dir
  FileList["resources/network/*.rb"].each do |path|
    file "#{dir}/#{File.basename(path)}" => "lib/rake/subproject/#{name.downcase}" do |t|
      File.open(t.name, 'w') do |f|
        f.puts <<END
module Rake::Subproject
  module #{name} #:nodoc: all
#{File.read(path)}  end
end
END
      end
    end

    namespace :build do
      task :library => "#{dir}/#{File.basename(path)}"
    end
    CLEAN.include "#{dir}/#{File.basename(path)}"
  end
end

file "lib/rake/subproject/server/task.rb" => ["resources/server_task.rb", "lib/rake/subproject/server"] do |t|
  cp t.prerequisites.first, t.name
end

namespace :build do
  task :library => "lib/rake/subproject/server/task.rb"
end

task :build => 'build:library'

task :test => :'build:library' do
  sh 'rspec', verbose: false
end
