-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

--[[ This comment is for LuaDoc.
---
-- [Experimental]
-- Utilize Ctags with Textadept.
--
-- This module is not loaded by default. `require('ctags')` must be called from
-- *~/.textadept/init.lua*.
--
-- There are four ways to tell Textadept about *tags* files:
--
--   1. Place a *tags* file in current file's directory. This file will be used
--      in a tag search from any file in that directory.
--   2. Place a *tags* file in a project's root directory. This file will be
--      used in a tag search from any of that project's source files.
--   3. Add a *tags* file or list of *tags* files to the [`ctags`]() module for
--      a project root key. This file(s) will be used in a tag search from any
--      of that project's source files.
--      For example: `ctags['/path/to/project'] = '/path/to/tags'`.
--   4. Add a *tags* file to the [`ctags`]() module. This file will be used in
--      any tag search.
--      For example: `ctags[#ctags + 1] = '/path/to/tags'`.
--   5. As a last resort, if no *tags* files were found, or if there is no match
--      for a given symbol, a temporary *tags* file is generated for the current
--      file and used.
--
-- Textadept will use any and all *tags* files based on the above rules.
--
-- ## Key Bindings
--
-- Linux / Win32 | Mac OSX | Terminal | Command
-- --------------|---------|----------|--------
-- **Search**    |         |          |
-- F12           |F12      |F12       |Goto Ctag
-- Shift+F12     |⇧F12     |S-F12     |Goto Ctag...
--
-- @field _G.textadept.editing.autocompleters.ctag (function)
--   Autocompleter function for ctags. (Names only; not context-sensitive).
-- @field ctags (string)
--   Path to the ctags executable.
--   The default value is `'ctags'`.
-- @field generate_default_api (bool)
--   Whether or not to generate simple api documentation files based on *tags*
--   file contents. For example, functions are documented with their signatures
--   and source file paths.
--   This *api* file is generated in the same directory as *tags* and can be
--   read by [`textadept.editing.show_documentation`]() as long as it was added
--   to [`textadept.editing.api_files`]() for a given language.
--   The default value is `true`.
-- @field LUA_FLAGS (string)
--   A set of command-line options for ctags that better parses Lua code.
--   Combine this with other flags in [`ctags.ctags_flags`]() if Lua files will
--   be parsed.
-- @field LUA_GENERATOR (string)
--   Placeholder value that indicates Textadept's built-in Lua tags and api file
--   generator should be used instead of ctags. Requires LuaDoc to be installed.
module('ctags')]]

local M = {}

M.ctags = 'ctags'
M.generate_default_api = true

---
-- Map of project root paths to string command-line options, or functions that
-- return such strings, that are passed to ctags when generating project tags.
-- @class table
-- @name ctags_flags
-- @see LUA_FLAGS
M.ctags_flags = {}

---
-- Map of project root paths to string commands, or functions that return such
-- strings, that generate an *api* file that Textadept can read via
-- [`textadept.editing.show_documentation()`]().
-- The user is responsible for adding the generated api file to
-- `textadept.editing.api_files[lexer]` for each lexer language the file applies
-- to.
-- @class table
-- @name api_commands
-- @see textadept.editing.api_files
M.api_commands = {}

M.LUA_FLAGS = table.concat({
  '--langdef=luax',
  '--langmap=luax:.lua',
  [[--regex-luax="/^\s*function\s+[^[:space:]\.]*\.?([[:alnum:]_]+)\(/\1/f/"]],
  [[--regex-luax="/^\s*local\s+function\s+([[:alnum:]_]+)\(/\1/F/"]],
  [[--regex-luax="/^[^[:space:]\.]*\.?([[:alnum:]_]+)\s*=\s*[{]/\1/t/"]]
})

M.LUA_GENERATOR = 'LUA_GENERATOR'

