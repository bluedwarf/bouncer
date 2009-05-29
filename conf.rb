$dbfile = 'bouncer.db'
$tblname = 'bouncer'

$valid_types = ["pie_by_product",
                "pie_by_language",
                "pie_by_oswa", # Pie chart by OS with architecture name
                "pie_by_os", # Pie chart by just OS name like "Windows"
                "count"]

# TODO: This is ugly hack to be removed in the future.
$LOAD_PATH.unshift 'C:\ruby\lib\ruby\gems\1.8\gems\sqlite3-ruby-1.2.3-x86-mswin32\lib'
$LOAD_PATH.unshift "./svg_graph_0.6.1"
