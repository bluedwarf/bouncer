#!/usr/bin/ruby

# Unit test of chart generator class of bouncer statistics.
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

require 'test/unit'
begin
  require 'fastercsv'
  $CSV = FasterCSV
rescue LoadError
  require 'csv'
  $CSV = CSV
end
require './chart_generator.rb'

class TC_CharGenerator < Test::Unit::TestCase
  def setup
  end

  # Test the download count.
  def test_downloadcount
    ARGV.replace(["period=specified&start_day2=1&start_month2=5&start_year2=2009&end_day=31&end_month=5&end_year=2009&type=count"])
    generator = ChartGenerator.new($dbfile, $tblname)
    res = generator.select(generator.sql_statement)

    assert_equal(7415320, res[0][0].to_i)
  end

  def test_downloadcount_ja1
    ARGV.replace(["period=specified&start_day2=1&start_month2=5&start_year2=2009&end_day=31&end_month=5&end_year=2009&type=count&language=ja"])
    generator = ChartGenerator.new($dbfile, $tblname)
    res = generator.select(generator.sql_statement)

    assert_equal(560259, res[0][0].to_i)
  end

  def test_downloadcount_ja2
    ARGV.replace(["period=specified&start_day2=1&start_month2=5&start_year2=2009&end_day=1&end_month=5&end_year=2009&type=count&language=ja"])

    generator = ChartGenerator.new($dbfile, $tblname)
    res = generator.select(generator.sql_statement)

    assert_equal(13520, res[0][0].to_i)
  end

  def test_pie_by_product
    ARGV.replace(["period=specified&start_day2=1&start_month2=5&start_year2=2009&end_day=31&end_month=5&end_year=2009&type=pie_by_product"])
    generator = ChartGenerator.new($dbfile, $tblname)
    res = generator.select(generator.sql_statement)

    a = $CSV.read("testcase/may2009_total_by_product.csv")
    a.shift

    assert_equal(a, res)
  end

  def test_pie_by_language
    ARGV.replace(["period=specified&start_day2=1&start_month2=5&start_year2=2009&end_day=31&end_month=5&end_year=2009&type=pie_by_language"])
    generator = ChartGenerator.new($dbfile, $tblname)
    res = generator.select(generator.sql_statement)

    a = $CSV.read("testcase/may2009_total_by_language.csv")
    a.shift

    assert_equal(a, res)
  end

  def test_pie_by_os
    ARGV.replace(["period=specified&start_day2=1&start_month2=5&start_year2=2009&end_day=31&end_month=5&end_year=2009&type=pie_by_os"])
    generator = ChartGenerator.new($dbfile, $tblname)
    res = generator.select(generator.sql_statement)

    a = $CSV.read("testcase/may2009_total_by_os.csv")
    a.shift

    assert_equal(a, res)
  end
end
