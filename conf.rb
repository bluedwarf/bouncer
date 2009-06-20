$dbfile = 'bouncer.db'
$tblname = 'bouncer'
$contact = 'bluedwarf@openoffice.org'
$charset = 'utf-8'

$name_types = ["Pie chart (by product)",
               "Pie chart (by language)",
               "Pie chart (by OS and architecture)",
               "Pie chart (by OS)",
               "Line chart (by product)",
               "Line chart (by language)",
               "Line chart (by OS and architecture)",
               "Line chart (by OS)",
               "Monthly bar chart",
               "Monthly bar chart (by product)",
               "Monthly bar chart (by language)",
               "Monthly bar chart (by OS and architecture)",
               "Monthly bar chart (by OS)",
               "Download counter"]

$valid_types = ["pie_by_product",
                "pie_by_language",
                "pie_by_oswa", # Pie chart by OS with architecture name
                "pie_by_os", # Pie chart by OS names like "Windows"
                "line_by_product",
                "line_by_language",
                "line_by_oswa", # Line chart by OS with architecture name
                "line_by_os", # Line chart by OS names like "Windows"
                "bar",
                "bar_by_product",
                "bar_by_language",
                "bar_by_oswa",
                "bar_by_os",
                "count"]

require 'date'
$first_date = Date.new(2008,10,13)

# TODO: This is ugly hack to be removed in the future.
$LOAD_PATH.unshift 'C:\ruby\lib\ruby\gems\1.8\gems\sqlite3-ruby-1.2.3-x86-mswin32\lib'
$LOAD_PATH.unshift "./svg_graph_0.6.1"
