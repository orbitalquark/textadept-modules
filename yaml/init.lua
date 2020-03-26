-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The YAML module.
-- It provides utilities for editing YAML documents.
--
-- ## Key Bindings
--
-- + `Ctrl+&` (`⌘&` | `M-&`)
--   Jump to the anchor for the alias under the caret.
module('_M.yaml')]]

local _, lyaml = pcall(require, 'yaml.lyaml')
M.lyaml = lyaml

-- Always use spaces.
events.connect(events.LEXER_LOADED, function(lexer)
  if lexer ~= 'yaml' then return end
  buffer.use_tabs = false
  buffer.word_chars = table.concat{
    'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    '1234567890-*'
  }
end)

-- Commands.

-- Verify syntax.
events.connect(events.FILE_AFTER_SAVE, function()
  if buffer:get_lexer() ~= 'yaml' or not M.lyaml then return end
  buffer:annotation_clear_all()
  local ok, error = pcall(M.lyaml.load, buffer:get_text())
  if ok then return end
  local msg, line, col =
    error:match('^(.-) at document: %d+, line: (%d+), column: (%d+)')
  if not line or not col then line, col, msg = 1, 1, error end
  buffer.annotation_text[line] = msg
  buffer.annotation_style[line] = 9 -- error style number
  buffer:goto_pos(buffer:find_column(line, col))
end)

---
-- Jumps to the anchor for the alias underneath the caret.
-- @name goto_anchor
function M.goto_anchor()
  local s = buffer:word_start_position(buffer.current_pos, true)
  local e = buffer:word_end_position(buffer.current_pos)
  local anchor = buffer:text_range(s, e):match('^%*(.+)$')
  if anchor then
    buffer:target_whole_document()
    buffer.search_flags = buffer.FIND_WHOLEWORD
    if buffer:search_in_target('&' .. anchor) ~= -1 then
      buffer:goto_pos(buffer.target_start)
    end
  end
end

---
-- Container for YAML-specific key bindings.
-- @class table
-- @name _G.keys.yaml
keys.yaml = {
  [not OSX and not CURSES and 'c&' or 'm&'] = M.goto_anchor
}

-- Snippets.

---
-- Container for YAML-specific snippets.
-- @class table
-- @name _G.snippets.yaml
snippets.yaml = {}

return M
