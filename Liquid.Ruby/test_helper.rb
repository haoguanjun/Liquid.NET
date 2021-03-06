#!/usr/bin/env ruby

ENV["MT_NO_EXPECTATIONS"] = "1"
require 'minitest/autorun'
require 'spy/integration'
require 'json'

$:.unshift(File.join(File.expand_path(__dir__), '..', 'lib'))
require 'liquid.rb'
require 'liquid/profiler'
# see: https://github.com/Shopify/liquid/issues/589
#require 'active_support/core_ext/object/blank'
#require 'active_support/all'
#require 'active_support/core_ext/object/blank'

# MONKEY PATCH Liquid::Drop.to_json
module Liquid
  class Drop
    def to_json x
      self.instance_variables.to_json       
    end
  end
end
#  Liquid::Drop.to_json do
#    puts "MONKEYPATCH"
#    self.instance_variables.to_json       
#  end


mode = :strict
if env_mode = ENV['LIQUID_PARSER_MODE']
  puts "-- #{env_mode.upcase} ERROR MODE"
  mode = env_mode.to_sym
end
Liquid::Template.error_mode = mode

if Minitest.const_defined?('Test')
  # We're on Minitest 5+. Nothing to do here.
else
  # Minitest 4 doesn't have Minitest::Test yet.
  Minitest::Test = MiniTest::Unit::TestCase
end

module Minitest
  class Test
    def fixture(name)
      File.join(File.expand_path(__dir__), "fixtures", name)
    end
  end

  # MONKEY PATCH ALERT

  module Assertions
    include Liquid

    def assert_template_result(expected, template, assigns = {}, message = nil)
      puts "# TEMPLATE"
      puts template
      puts "# ASSIGNS"
      #if (assigns.is_a?(Liquid::Drop)) 
      #  puts "DROP!!#{x}"
      #  puts assigns.instance_variables.to_json       
      #else
        puts assigns.to_json
      #end
      puts "#EXPECTED"
      begin
        puts Template.parse(template).render!(assigns)
      rescue Error => err
        puts "EXCEPTION:#{err}"
      end
      puts "# END"
      assert_equal expected, Template.parse(template).render!(assigns), message
    end

    def assert_template_result_matches(expected, template, assigns = {}, message = nil)
      return assert_template_result(expected, template, assigns, message) unless expected.is_a? Regexp

      assert_match expected, Template.parse(template).render!(assigns), message
    end

    def assert_match_syntax_error(match, template, assigns = {})
      exception = assert_raises(Liquid::SyntaxError) {
        Template.parse(template).render(assigns)
      }
      assert_match match, exception.message
    end

    def with_global_filter(*globals)
      original_global_strainer = Liquid::Strainer.class_variable_get(:@@global_strainer)
      Liquid::Strainer.class_variable_set(:@@global_strainer, Class.new(Liquid::Strainer) do
        @filter_methods = Set.new
      end)
      Liquid::Strainer.class_variable_get(:@@strainer_class_cache).clear

      globals.each do |global|
        Liquid::Template.register_filter(global)
      end
      yield
    ensure
      Liquid::Strainer.class_variable_get(:@@strainer_class_cache).clear
      Liquid::Strainer.class_variable_set(:@@global_strainer, original_global_strainer)
    end

    def with_taint_mode(mode)
      old_mode = Liquid::Template.taint_mode
      Liquid::Template.taint_mode = mode
      yield
    ensure
      Liquid::Template.taint_mode = old_mode
    end

    def with_error_mode(mode)
      old_mode = Liquid::Template.error_mode
      Liquid::Template.error_mode = mode
      yield
    ensure
      Liquid::Template.error_mode = old_mode
    end
  end
end

class ThingWithToLiquid
  def to_liquid
    'foobar'
  end
end

class ErrorDrop < Liquid::Drop
  def standard_error
    raise Liquid::StandardError, 'standard error'
  end

  def argument_error
    raise Liquid::ArgumentError, 'argument error'
  end

  def syntax_error
    raise Liquid::SyntaxError, 'syntax error'
  end

  def runtime_error
    raise RuntimeError, 'runtime error'
  end

  def exception
    raise Exception, 'exception'
  end
end

