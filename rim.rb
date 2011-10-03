require "rubygems"
require "bundler/setup"

require "eventmachine"
require "logger"
require 'socket'
require 'rexml/document'
require "rexml/document"
require 'rexml/parsers/sax2parser'
require "state_machine"
require "colored"
require "uuidtools"

require "./lib/extend"
require "./lib/rim"
require "./lib/connection"
require "./lib/stream"
require "./lib/xmpp"
Rim.start
