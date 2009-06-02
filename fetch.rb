#!/usr/bin/ruby

# Database constructor of bouncer statistics.
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

##########################
# Deleting existing table
##########################

# This line was commented out not to remove the existing table by mistake.

#db.execute("drop table bouncer")

##########################
# Creating new table
##########################
sql = <<SQL
CREATE TABLE #{$tblname} (
  datejd integer,
  product varchar(100),
  os varchar(20),
  language varchar(10),
  downloads integer
);
SQL
db.execute(sql)


####################################################
# Fetch data from OpenOffice.org marketing website
####################################################

base_url = "http://marketing.openoffice.org/bouncer/"
extension = ".csv"
month = Date.new(2008,10,01)
#month = Date.new(2009,05,01)
while month <= Date.today
  url = base_url + month.strftime("%Y%m") + extension

  open(url){ |f|
    f.gets # header => discard
    f.each_line{ |line|
      date, product, os, language, downloads = line.chomp.split(",")
      date_jd = Date.parse(date).jd
      sql = "INSERT INTO #{$tblname} VALUES ('#{date_jd}', '#{product}', '#{os}', '#{language}', #{downloads.to_i})"
      db.execute(sql)

      puts "Registered: #{line}"
    }
  }

  month = month >> 1
end

db.close
