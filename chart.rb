#!/usr/bin/ruby

# Chart generator of bouncer statistics.
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

require './conf.rb'
require './chart_generator.rb'

output = ""

begin
  generator = ChartGenerator.new($dbfile, $tblname)
  output = generator.generate
rescue KnownException => exception
  cgi = CGI.new("html4")
  cgi.out('charset'=>$charset) {
    html = cgi.html {
      cgi.head { cgi.title{'ERROR - OpenOffice.org Bouncer statistics'} } +
      cgi.body {
        cgi.h1 { "ERROR - OpenOffice.org Bouncer statistics: Query for chart" } +
        cgi.p {
          "Your request was invalid because;"
        } +
        cgi.p {
          exception.message
        }
      }
    }
  }
rescue => exception # for unknown exception
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
          "Query:"
        } +
        cgi.p {
          cgi.query_string
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
  print output
end

