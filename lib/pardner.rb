require 'active_model'
require 'active_record'
require 'active_support/all'

require 'pardner/version'
require 'pardner/config'
require 'pardner/base'

module Pardner
  class InvalidModel < StandardError; end
end
