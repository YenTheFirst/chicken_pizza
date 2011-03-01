require 'bundler'
Bundler.require

#require File.expand_path("../pizza",__FILE__)

load 'pizza.rb'
run Sinatra::Application

