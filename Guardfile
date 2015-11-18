guard :rspec, cmd: 'bundle exec rspec' do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  watch(dsl.ruby.lib_files) { dsl.rspec.spec_dir }
  watch(dsl.rspec.spec_files)
  watch(dsl.rspec.spec_helper) { dsl.rspec.spec_dir }
  watch(dsl.rspec.spec_support) { dsl.rspec.spec_dir }
end
