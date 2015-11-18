require 'rspec/its'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pardner'
require 'support/active_record'

RSpec.configure do |config|
  config.filter_run :focus
  config.order = 'random'
  config.run_all_when_everything_filtered = true
end
