require 'rexml/document'
require 'SVG/Graph/Graph'

module SVG
  module Graph
		# = Synopsis
		#
		# A superclass for bar-style graphs.  Do not attempt to instantiate
		# directly; use one of the subclasses instead.
		#
    # = Author
    #
    # Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
		#
    # Copyright 2004 Sean E. Russell
		# This software is available under the Ruby license[LICENSE.txt]
    #
    class BarBase < SVG::Graph::Graph
			# Ensures that :fields are provided in the configuration.
      def initialize config
        raise "fields was not supplied or is empty" unless config[:fields] &&
        config[:fields].kind_of?(Array) &&
        config[:fields].length > 0
				super
			end

			# In addition to the defaults set in Graph::initialize, sets
			# [bar_gap] true
			# [stack] :overlap
			def set_defaults
        init_with( :bar_gap => true, :stack => :overlap )
      end

      #   Whether to have a gap between the bars or not, default
      #   is true, set to false if you don't want gaps.
      attr_accessor :bar_gap
      #   How to stack data sets.  :overlap overlaps bars with
      #   transparent colors, :top stacks bars on top of one another,
      #   :side stacks the bars side-by-side. Defaults to :overlap.
      attr_accessor :stack


			protected

      def max_value
        @data.collect{|x| x[:data].max}.max
      end

      def min_value
        min = 0
        if min_scale_value.nil? 
          min = @data.collect{|x| x[:data].min}.min
          min = min > 0 ? 0 : min
        else
          min = min_scale_value
        end
        return min
      end

      def get_css
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
.key#{i+1},.fill#{i+1}{
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
