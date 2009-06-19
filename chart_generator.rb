#!/usr/bin/ruby

# Chart generator class of bouncer statistics.
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
require 'cgi'

class KnownException < Exception; end

class ChartGenerator
  ###################################################
  # Initialization.
  ###################################################
  def initialize(dbfile, tblname)
    @db = SQLite3::Database.new(dbfile)
    @tbl = tblname
    @cgi = CGI.new("html4")

    check_argument
  end

  ###################################################
  # Getting arguments and checking the validity.
  ###################################################
  def check_argument
    # Dates:
    #  This CGI generates a chart based on the data generated between
    #  these days.
    res = @db.execute("SELECT MIN(datejd) FROM #{$tblname}")
    first_date = Date.jd(res[0][0].to_i)

    res = @db.execute("SELECT MAX(datejd) FROM #{$tblname}")
    last_date = Date.jd(res[0][0].to_i)

    case @cgi['period']
    when 'this_year'
      @start_date = Date.new(last_date.year, 1, 1)
      @end_date = last_date
    when 'this_month'
      @start_date = Date.new(last_date.year, last_date.month, 1)
      @end_date = last_date
    when 'yesterday'
      @start_date = @end_date = last_date
    when 'specified_to_yesterday'
      begin
        @start_date = Date.new(@cgi['start_year1'].to_i,
                               @cgi['start_month1'].to_i,
                               @cgi['start_day1'].to_i)
      rescue ArgumentError => exception
        raise KnownException,
        "Invalid date. Make sure the date you choose is correct and try again."
      end
      @end_date = last_date
    when 'specified'
      begin
        @start_date = Date.new(@cgi['start_year2'].to_i,
                               @cgi['start_month2'].to_i,
                               @cgi['start_day2'].to_i)
        @end_date = Date.new(@cgi['end_year'].to_i,
                             @cgi['end_month'].to_i,
                             @cgi['end_day'].to_i)
      rescue ArgumentError => exception
        raise KnownException,
        "Invalid date. Make sure the date you choose is correct and try again."
      end
    else
      raise KnownException,
      "Invalid period. Make sure the period you choose is correct and try again."
    end

    if @start_date > @end_date
      tmp = @start_date
      @start_date = @end_date
      @end_date = tmp
    end

    if @start_date < first_date
      raise KnownException,
      "no download data was recoreded on the day you specified, #{@start_date.strftime('%d %b %Y')}. Download data has been recorded since #{first_date.strftime('%d %b %Y')}."
    elsif @end_date > last_date
      raise KnownException,
      "no download data was recoreded on the day you specified, #{@end_date.strftime('%d %b %Y')}. The last date when the latest download log was updated was #{last_date.strftime('%d %b %Y')}."
    end

    # Products:
    #  This CGI generates a chart based on the data related to the
    #  specified product name like "OpenOffice.org". If there is
    #  "product=ALL", or if there is no arguments related to
    #  product, then all products will be selected for the chart
    #  data.
    @products = @cgi.params['product']
    @products = :all if @products.empty? || @products.include?("ALL")

    # Languagess:
    #  This CGI generates a chart based on the data related to the
    #  specified language name like "en-us". If there is "language=ALL",
    #  or if there is no arguments related to language, then all
    #  languages will be selected for the chart data.
    @languages = @cgi.params['language']
    @languages = :all if @languages.empty? || @languages.include?("ALL")

    # OS:
    #  This CGI generates a chart based on the data related to the
    #  specified the name of OS and architectures like "winwjre".
    #  If there is "os=ALL", or if there is no arguments related to
    #  OS, then all OSes will be selected for the chart data.
    @oses = @cgi.params['os']
    @oses = :all if @oses.empty? || @oses.include?("ALL")

    # Type of chart:
    #  This CGI generates a specified type of chart.
    @type = @cgi['type']
    if !$valid_types.include?(@type)
      raise KnownException, "Invalid argument for 'type': #{@type}"
    end
  end

  ###################################################
  # Generating SQL statement.
  ###################################################
  def sql_statement
    where_conds = "WHERE "

    # Conditions for products, languages and oses.
    { "product" => @products,
      "language" => @languages,
      "os" => @oses }.each{ |name, set|

      # Note that "set" cannot be empty here.
      # See the part of checking arguments.
      if set != :all # || set.empty?
        where_conds += "#{name} IN ("
        set.each{ |e| where_conds += "'#{e}', " }
        where_conds[-2] = ")"
        where_conds += "AND "
      end
    }

    # Conditions for date
    where_conds += "datejd>=#{@start_date.jd} AND datejd<=#{@end_date.jd} "

    sql = ""

    if @type == "pie_by_product"
      sql += "SELECT product, Sum(downloads) AS 'count' FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY product "
      sql += "ORDER BY product "
    elsif @type == "pie_by_language"
      sql += "SELECT language, Sum(downloads) AS 'count' FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY language "
      sql += "ORDER BY language "
    elsif @type == "pie_by_oswa" || @type == "pie_by_os"
      sql += "SELECT os, Sum(downloads) AS 'count' FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY os "
      sql += "ORDER BY os "
    elsif @type == "line_by_product"
      sql += "SELECT datejd, product, Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY datejd, product "
      sql += "ORDER BY product, datejd ASC "
    elsif @type == "line_by_language"
      sql += "SELECT datejd, language, Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY datejd, language "
      sql += "ORDER BY language, datejd ASC "
    elsif @type == "line_by_oswa" || @type == "line_by_os"
      sql += "SELECT datejd, os, Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY datejd, os "
      sql += "ORDER BY os, datejd ASC "
    elsif @type == "bar"
      sql += "SELECT datejd, Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY datejd "
      sql += "ORDER BY datejd ASC "
#    elsif @type == "bar_by_product"
#      sql += "SELECT datejd, product, Sum(downloads) FROM #{@tbl} "
#      sql += where_conds
#      sql += "GROUP BY datejd, product "
#      sql += "ORDER BY product, datejd ASC "
    elsif @type == "count"
      sql += "SELECT Sum(downloads) as 'count' FROM #{@tbl} "
      sql += where_conds
    end

    sql
  end

  ###################################################
  # Fetching data from database.
  ###################################################
  def select(sql)
#    STDERR.puts sql # for debug purpose
    @db.execute(sql)
  end

  ########################################################
  # Generate a chart and return SVG or HTML as a result
  ########################################################
  def generate
    # fetching data
    res = select(sql_statement)

    output = ""

    if @type == "count"
      output = @cgi.out('charset'=>$charset) {
        html = @cgi.html { 
          @cgi.head { @cgi.title{'OpenOffice.org Bouncer statistics'} } +
          @cgi.body { 
            res[0][0].to_i
          }
        }

        CGI.pretty(html)
      }
    elsif @type =~ /^pie/
      fields = []
      values = []

      if @type == "pie_by_os" # Special manipulation for this type of chart.
        # Group by OS name
        h = {}
        res.each{ |r|
          case r[0]
          when /^win/
            h["Windows"] = 0 unless h["Windows"]
            h["Windows"] += r[1].to_i
          when /^linux/
            h["Linux"] = 0 unless h["Linux"]
            h["Linux"] += r[1].to_i
          when /^macosx/
            h["Mac OS X"] = 0 unless h["Mac OS X"]
            h["Mac OS X"] += r[1].to_i
          when /^solaris/
            h["Solaris"] = 0 unless h["Solaris"]
            h["Solaris"] += r[1].to_i
          else
            h["Others"] = 0 unless h["Others"]
            h["Others"] += r[1].to_i
          end
        }

        # Show the chart in this order.
        ["Windows", "Linux", "Mac OS X", "Solaris", "Others"].each{ |os_name|
          if h[os_name]
            fields << os_name
            values << h[os_name]
          end
        }
      else
        res.each{ |r|
          fields << r[0]
          values << r[1].to_i
        }
      end

      if fields.size == 0
        raise KnownException, "No download was recorded in the condition you specified."
      end

      # Generate SVG chart
      require 'SVG/Graph/Pie'
      graph = SVG::Graph::Pie.new({ :height => 500,
                                    :width => 900,
                                    :fields => fields, })

      graph.add_data({ :data => values,
                       :title => 'Bouncer Statistics'})

      output << "Content-type: image/svg+xml\r\n\r\n"
      output << graph.burn()
    elsif @type =~ /^line/
      # set x label
      fields = []
      date = @start_date
      interval = ((@end_date - @start_date) / 20).round
      interval = 1 if interval < 1
      while date <= @end_date
        if (date - @start_date) % interval == 0 
          fields << date.strftime("%y/%m/%d")
        else
          fields << ""
        end
        date += 1
      end

      # set data
      lines = {}

      if @type == "line_by_os"
        res.each{ |r|
          date = Date.jd(r[0].to_i)
          i = date - @start_date

          case r[1]
          when /^win/
            lines["Windows"] = Array.new(fields.size, 0) unless lines["Windows"]
            lines["Windows"][i] += r[2].to_i
          when /^linux/
            lines["Linux"] = Array.new(fields.size, 0) unless lines["Linux"]
            lines["Linux"][i] += r[2].to_i
          when /^macosx/
            lines["Mac OS X"] = Array.new(fields.size, 0) unless lines["Mac OS X"]
            lines["Mac OS X"][i] += r[2].to_i
          when /^solaris/
            lines["Solaris"] = Array.new(fields.size, 0) unless lines["Solaris"]
            lines["Solaris"][i] += r[2].to_i
          else
            lines["Others"] = Array.new(fields.size, 0) unless lines["Others"]
            lines["Others"][i] += r[2].to_i
          end
        }
      else
        res.each{ |r|
          lines[r[1]] = Array.new(fields.size, 0) if lines[r[1]] == nil

          date = Date.jd(r[0].to_i)
          i = date - @start_date
          lines[r[1]][i] = r[2].to_i
        }
      end

      if lines.size == 0
        raise KnownException, "No download data in the condition you specified."
      end

      require 'SVG/Graph/Line'
      graph = SVG::Graph::Line.new({ :height => 500,
                                     :width => 900,
                                     :fields => fields,
                                     :min_scale_value => 0,
                                     :show_data_values => false, 
                                     :scale_integers => true,
                                     :min_x_value => 0,
                                     :min_y_value => 0,
                                     :show_x_title => false,
                                     :y_title => "D/L a day",
                                     :y_title_font_size => 18,
                                     :show_y_title => true, 
                                     :rotate_x_labels => true, })

      lines.each{ |title,data|
        graph.add_data({ :data => data,
                         :title => title })
      }
      output << "Content-type: image/svg+xml\r\n\r\n"
      output << graph.burn()
    elsif @type == "bar"
      fields = []
      values = []

      date = Date.jd(res[0][0].to_i)
      count = 0

      res.each{ |r|
        if date.month != Date.jd(r[0].to_i).month
          fields << date.strftime("%b %Y")
          values << count

          date = Date.jd(r[0].to_i)
          count = 0
        end

        count += r[1].to_i
      }

      fields << date.strftime("%b %Y")
      values << count

      require 'SVG/Graph/Bar'
      graph = SVG::Graph::Bar.new({ :height => 500,
                                    :width => 900,
                                    :scale_integers => true,
                                    :stack => :side,
                                    :fields => fields, })

      graph.add_data(:data => values, :title => 'D/L')

      output << "Content-type: image/svg+xml\r\n\r\n"
      output << graph.burn()
    else
      raise KnownException, "Invalid argument for 'type': #{@type}"
    end

    output
  end
end
