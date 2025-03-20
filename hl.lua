-- Lua script to highlight strings in an Nvim buffer using perl instead of vim regex search tool (/)

local M = {}

function M.get_perl_regex_matches(perl_regex)
   local buf_text_table = vim.api.nvim_buf_get_lines(0, 0, -1, true)          -- Get the perl query file
   local buf_text_string = table.concat(buf_text_table, "\n")                 -- Read the lines from the buffer into a lua tableb
   local perl_script_location = './search_highlight.pl'                       -- Store the location of the perl file into a string
   local match_table = {}                                                     -- Lua table that will be used later to keep record of the current cursor position and 
                                                                              -- next/prev cursor position (for the functionality to scroll forward/backward through the 
                                                                              -- highlighted regex-matches using 'n' and 'N')
   local perl_namespace_id = vim.api.nvim_create_namespace('perl_highlight')  -- Lua namespace that contains the record of all the highlights made using this script
   vim.api.nvim_buf_clear_namespace(0, perl_namespace_id, 0, -1)              -- Clear the previous highlights that were made using this lua + perl script

   local perl_command = string.format(                                     -- Create the perl command to be called by lua & run the perl command on the text
      "perl %s %s",
      perl_script_location,
      perl_regex 
   )
   local perl_command_output_table = vim.fn.systemlist(perl_command, buf_text_string) -- Output from the perl script containing multiple lines with each line 
                                                                           -- being of the form: lineno startcolno endcolno. Note that in the command, buf_text_string will 
                                                                           -- be provided to perl_command as STDIN and perl will pick it up from there
   for _, match in ipairs(perl_command_output_table) do                    -- Loop to highlight the regex match with coordinates as those in each line of the perl output
      local line, start_col, end_col = match:match("(%d+) (%d+) (%d+)")    -- Parse each line with 3 numbers (%d+) in each line
      if line and start_col and end_col then                               -- Process only if there is at least one match found by the perl script
         line = tonumber(line)                                             -- Convert the strings in each line to number
         start_col = tonumber(start_col)
         end_col = tonumber(end_col)
         table.insert(match_table, {line, start_col, end_col})             -- Add the numericized items to the match table
         vim.api.nvim_buf_add_highlight(                                   -- Highlight the match in nvim buffer
            0,                                                             -- Buffer Id
            perl_namespace_id,                                             -- Namespace ID (tagged to clear related match-highlights later on using this ID)
            'Search',
            tonumber(line),                                                -- Highlight coordinates
            tonumber(start_col),
            tonumber(end_col)
         )
      end
   end
   table.sort(match_table, function(a, b) return a[1] < b[1] or ((a[1] == b[1]) and (a[2] < b[2])) end) -- Sort the match table in increasing order of the match-coordinates
   match_table_rev = {unpack(match_table)}                                 -- Create a table that is reverse of the above table
   table.sort(match_table_rev, function(a, b) return a[1] > b[1] or ((a[1] == b[1]) and (a[2] > b[2])) end)
   vim.g.match_table = match_table                                         -- Storing the match_table into a variable that can be accessed by nvim outside this script (helpful in 
                                                                           -- using the match table to set up scrolling functinality using keymaps in nvim) (used for forward scroll)
   vim.g.match_table_rev = match_table_rev
end

return M
