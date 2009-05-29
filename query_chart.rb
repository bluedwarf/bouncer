#!/usr/bin/ruby

# Query form of chart generator of bouncer statistics.
# Copyright (C) 2009 Takashi Nakamoto.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

db = nil
require './conf.rb'

begin
  require 'sqlite3'
  require 'cgi'

  ###################################################
  # Data section.
  ###################################################
  days = (1..31).to_a.map!{|a| a.to_s}
  months = ["January", "February", "March", "April", "May", "June", "July",
            "August", "September", "Octoboer", "November", "December"]
  years = (2008..2015).to_a.map!{|a| a.to_s}

  ###################################################
  # Initialization.
  ###################################################
  db = SQLite3::Database.new($dbfile)

  start_date = Date.today
  end_date = Date.new(2000,1,1)
  products = []
  oses = []
  languages = []

  ###################################################
  # Obtaining the valid values from database
  ###################################################
  db.execute("SELECT DISTINCT product FROM #{$tblname}"){ |r| products << r }
  products.sort!

  db.execute("SELECT DISTINCT os FROM #{$tblname}"){ |r| oses << r }
  oses.sort!

  db.execute("SELECT DISTINCT language FROM #{$tblname}"){ |r| languages << r }
  languages.sort!
rescue => exception
  ###################################################
  # Printing error message.
  ###################################################
  cgi = CGI.new("html4")
  cgi.out('charset'=>'utf-8') {
    html = cgi.html {
      cgi.head { cgi.title{'ERROR - OpenOffice.org Bouncer statistics'} } +
      cgi.body {
        cgi.h1 { "ERROR - OpenOffice.org Bouncer statistics: Query for chart" } +
        cgi.p {
          "This CGI crashed for some reason. Please send the following error message to #$contact:"
        } +
        cgi.h2 {
          "Error message:"
        } +
        cgi.p {
          exception.message
        } + 
        cgi.h2 {
          "Backtrace:"
        } +
        cgi.p {
          exception.backtrace
        }
      }
    }

    CGI.pretty(html)
  }
  
else
  ###################################################
  # Printing query form.
  ###################################################
  cgi = CGI.new("html4")
  cgi.out('charset'=>'utf-8') {
    html = cgi.html { 
      cgi.head { cgi.title{'OpenOffice.org Bouncer statistics'} } +
      cgi.body { 
        cgi.h1 { "OpenOffice.org Bouncer statistics: Query for chart" } +
        cgi.form('METHOD'=>'GET', 'ACTION'=>'chart.rb') {
          cgi.p {
            "From: " +
            cgi.scrolling_list({"NAME" => "start_day",
                                 "VALUES" => days}) +
            cgi.scrolling_list({"NAME" => "start_month",
                                 "VALUES" => months}) +
            cgi.scrolling_list({"NAME" => "start_year",
                                 "VALUES" => years})
          } +
          cgi.p {
            "To: " +
            cgi.scrolling_list({"NAME" => "end_day",
                                 "VALUES" => days}) +
            cgi.scrolling_list({"NAME" => "end_month",
                                 "VALUES" => months}) +
            cgi.scrolling_list({"NAME" => "end_year",
                                 "VALUES" => years})
          } +
          cgi.p {
          } +
          cgi.table {
            cgi.tr {
              cgi.th {"Product:"} + cgi.th {"Language:"} + cgi.th {"OS: "}
            } +
            cgi.tr {
              cgi.td {
                cgi.scrolling_list({"NAME" => "product",
                                     "VALUES" => products,
                                     "SIZE" => 10,
                                     "MULTIPLE" => true})
              } +
              cgi.td {
                cgi.scrolling_list({"NAME" => "language",
                                     "VALUES" => languages,
                                     "SIZE" => 10,
                                     "MULTIPLE" => true})
              } +
              cgi.td {
                cgi.scrolling_list({"NAME" => "os",
                                     "VALUES" => oses,
                                     "SIZE" => 10,
                                     "MULTIPLE" => true})
              }
            }
          } +
          cgi.p {
            "Chart type: " +
            cgi.scrolling_list({"NAME" => "type",
                                 "VALUES" => $valid_types})
          } +
          cgi.p { 
            cgi.submit("Show")
          }
        }       
      }
    }

    CGI.pretty(html)
  }
ensure
  db.close if db
end
