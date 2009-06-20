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
  f = open("query_chart.html") # Read the template
  str = f.gets(nil)
  f.close

  cgi = CGI.new("html4")
  cgi.out('charset'=>$charset) {
    str.gsub!('<SELECT NAME="type"><!-- REPLACE SELECT_TYPE --></SELECT>',
             cgi.scrolling_list({ "NAME" => "type",
                                  "VALUES" => type_values}))
    str.gsub!('<!-- REPLACE THIS_YEAR -->', end_date.strftime('%Y'))
    str.gsub!('<!-- REPLACE THIS_MONTH -->', end_date.strftime('%b %Y'))
    str.gsub!('<!-- REPLACE YESTERDAY -->', end_date.strftime('%d %b %Y'))
    str.gsub!('<SELECT NAME="start_day1"><!-- REPLACE START_DAY --></SELECT>',
              cgi.scrolling_list( {"NAME" => "start_day1",
                                   "VALUES" => start_days}))
    str.gsub!('<SELECT NAME="start_month1"><!-- REPLACE START_MONTH --></SELECT>',
              cgi.scrolling_list({ "NAME" => "start_month1",
                                   "VALUES" => start_months}))
    str.gsub!('<SELECT NAME="start_year1"><!-- REPLACE START_YEAR --></SELECT>',
              cgi.scrolling_list({ "NAME" => "start_year1",
                                   "VALUES" => start_years}))
    str.gsub!('<SELECT NAME="start_day2"><!-- REPLACE START_DAY --></SELECT>',
              cgi.scrolling_list( {"NAME" => "start_day2",
                                   "VALUES" => start_days}))
    str.gsub!('<SELECT NAME="start_month2"><!-- REPLACE START_MONTH --></SELECT>',
              cgi.scrolling_list({ "NAME" => "start_month2",
                                   "VALUES" => start_months}))
    str.gsub!('<SELECT NAME="start_year2"><!-- REPLACE START_YEAR --></SELECT>',
              cgi.scrolling_list({ "NAME" => "start_year2",
                                   "VALUES" => start_years}))
    str.gsub!('<SELECT NAME="end_day"><!-- REPLACE END_DAY --></SELECT>',
              cgi.scrolling_list( {"NAME" => "end_day",
                                   "VALUES" => end_days}))
    str.gsub!('<SELECT NAME="end_month"><!-- REPLACE END_MONTH --></SELECT>',
              cgi.scrolling_list({ "NAME" => "end_month",
                                   "VALUES" => end_months}))
    str.gsub!('<SELECT NAME="end_year"><!-- REPLACE END_YEAR --></SELECT>',
              cgi.scrolling_list({ "NAME" => "end_year",
                                   "VALUES" => end_years}))
    str.gsub!('<SELECT NAME="months"><!-- REPLACE MONTHS --></SELECT>',
              cgi.scrolling_list({ "NAME" => "months",
                                   "VALUES" => (1..12).to_a.map{|f| f.to_s} } ))
    str.gsub!('<SELECT NAME="product" SIZE="10" MULTIPLE><!-- REPLACE PRODUCTS --></SELECT>',
              cgi.scrolling_list( {"NAME" => "product",
                                   "VALUES" => products,
                                   "SIZE" => 10,
                                   "MULTIPLE" => true}))

    str.gsub!('<SELECT NAME="language" SIZE="10" MULTIPLE><!-- REPLACE LANGUAGES --></SELECT>',
              cgi.scrolling_list( {"NAME" => "language",
                                   "VALUES" => languages,
                                   "SIZE" => 10,
                                   "MULTIPLE" => true}))

    str.gsub!('<SELECT NAME="os" SIZE="10" MULTIPLE><!-- REPLACE OSES --></SELECT>',
              cgi.scrolling_list( {"NAME" => "os",
                                   "VALUES" => oses,
                                   "SIZE" => 10,
                                   "MULTIPLE" => true}))
    str
  }
ensure
  db.close if db
end
