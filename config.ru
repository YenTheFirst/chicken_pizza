require 'bundler'
Bundler.require

#require File.expand_path("../pizza",__FILE__)

require './pizza.rb'
run Sinatra::Application

