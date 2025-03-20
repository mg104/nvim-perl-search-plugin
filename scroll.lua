local M = {}

local function M.find_first_last_matches(vim.g.match_table)
   local match_row_min, match_col_min = match_table[1][1], match_table[1][2]  -- Coordinates of the first match in the nvim buffer (for wrapping around the scroll when pressing 'N')
   local match_row_max, match_col_max = match_table[#match_table][1], match_table[#match_table][2]  -- Coordinates of the last match in the nvim buffer (for wrapping around the 
                                                                           -- scroll when pressing 'n')
   return match_row_min, match_col_min, match_row_max, match_col_max
end 
                                                                                                 
local function M.goto_nxt_perl_match(vim.g.match_table)                    -- Function to make the cursor go to the next regex match (useful for scrolling between matches)
   local match_row_min, match_col_min, match_row_max, match_col_max = M.find_first_last_matches(vim.g.match_table)
   local curs_row, curs_col = unpack(vim.api.nvim_win_get_cursor(0))
   if (
      (match_row_max < curs_row) or 
      ((match_row_max == curs_row) and (match_col_max < curs_col))
   ) then                                                                  -- If the cursor position is past the position of last match in the nvim buffer, go to the first match
      vim.api.nvim_win_set_cursor(
         0,                                                                -- nvim Buffer ID in which the matches are
         {match_row_min, match_col_min}                                    -- Coordinates for the first match
      )
   else 
      for i, v in ipairs(match_table) do
                  local match_row, match_col = v[1], v[2]                  -- Loop through each match's coordinates and stop at a point on the first match satisfying the 
                                                                           -- if condition below to get the next and nearest match relative to the cursor position
         if (
            (match_row > curs_row) or                                      -- If the cursor position is not past the position of the last match in the nvim buffer, go to the next match
            ((match_row == curs_row) and (match_col > curs_col))
         ) then
            vim.api.nvim_win_set_cursor(
               0, 
               {match_row, match_col}
            )
            break                                                          -- Exit the loop after finding the first match that is just after the current cursor position
         end
      end
   end
end

local function M.goto_prev_perl_match(vim.g.match_table)                   -- Function to make the cursor go to the next regex match (useful for scrolling between matches)
   local match_row_min, match_col_min, match_row_max, match_col_max = M.find_first_last_matches(vim.g.match_table)
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

return M
