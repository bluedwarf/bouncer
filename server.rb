#!/usr/bin/ruby

# Test server for chart generator of bouncer statistics.
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

require 'webrick'

httpd = WEBrick::HTTPServer.new(:DocumentRoot => 'C:\ruby\work\bouncer',
                                :Port => 3000,
                                :CGIInterpreter => 'C:\ruby\bin\ruby.exe',
                                :DirectoryIndex => ['index.html'])

httpd.mount('/query_chart.rb',
            WEBrick::HTTPServlet::CGIHandler,
            'query_chart.rb')
httpd.mount('/chart.rb', WEBrick::HTTPServlet::CGIHandler, 'chart.rb')

trap(:INT) do
  httpd.shutdown
end
httpd.start
