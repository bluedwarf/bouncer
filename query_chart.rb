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
     "August", "September", "October", "November", "December"]

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

  start_months = (1..12).to_a.map{ |i|
    if start_date.month == i
      [i.to_s, months[i-1], true]
    else
      [i.to_s, months[i-1]]
    end
  }

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

  end_months = (1..12).to_a.map{ |i|
    if end_date.month == i
      [i.to_s, months[i-1], true]
    else
      [i.to_s, months[i-1]]
    end
  }

  end_years = ((start_date.year)..(end_date.year)).to_a.map{ |a|
    if a == end_date.year
      [a.to_s, true]
    else
      a.to_s
    end
  }

  type_values = []
  $valid_types.each_index{ |index|
    type_values << [$valid_types[index], $name_types[index]]
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
        cgi.h1 { "<SMALL>OpenOffice.org Bouncer statistics:</SMALL><BR> Query for chart" } +
        cgi.form('METHOD'=>'GET', 'ACTION'=>'chart.rb') {
          cgi.p {
            "<B>Chart type: </B>" +
            cgi.scrolling_list({"NAME" => "type",
                                 "VALUES" => type_values})
          } +
          cgi.p {
            "<B>Period: </B><BR>" +
            cgi.radio_button("period", "this_year", true) +
            "This year (#{end_date.strftime('%Y')}) <BR>" +

            cgi.radio_button("period", "this_month") +
            "This month (#{end_date.strftime('%b %Y')}) <BR>" +

            cgi.radio_button("period", "yesterday") +
            "Yesterday (#{end_date.strftime('%d %b %Y')}) <BR>" +

            cgi.radio_button("period", "specified_to_yesterday") +
            cgi.scrolling_list({"NAME" => "start_day1",
                                 "VALUES" => start_days}) +
            cgi.scrolling_list({"NAME" => "start_month1",
                                 "VALUES" => start_months}) +
            cgi.scrolling_list({"NAME" => "start_year1",
                                 "VALUES" => start_years}) +
            "- Yesterday (#{end_date.strftime('%d %b %Y')}) <BR>" +
            
            cgi.radio_button("period", "specified") +
            cgi.scrolling_list({"NAME" => "start_day2",
                                 "VALUES" => start_days}) +
            cgi.scrolling_list({"NAME" => "start_month2",
                                 "VALUES" => start_months}) +
            cgi.scrolling_list({"NAME" => "start_year2",
                                 "VALUES" => start_years}) +
            " - " +
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
              cgi.th {"Product (*):"} + cgi.th {"Language (*):"} + cgi.th {"OS (*): "}
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
            cgi.submit("Show")
          } +
          cgi.p {
            "(*) Leave nothing selected to cover all elements listed."
          } +
          cgi.p {
            "(**) The chart will be provided in SVG format. If you want to view this chart with Internet Explorer, you need to install a plugin for viewing SVG such as <a href='http://www.adobe.com/svg/viewer/install/main.html'>Adobe SVG Viewer</a>."
          }
        }       
      }
    }

    CGI.pretty(html)
  }
ensure
  db.close if db
end
