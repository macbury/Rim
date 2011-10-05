require "rubygems"
require "bundler/setup"

require "eventmachine"
require "logger"
require 'socket'
require 'rexml/document'
require 'rexml/parsers/sax2parser'
require "rexml/formatters/default"
require "base64"
require "state_machine"
require "colored"
require "rufus-mnemo"
require "base64"
require "openssl"
require "digest/md5"

require "./lib/extend"
require "./lib/state/idle"
require "./lib/rim"
require "./lib/connection"
require "./lib/stream"
require "./lib/auth"
require "./lib/response"

Rim.start
