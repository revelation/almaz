require 'rubygems'
require 'rake'
require 'spec'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "almaz-revelation"
    gem.summary = "Almaz is watching!"
    gem.description = "Almaz is a ruby rack middleware redis logger"
    gem.email = "ops@revelationglobal.com"
    gem.homepage = "http://github.com/revelation/almaz"
    gem.authors = ['James Pozdena', 'Max Ogden', 'Andrew Kurtz', 'Dan Herrera']
    gem.add_dependency "redis"
    gem.add_dependency "json"
    gem.add_development_dependency 'timecop'
    gem.add_development_dependency 'sinatra'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec
