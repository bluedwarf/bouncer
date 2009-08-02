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

    # create OS grouping rule
    if @type =~ /by_os$/
      @osnames = ["Windows", "Linux", "Mac OS X", "Solaris", "Others"]
      cases = ["win%", "linux%", "macosx%", "solaris%"]

      @osname_case = "CASE "
      cases.each_index{ |i|
        case_str = cases[i]
        osname = @osnames[i]
        
        @osname_case += "WHEN os LIKE '#{case_str}' THEN '#{osname}' "
      }
      @osname_case += "ELSE '#{@osnames[-1]}' END "
    end

    # carete month grouping rule
    if @type =~ /^bar/
      @periods = []
      date = @start_date
      while date <= @end_date
        first_date = date
        next_month = first_date >> 1
        date = Date.new(next_month.year, next_month.month, 1)
        last_date = date - 1
        if  first_date.year == @end_date.year &&
            first_date.month == @end_date.month
          last_date = @end_date
        end

        @periods << [first_date, last_date, first_date.strftime("%Y-%m")]
      end

      @month_case = "CASE "
      @periods.each{ |a|
        first_date = a[0]
        last_date = a[1]
        month_name = a[2] # month_name "%Y-%m"

        @month_case += "WHEN datejd>=#{first_date.jd} AND "
        @month_case += "datejd<=#{last_date.jd} "
        @month_case += "THEN '#{month_name}' "
      }
      @month_case += "END "
    end
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
    when 'last_months'
      months = @cgi['months'].to_i
      @end_date = last_date
      @start_date = last_date << (months - 1)
      @start_date = Date.new(@start_date.year, @start_date.month, 1)
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
    elsif @type == "pie_by_oswa"
      sql += "SELECT os, Sum(downloads) AS 'count' FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY os "
      sql += "ORDER BY os "
    elsif @type == "pie_by_os"
      sql = "SELECT #{@osname_case} AS osname, "
      sql += "Sum(downloads) AS 'count' "
      sql += "FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY osname "
      sql += "ORDER BY osname "
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
    elsif @type == "line_by_oswa"
      sql += "SELECT datejd, os, Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY datejd, os "
      sql += "ORDER BY os, datejd ASC "
    elsif @type == "line_by_os"
      sql += "SELECT datejd, "
      sql += "#{@osname_case} AS osname, "
      sql += "Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY datejd, osname "
      sql += "ORDER BY osname, datejd ASC "
    elsif @type == "bar"
      sql += "SELECT "
      sql += "#{@month_case} AS month, "
      sql += "Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY month "
      sql += "ORDER BY month ASC "
    elsif @type == "bar_by_product"
      sql += "SELECT "
      sql += "#{@month_case} AS month, "
      sql += "product, "
      sql += "Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY month, product "
      sql += "ORDER BY product ASC, month ASC "
    elsif @type == "bar_by_language"
      sql += "SELECT "
      sql += "#{@month_case} AS month, "
      sql += "language, "
      sql += "Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY month, language "
      sql += "ORDER BY language ASC, month ASC "
    elsif @type == "bar_by_oswa"
      sql += "SELECT "
      sql += "#{@month_case} AS month, "
      sql += "os, "
      sql += "Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY month, os "
      sql += "ORDER BY os ASC, month ASC "
    elsif @type == "bar_by_os"
      sql += "SELECT "
      sql += "#{@month_case} AS month, "
      sql += "#{@osname_case} AS osname, "
      sql += "Sum(downloads) FROM #{@tbl} "
      sql += where_conds
      sql += "GROUP BY month, osname "
      sql += "ORDER BY osname ASC, month ASC "
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

      res.each{ |r|
        fields << r[0]
        values << r[1].to_i
      }

      if fields.size == 0
        raise KnownException, "No download was recorded in the condition you specified."
      end

      # Reorder in the order of @osnames
      if @type == "pie_by_os"
        new_fields = []
        new_values = []

        @osnames.each{ |osname|
          i = fields.index(osname)
          if i != nil
            new_fields << fields[i]
            new_values << values[i]
          end
        }

        fields = new_fields
        values = new_values
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
      res.each{ |r|
        lines[r[1]] = Array.new(fields.size, 0) if lines[r[1]] == nil

        date = Date.jd(r[0].to_i)
        i = date - @start_date
        lines[r[1]][i] = r[2].to_i
      }

      if lines.size == 0
        raise KnownException, "No download data was recorded in the condition you specified. Please try another query."
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

      if @type == "line_by_os"
        titles = @osnames
      else
        titles = lines.keys.sort
      end

      titles.each{ |title|
        if lines[title]
          graph.add_data({ :data => lines[title],
                           :title => title })
        end
      }

      output << "Content-type: image/svg+xml\r\n\r\n"
      output << graph.burn()
    elsif @type == "bar"
      fields = []
      values = []

      res.each{ |r|
        if r[0] =~ /(\d{4})\-(\d{2})/
          fields << Date.new($1.to_i, $2.to_i, 1).strftime("%b %Y")
        else
          raise "Unknown problem occured while creating month expression."
        end

        values << r[1].to_i
      }

      require 'SVG/Graph/Bar'
      graph = SVG::Graph::Bar.new({ :height => 500,
                                    :width => 900,
                                    :scale_integers => true,
                                    :stack => :side,
                                    :fields => fields, })

      graph.add_data(:data => values, :title => 'D/L')

      output << "Content-type: image/svg+xml\r\n\r\n"
      output << graph.burn()
    elsif @type =~ /^bar/
      fields = []
      @periods.each{ |a| fields << a[2] } # month_name "%Y-%m"

      value_set = {}
      res.each{ |r|
        value_set[r[1]] = Array.new(fields.size, 0) if value_set[r[1]] == nil

        i = fields.index(r[0])
        value_set[r[1]][i] = r[2].to_i
      }

      if value_set.size == 0
        raise KnownException, "No download data was recorded in the condition you specified. Please try another query."
      end

      # Replace month description with "%b %Y"
      fields.map!{ |f|
        if f =~ /(\d{4})\-(\d{2})/
          Date.new($1.to_i, $2.to_i, 1).strftime("%b %Y")
        else
          raise "Unknown problem occured while creating month expression."
        end
      }

      require 'SVG/Graph/Bar'
      graph = SVG::Graph::Bar.new({ :height => 500,
                                    :width => 900,
                                    :scale_integers => true,
                                    :stack => :side,
                                    :fields => fields, })

      if @type == "bar_by_os"
        titles = @osnames
      else
        titles = value_set.keys.sort
      end

      titles.each{ |title|
        if value_set[title]
          graph.add_data( :data => value_set[title],
                          :title => title)
        end
      }

      output << "Content-type: image/svg+xml\r\n\r\n"
      output << graph.burn()
    else
      raise KnownException, "Invalid argument for 'type': #{@type}"
    end

    output
  end
end
