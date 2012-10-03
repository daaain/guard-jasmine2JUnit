#!/usr/bin/env ruby
#
# guard-jasmine2junit.rb by Daniel Demmel <dain@danieldemmel.me>
# Version: 0.1 - 2012/10/03
#
# Usage: 
# bundle exec guard-jasmine -p 8888 -u http://localhost:8888/ --console=never 2>&1 | perl -pe 's/\e\[?.*?[\@-~]//g' | guard-jasmine2junit.rb
#
# All output is just passed through to stdout so you don't miss a thing!
# Console output colours are stripped to make parsing safer, but Jenkins doesn't display colour codes anyway.
# JUnit style XML-report are put in the folder specified below.
#
# Acknowledgement:
# Based on ocunit2junit.rb by Christian Hedin <christian.hedin@jayway.com>
################################################################
# 
#
# Edit these variables to match your system
#
#
# Where to put the XML-files from your unit tests
TEST_REPORTS_FOLDER = "test-reports"
#
#
# Don't edit below this line unless you know what you're doing! :)
################################################################

require 'time'
require 'fileutils'
require 'socket'

class ReportParser

  attr_reader :exit_code
  
  def initialize(piped_input)
    @piped_input = piped_input
    @exit_code = 0
    
    FileUtils.rm_rf(TEST_REPORTS_FOLDER)
    FileUtils.mkdir(TEST_REPORTS_FOLDER)
    parse_input
  end

  private
  
  def parse_input
    @piped_input.each do |piped_row|
      puts piped_row
      case piped_row
        
        when /Finished in (\d+\.\d*) seconds/
          handle_start_tests($1.to_s)

        when /(\d*) specs, (\d*) failures/
          handle_end_tests($1.to_i, $2.to_i)
      end
    end
  end

  def handle_start_tests(time)
    @elapsed_time = time
  end

  def handle_end_tests(specs, failures)
    @total_passed_test_cases = specs - failures
    @total_failed_test_cases = failures
    
    current_file = File.open("#{TEST_REPORTS_FOLDER}/TEST-jasmine.xml", 'w')
    
    test_duration = @elapsed_time
    total_tests = @total_failed_test_cases + @total_passed_test_cases
    suite_info = '<testsuite disabled="0" skipped="0" hostname="" id="" errors="0" failures="'+@total_failed_test_cases.to_s+'" tests="'+total_tests.to_s+'" time="'+test_duration.to_s+'" timestamp="'+Time.now.to_s+"\">\n"
    
    current_file << "<?xml version='1.0' encoding='UTF-8' ?>\n"
    current_file << suite_info

    (1..@total_failed_test_cases).each do
       current_file << "  <testcase classname=\"Jasmine\" name=\"Fail\" time=\"0\" assertions=\"0\" status=\"\">\n    <failure type=\"Failure\" message=\"\"> A test failed </failure>\n  </testcase>\n"
    end

    (1..@total_passed_test_cases).each do
       current_file << "  <testcase classname=\"Jasmine\" name=\"Success\" time=\"0\" assertions=\"0\" status=\"\"/>\n"
    end

    current_file << "</testsuite>\n"
    current_file.close
  end

  def string_to_xml(s)
    s.gsub(/&/, '&amp;').gsub(/'/, '&quot;').gsub(/</, '&lt;')
  end
 
end

#Main
# piped_input = File.open("tests_fail.txt") # for debugging this script
piped_input = ARGF.readlines

report = ReportParser.new(piped_input)

exit report.exit_code
