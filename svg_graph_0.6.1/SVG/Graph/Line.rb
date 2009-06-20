require 'SVG/Graph/Graph'

module SVG
  module Graph
    # === Create presentation quality SVG line graphs easily
    # 
    # = Synopsis
    # 
    #   require 'SVG/Graph/Line'
    # 
    #   fields = %w(Jan Feb Mar);
    #   data_sales_02 = [12, 45, 21]
    #   data_sales_03 = [15, 30, 40]
    #   
    #   graph = SVG::Graph::Line.new({
    #   	:height => 500,
    #    	:width => 300,
    # 	  :fields => fields,
    #   })
    #   
    #   graph.add_data({
    #   	:data => data_sales_02,
    # 	  :title => 'Sales 2002',
    #   })
    # 
    #   graph.add_data({
    #   	:data => data_sales_03,
    # 	  :title => 'Sales 2003',
    #   })
    #   
    #   print "Content-type: image/svg+xml\r\n\r\n";
    #   print graph.burn();
    # 
    # = Description
    # 
    # This object aims to allow you to easily create high quality
    # SVG line graphs. You can either use the default style sheet
    # or supply your own. Either way there are many options which can
    # be configured to give you control over how the graph is
    # generated - with or without a key, data elements at each point,
    # title, subtitle etc.
    # 
    # = Examples
    # 
    # http://www.germane-software/repositories/public/SVG/test/single.rb
    # 
    # = Notes
    # 
    # The default stylesheet handles upto 10 data sets, if you
    # use more you must create your own stylesheet and add the
    # additional settings for the extra data sets. You will know
    # if you go over 10 data sets as they will have no style and
    # be in black.
    # 
    # = See also
    # 
    # * SVG::Graph::Graph
    # * SVG::Graph::BarHorizontal
    # * SVG::Graph::Bar
    # * SVG::Graph::Pie
    # * SVG::Graph::Plot
    # * SVG::Graph::TimeSeries
    #
    # == Author
    #
    # Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
    #
    # Copyright 2004 Sean E. Russell
    # This software is available under the Ruby license[LICENSE.txt]
    #
    class Line < SVG::Graph::Graph
      #    Show a small circle on the graph where the line
      #    goes from one point to the next.
      attr_accessor :show_data_points
      #    Accumulates each data set. (i.e. Each point increased by sum of 
      #   all previous series at same point). Default is 0, set to '1' to show.
      attr_accessor :stacked
      # Fill in the area under the plot if true
      attr_accessor :area_fill

      # The constructor takes a hash reference, fields (the names for each
      # field on the X axis) MUST be set, all other values are defaulted to 
      # those shown above - with the exception of style_sheet which defaults
      # to using the internal style sheet.
      def initialize config
        raise "fields was not supplied or is empty" unless config[:fields] &&
        config[:fields].kind_of?(Array) &&
        config[:fields].length > 0
				super
			end

      # In addition to the defaults set in Graph::initialize, sets
      # [show_data_points] true
      # [show_data_values] true
      # [stacked] false
      # [area_fill] false
			def set_defaults
        init_with(
          :show_data_points   => true,
          :show_data_values   => true,
          :stacked            => false,
          :area_fill          => false
        )

        self.top_align = self.top_font = self.right_align = self.right_font = 1
      end

      protected

      def max_value
        max = 0
        
        if (stacked == true) then
          sums = Array.new(@config[:fields].length).fill(0)

          @data.each do |data|
            sums.each_index do |i|
              sums[i] += data[:data][i].to_f
            end
          end
          
          max = sums.max
        else
          max = @data.collect{|x| x[:data].max}.max
        end

        return max
      end

      def min_value
        min = 0
        
        if (min_scale_value.nil? == false) then
          min = min_scale_value
        elsif (stacked == true) then
          min = @data[-1][:data].min
        else
          min = @data.collect{|x| x[:data].min}.min
        end

        return min
      end

      def get_x_labels
        @config[:fields]
      end

      def calculate_left_margin
        super
        label_left = @config[:fields][0].length / 2 * font_size * 0.6
        @border_left = label_left if label_left > @border_left
      end

      # This methods was modified by Takashi Nakamoto
      # <bluedwarf@bpost.plala.or.jp>
      def get_y_labels
        maxvalue = max_value
        minvalue = min_value
        range = maxvalue - minvalue
        top_pad = range == 0 ? 10 : range / 20.0
        scale_range = (maxvalue + top_pad) - minvalue

        scale_division = scale_divisions || (scale_range / 10.0)

        if scale_integers
          scale_division = scale_division < 1 ? 1 : scale_division.round

          digit = scale_division.to_s.size
          i = scale_division.to_s[0..0].to_i
          scale_division = i*(10**(digit-1))
        end

        rv = []
        maxvalue = maxvalue%scale_division == 0 ? 
          maxvalue : maxvalue + scale_division
        minvalue.step( maxvalue, scale_division ) {|v| rv << v}
        return rv
      end

      def calc_coords(field, value, width = field_width, height = field_height)
        coords = {:x => 0, :y => 0}
        coords[:x] = width * field
        coords[:y] = @graph_height - value * height
      
        return coords
      end

      def draw_data
        minvalue = min_value
        fieldheight = (@graph_height.to_f - font_size*2*top_font) / 
                         (get_y_labels.max - get_y_labels.min)
        fieldwidth = field_width
        line = @data.length

        prev_sum = Array.new(@config[:fields].length).fill(0)
        cum_sum = Array.new(@config[:fields].length).fill(-minvalue)

        for data in @data.reverse
          lpath = ""
          apath = ""

          if not stacked then cum_sum.fill(-minvalue) end
          
          data[:data].each_index do |i|
            cum_sum[i] += data[:data][i]
            
            c = calc_coords(i, cum_sum[i], fieldwidth, fieldheight)
            
            lpath << "#{c[:x]} #{c[:y]} "
          end
        
          if area_fill
            if stacked then
              (prev_sum.length - 1).downto 0 do |i|
                c = calc_coords(i, prev_sum[i], fieldwidth, fieldheight)
                
                apath << "#{c[:x]} #{c[:y]} "
              end
          
              c = calc_coords(0, prev_sum[0], fieldwidth, fieldheight)
            else
              apath = "V#@graph_height"
              c = calc_coords(0, 0, fieldwidth, fieldheight)
            end
              
            @graph.add_element("path", {
              "d" => "M#{c[:x]} #{c[:y]} L" + lpath + apath + "Z",
              "class" => "fill#{line}"
            })
          end
        
          @graph.add_element("path", {
            "d" => "M0 #@graph_height L" + lpath,
            "class" => "line#{line}"
          })
          
          if show_data_points || show_data_values
            cum_sum.each_index do |i|
              if show_data_points
                @graph.add_element( "circle", {
                  "cx" => (fieldwidth * i).to_s,
                  "cy" => (@graph_height - cum_sum[i] * fieldheight).to_s,
                  "r" => "2.5",
                  "class" => "dataPoint#{line}"
                })
              end
              make_datapoint_text( 
                fieldwidth * i, 
                @graph_height - cum_sum[i] * fieldheight - 6,
                cum_sum[i] + minvalue
              )
            end
          end

          prev_sum = cum_sum.dup
          line -= 1
        end
      end


      def get_css
        # This methods was modified by Takashi Nakamoto
        # <bluedwarf@bpost.plala.or.jp>

        css = ""

        color_set_base = [[0, 69, 134],
                          [255, 66, 14],
                          [255, 211, 32],
                          [87, 157, 28],
                          [126, 0, 33],
                          [131, 202, 255],
                          [49, 64, 4],
                          [174, 207, 0],
                          [75, 31, 111],
                          [255, 149, 14],
                          [197, 0, 11]] # in RGB
        color_set = color_set_base.clone

        # light colours
        color_set_base.each{ |c|
          color_set << c.map{|e|
            if e*3/2 > 255
              255
            else
              e*3/2
            end
          }
        }

        # dark colours
        color_set_base.each{ |c|
          color_set << c.map{|e| e/2}
        }

        @data.each_index{ |i|
          j = i % color_set.size
          r = color_set[j][0].to_s(16)
          g = color_set[j][1].to_s(16)
          b = color_set[j][2].to_s(16)

          r = "0" + r if r.size == 1
          g = "0" + g if g.size == 1
          b = "0" + b if b.size == 1

          css << <<EOL
.line#{i+1}{
	fill: none;
	stroke: \##{r}#{g}#{b};
	stroke-width: 1px;
}
.fill#{i+1}{
	fill: \##{r}#{g}#{b};
	fill-opacity: 0.2;
	stroke: none;
}
.key#{i+1},.dataPoint#{i+1}{
	fill: \##{r}#{g}#{b};
	stroke: none;
	stroke-width: 1px;	
}
EOL
        }

        return css
      end
    end
  end
end
