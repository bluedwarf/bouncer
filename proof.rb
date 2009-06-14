#!/usr/bin/ruby

# Database updater of bouncer statistics (for false database).
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
 
require 'sqlite3'
require 'open-uri'
 
db = SQLite3::Database.new($dbfile)
 
base_url = "http://marketing.openoffice.org/bouncer/"
extension = ".csv"
 
months = [Date.today]
months.each{ |month|
  url = base_url + month.strftime("%Y%m") + extension
 
  open(url){ |f|
    f.gets # header => discard
    f.each_line{ |line|
      date, product, os, language, downloads = line.chomp.split(",")
      date_jd = Date.parse(date).jd
 
      sql = "SELECT * FROM #{$tblname} WHERE datejd=#{date_jd} AND product='#{product}' AND os='#{os}' AND language='#{language}'"
      res = db.execute(sql)
 
      if res.empty?
        sql = "INSERT INTO #{$tblname} VALUES ('#{date_jd}', '#{product}', '#{os}', '#{language}', #{downloads.to_i})"
        db.execute(sql)
 
        puts "Registered: #{line}"
      end
    }
  }
}
 
db.close
