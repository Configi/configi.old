textfile.render[[
  src "textfile_render_string.txt"
  dest "test/tmp/textfile_render_test.txt"
  view "view_model"
  lua "textfile_render_data.lua"
  diff "true"
]]