-- Localizations.
local _L = _L
if _L['_Ctags']:find('^No Localization') then
  -- Dialogs.
  _L['Extra Information'] = 'Extra Information'
  _L['Goto Tag'] = 'Goto Tag'
  -- Menu.
  _L['_Ctags'] = '_Ctags'
  _L['_Goto Ctag'] = '_Goto Ctag'
  _L['G_oto Ctag...'] = 'G_oto Ctag...'
  _L['Jump _Back'] = 'Jump _Back'
  _L['Jump _Forward'] = 'Jump _Forward'
  _L['_Autocomplete Tag'] = '_Autocomplete Tag'
  _L['Generate _Project Tags and API'] = 'Generate _Project Tags and API'
end

-- Searches all available tags files tag *tag* and returns a table of tags
-- found.
-- All Ctags in tags files must be sorted.
-- @param tag Tag to find.
-- @return table of tags found with each entry being a table that contains the
--   4 ctags fields
local function find_tags(tag)
  -- TODO: binary search?
  local tags = {}
  local patt = '^('..tag..'%S*)\t([^\t]+)\t(.-);"\t?(.*)$'
  -- Determine the tag files to search in.
  local tag_files = {}
  local function add_tag_file(file)
    for i = 1, #tag_files do if tag_files[i] == file then return end end
    tag_files[#tag_files + 1] = file
  end
  local tag_file = ((buffer.filename or ''):match('^.+[/\\]') or
                    lfs.currentdir()..'/')..'tags' -- current directory's tags
  if lfs.attributes(tag_file) then add_tag_file(tag_file) end
  if buffer.filename then
    local root = io.get_project_root(buffer.filename)
    if root then
      tag_file = root..'/tags' -- project's tags
      if lfs.attributes(tag_file) then add_tag_file(tag_file) end
      tag_file = M[root] -- project's specified tags
      if type(tag_file) == 'string' then
        add_tag_file(tag_file)
      elseif type(tag_file) == 'table' then
        for i = 1, #tag_file do add_tag_file(tag_file[i]) end
      end
    end
  end
  for i = 1, #M do add_tag_file(M[i]) end -- global tags
  -- Search all tags files for matches.
  local tmpfile
  ::retry::
  for i = 1, #tag_files do
    local dir, found = tag_files[i]:match('^.+[/\\]'), false
    local f = io.open(tag_files[i])
    if not f then goto continue end
    for line in f:lines() do
      local tag, file, ex_cmd, ext_fields = line:match(patt)
      if tag then
        if not file:find('^%a?:?[/\\]') then file = dir..file end
        if ex_cmd:find('^/') then ex_cmd = ex_cmd:match('^/^?(.-)$?/$') end
        tags[#tags + 1] = {tag, file:gsub('\\\\', '\\'), ex_cmd, ext_fields}
        found = true
      elseif found then
        break -- tags are sorted, so no more matches exist in this file
      end
    end
    f:close()
    ::continue::
  end
  if #tags == 0 and buffer.filename and not tmpfile then
    -- If no matches were found, try the current file.
    tmpfile = os.tmpname()
    if WIN32 then tmpfile = os.getenv('TEMP')..tmpfile end
    local cmd = string.format('%s -o "%s" "%s"', M.ctags, tmpfile,
                              buffer.filename)
    os.spawn(cmd):wait()
    tag_files = {tmpfile}
    goto retry
  end
  if tmpfile then os.remove(tmpfile) end
  return tags
end

---
-- Jumps to the source of string *tag* or the source of the word under the
-- caret.
-- Prompts the user when multiple sources are found.
-- @param tag The tag to jump to the source of.
-- @name goto_tag
function M.goto_tag(tag)
  if not tag then
    local s = buffer:word_start_position(buffer.current_pos, true)
    local e = buffer:word_end_position(buffer.current_pos, true)
    tag = buffer:text_range(s, e)
  end
  -- Search for potential tags to jump to.
  local tags = find_tags(tag)
  if #tags == 0 then return end
  -- Prompt the user to select a tag from multiple candidates or automatically
  -- pick the only one.
  if #tags > 1 then
    local items = {}
    for i = 1, #tags do
      items[#items + 1] = tags[i][1]
      items[#items + 1] = tags[i][2]:match('[^/\\]+$') -- filename only
      items[#items + 1] = tags[i][3]:match('^%s*(.+)$') -- strip indentation
      items[#items + 1] = tags[i][4]:match('^%a?%s*(.*)$') -- ignore kind
    end
    local button, i = ui.dialogs.filteredlist{
      title = _L['Go To'],
      columns = {_L['Name'], _L['File'], _L['Line:'], _L['Extra Information']},
      items = items, search_column = 2, width = CURSES and ui.size[1] - 2 or nil
    }
    if button < 1 then return end
    tag = tags[i]
  else
    tag = tags[1]
  end
  -- Store the current position in the jump history, if applicable.
  require('history').append(buffer.filename,
                            buffer:line_from_position(buffer.current_pos),
                            buffer.column[buffer.current_pos])
  -- Jump to the tag.
  io.open_file(tag[2])
  if not tonumber(tag[3]) then
    for i = 0, buffer.line_count - 1 do
      if buffer:get_line(i):find(tag[3], 1, true) then
        textadept.editing.goto_line(i)
        break
      end
    end
  else
    textadept.editing.goto_line(tonumber(tag[3]) - 1)
  end
  -- Store the new position in the jump history.
  require('history').append(buffer.filename,
                            buffer:line_from_position(buffer.current_pos),
                            buffer.column[buffer.current_pos])
end

-- Autocompleter function for ctags.
-- Does not remove duplicates.
textadept.editing.autocompleters.ctag = function()
  local completions = {}
  local s = buffer:word_start_position(buffer.current_pos, true)
  local e = buffer:word_end_position(buffer.current_pos, true)
  local tags = find_tags(buffer:text_range(s, e))
  for i = 1, #tags do completions[#completions + 1] = tags[i][1] end
  return e - s, completions
end

-- Add menu entries and configure key bindings.
local m_search = textadept.menu.menubar[_L['_Search']]
local SEPARATOR = {''}
m_search[#m_search + 1] = SEPARATOR
m_search[#m_search + 1] = {
  title = _L['_Ctags'],
  {_L['_Goto Ctag'], M.goto_tag},
  {_L['G_oto Ctag...'], function()
    local button, name = ui.dialogs.standard_inputbox{title = _L['Goto Tag']}
    if button == 1 then _M.ctags.goto_tag(name) end
  end},
  SEPARATOR,
  {_L['_Autocomplete Tag'], function()
    textadept.editing.autocomplete('ctag')
  end},
  SEPARATOR,
  {_L['Generate _Project Tags and API'], function()
    local root_directory = io.get_project_root()
    if not root_directory then return end
    local ctags_flags = M.ctags_flags[root_directory]
    if type(ctags_flags) == 'function' then ctags_flags = ctags_flags() end
    local api_command = M.api_commands[root_directory]
    if type(api_command) == 'function' then api_command = api_command() end
    if ctags_flags == M.LUA_GENERATOR or api_command == M.LUA_GENERATOR then
      os.spawn('luadoc -d . --doclet tadoc .', root_directory,
               {'LUA_PATH='.._HOME..'/modules/lua/?.lua;;'}):wait()
    end
    if ctags_flags ~= M.LUA_GENERATOR then
      os.spawn(string.format('"%s" %s', M.ctags, ctags_flags or '-R'),
               root_directory):wait()
    end
    if api_command then
      if api_command ~= M.LUA_GENERATOR then
        os.spawn(api_command, root_directory):wait()
      end
    elseif M.generate_default_api then
      -- Generate from ctags file.
      local f = assert(io.open(root_directory..'/api', 'wb'))
      for line in io.lines(root_directory..'/tags') do
        local patt = '^(%S*)\t([^\t]+)\t(.-);"\t?(.*)$'
        local tag, file, ex_cmd = line:match(patt)
        if tag then
          ex_cmd = ex_cmd:match('^/^?(.-)$?/$')
          if ex_cmd and tag:find('^[%w_]+$') then
            f:write(tag, ' ', ex_cmd, '\\n', file, '\n')
          end
        end
      end
      f:close()
    end
  end}
}
keys.f12 = M.goto_tag
keys.sf12 = m_search[_L['_Ctags']][_L['G_oto Ctag...']][2]

return M