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
  months = 
    ["January", "February", "March", "April", "May", "June", "July",
     "August", "September", "Octoboer", "November", "December"]

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
  res = db.execute("SELECT MIN(datejd) FROM #{$tblname}")
  start_date = Date.jd(res[0][0].to_i)

  res = db.execute("SELECT MAX(datejd) FROM #{$tblname}")
  end_date = Date.jd(res[0][0].to_i)

  db.execute("SELECT DISTINCT product FROM #{$tblname}"){ |r| products << r }
  products.sort!

  db.execute("SELECT DISTINCT os FROM #{$tblname}"){ |r| oses << r }
  oses.sort!

  db.execute("SELECT DISTINCT language FROM #{$tblname}"){ |r| languages << r }
  languages.sort!

  ###################################################
  # Set default values for query form
  ###################################################
  start_days = (1..31).to_a.map{ |a|
    if a == start_date.day
      [a.to_s, true]
    else
      a.to_s
    end
  }

  start_months = months.clone
  start_months[start_date.month - 1] = [start_months[start_date.month - 1],
                                        true]

  start_years = ((start_date.year)..(end_date.year)).to_a.map{ |a|
    if a == start_date.year
      [a.to_s, true]
    else
      a.to_s
    end
  }

  end_days = (1..31).to_a.map{ |a|
    if a == end_date.day
      [a.to_s, true]
    else
      a.to_s
    end
  }

  end_months = months.clone
  end_months[end_date.month - 1] = [end_months[end_date.month - 1], true]

  end_years = ((start_date.year)..(end_date.year)).to_a.map{ |a|
    if a == end_date.year
      [a.to_s, true]
    else
      a.to_s
    end
  }
rescue => exception
  ###################################################
  # Printing error message.
  ###################################################
  cgi = CGI.new("html4")
  cgi.out('charset'=>$charset) {
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
          exception.message.gsub("\n"){"<BR>"}
        } + 
        cgi.h2 {
          "Backtrace:"
        } +
        cgi.p {
          exception.backtrace.join("<BR>")
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
  cgi.out('charset'=>$charset) {
    html = cgi.html { 
      cgi.head { cgi.title{'OpenOffice.org Bouncer statistics'} } +
      cgi.body { 
        cgi.h1 { "OpenOffice.org Bouncer statistics: Query for chart" } +
        cgi.form('METHOD'=>'GET', 'ACTION'=>'chart.rb') {
          cgi.p {
            "From: " +
            cgi.scrolling_list({"NAME" => "start_day",
                                 "VALUES" => start_days}) +
            cgi.scrolling_list({"NAME" => "start_month",
                                 "VALUES" => start_months}) +
            cgi.scrolling_list({"NAME" => "start_year",
                                 "VALUES" => start_years})
          } +
          cgi.p {
            "To: " +
            cgi.scrolling_list({"NAME" => "end_day",
                                 "VALUES" => end_days}) +
            cgi.scrolling_list({"NAME" => "end_month",
                                 "VALUES" => end_months}) +
            cgi.scrolling_list({"NAME" => "end_year",
                                 "VALUES" => end_years})
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
