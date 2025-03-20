-- Lua script to highlight strings in an Nvim buffer using perl instead of vim regex search tool (/)

local buf_text_table = vim.api.nvim_buf_get_lines(0, 0, -1, true)    -- Get the perl query file
local buf_text_single_string = table.concat(buf_text_table, "\n")    -- Read the lines from the buffer into a lua tableb
local perl_script_location = './search_highlight.pl'                 -- Store the location of the perl file into a string
local perl_regex = 'local'                                           -- Capture the perl regex query (note that I'm working on adding functionality to be able to provide this query as a dynamic argument, rather than hard coding it here)

local perl_command = string.format(                                  -- Create the perl command to be called by lua & run the perl command on the text
   "perl %s %s",
   perl_script_location,
   perl_regex 
)

local perl_command_output_table = vim.fn.systemlist(perl_command, buf_text_single_string) -- Output from the perl script containing multiple lines
                                                                                          -- with each line being of the form: lineno startcolno endcolno
local match_table = {} -- Lua table that will be used later to keep record of the current cursor position and next/prev cursor position (for the functionality to scroll forward/backward through the highlighted regex-matches using 'n' and 'N')

local perl_namespace_id = vim.api.nvim_create_namespace('perl_highlight')  -- Lua namespace that contains the record of all the highlights made using this script
vim.api.nvim_buf_clear_namespace(0, perl_namespace_id, 0, -1)              -- Clear the previous highlights that were made using this lua + perl script

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

table.sort(match_table, function(a, b) return a[1] < b[1] or ((a[1] == b[1]) and (a[2] < b[2])) end)     -- Sort the match table in increasing order of the match-coordinates
                                                                                                         -- (used for forward scroll)
match_table_rev = {unpack(match_table)}                                                                  -- Create a table that is reverse of the above table
                                                                                                         -- (used for backward scroll)
table.sort(match_table_rev, function(a, b) return a[1] > b[1] or ((a[1] == b[1]) and (a[2] > b[2])) end)

local match_row_min, match_col_min = match_table[1][1], match_table[1][2]                       -- Coordinates of the first match in the nvim buffer (for wrapping around the scroll when pressing 'N')

function goto_nxt_perl_match(match_table)                            -- Function to make the cursor go to the next regex match (useful for scrolling between matches)
   local curs_row, curs_col = unpack(vim.api.nvim_win_get_cursor(0))
   if (
      (match_row_max < curs_row) or 
      ((match_row_max == curs_row) and (match_col_max < curs_col))
   ) then                                                            -- If the cursor position is past the position of last match in the nvim buffer, go to the first match
      vim.api.nvim_win_set_cursor(
         0,                                                          -- nvim Buffer ID in which the matches are
         {match_row_min, match_col_min}                              -- Coordinates for the first match
      )
   else 
      for i, v in ipairs(match_table) do
         local match_row, match_col = v[1], v[2]                     -- Loop through each match's coordinates and stop at a point on the first match satisfying the if condition below to get the next and nearest match relative to the cursor position
         if (
            (match_row > curs_row) or                                -- If the cursor position is not past the position of the last match in the nvim buffer, go to the next match
            ((match_row == curs_row) and (match_col > curs_col))
         ) then
            vim.api.nvim_win_set_cursor(
               0, 
               {match_row, match_col}
            )
            break
         end
      end
   end
end

function goto_prev_perl_match(match_table)                           -- Function to make the cursor go to the next regex match (useful for scrolling between matches)
                                                                     -- This is a reverse of the goto_nxt_perl_match function logic defined above
   local curs_row, curs_col = unpack(vim.api.nvim_win_get_cursor(0))
   if (
      (match_row_min > curs_row) or 
      ((match_row_min == curs_row) and (match_col_min > curs_col))
   ) then
      vim.api.nvim_win_set_cursor(0, {match_row_max, match_col_max})
   else 
      for i, v in ipairs(match_table_rev) do
         match_row = v[1]
         match_col = v[2]
         if (
            (match_row < curs_row) or 
            ((match_row == curs_row) and (match_col < curs_col))
         ) then
            vim.api.nvim_win_set_cursor(0, {match_row, match_col})
            break
         end
      end
   end
end
