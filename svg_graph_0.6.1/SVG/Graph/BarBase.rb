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
        return <<EOL
/* default fill styles for multiple datasets (probably only use a single dataset on this graph though) */
.key1,.fill1{
	fill: #004586;
	stroke: none;
	stroke-width: 0.5px;	
}
.key2,.fill2{
	fill: #ff420e;
	stroke: none;
	stroke-width: 1px;	
}
.key3,.fill3{
	fill: #ffd320;
	stroke: none;
	stroke-width: 1px;	
}
.key4,.fill4{
	fill: #579d1c;
	stroke: none;
	stroke-width: 1px;	
}
.key5,.fill5{
	fill: #7e0021;
	stroke: none;
	stroke-width: 1px;	
}
.key6,.fill6{
	fill: #83caff;
	stroke: none;
	stroke-width: 1px;	
}
.key7,.fill7{
	fill: #314004;
	stroke: none;
	stroke-width: 1px;	
}
.key8,.fill8{
	fill: #aecf00;
	stroke: none;
	stroke-width: 1px;	
}
.key9,.fill9{
	fill: #4b1f6f;
	stroke: none;
	stroke-width: 1px;	
}
.key10,.fill10{
	fill: #ff950e;
	stroke: none;
	stroke-width: 1px;	
}
.key11,.fill11{
	fill: #c5000b;
	stroke: none;
	stroke-width: 1px;	
}
EOL
      end
    end
  end
end
