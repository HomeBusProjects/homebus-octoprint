#!/usr/bin/env ruby

require './options'
require './app'

octo_app_options = OctoprintHomebusAppOptions.new

octo = OctoprintHomebusApp.new octo_app_options.options
octo.run!
