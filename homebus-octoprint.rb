#!/usr/bin/env ruby

require './options'
require './app'

octo_app_options = OctoprintHomeBusAppOptions.new

octo = OctoprintHomeBusApp.new octo_app_options.options
octo.run!
