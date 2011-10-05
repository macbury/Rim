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
require "base64"
require "openssl"
require "digest/md5"
require "mongoid"
require 'ostruct'
require "yaml"

require "./lib/extend"
require "./lib/state/idle"
require "./lib/rim"
require "./lib/connection"
require "./lib/stream"
require "./lib/auth"
require "./lib/response"
require "./lib/user"

Rim.start
