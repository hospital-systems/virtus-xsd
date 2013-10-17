require 'active_support/dependencies'
require 'nokogiri'
require 'virtus/xsd'

spec_path = File.expand_path('..', __FILE__)
ActiveSupport::Dependencies.autoload_paths += [File.join(spec_path, 'tmp')]