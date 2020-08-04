-- Copyright 2019-2020 Mitchell mitchell.att.foicica.com.

--[[ This comment is for LuaDoc
---
-- [Experimental]
-- Extends Textadept's [`ui.command_entry`]() with a mode that can open files
-- relative to the current file or directory.
-- Tab-completion is available.
--
-- This is an alternative to Textadept's default File Open dialog.
--
-- This module is not loaded by default. `require('open_file_mode')` must be
-- called from *~/.textadept/init.lua*.
module('ui.command_entry.open_file')]]

-- Normalizes a Windows path by replacing '/' with '\\'.
-- Also transforms Cygwin-style '/c/' root directories into 'C:\'.
local function win32_normalize(path)
  return path:gsub('^/([%a])/', function(ch)
    return string.format('%s:\\', string.upper(ch))
  end):gsub('/', '\\')
end

---
-- Opens the command entry in a mode that can open files relative to the current
-- file or directory.
-- Tab-completion is available, and on Win32, Cygwin-style '/c/' root
-- directories are supported.
-- If no file is ultimately specified, the user is prompted with Textadept's
-- default File Open dialog.
-- @name _G.ui.command_entry.open_file
function ui.command_entry.open_file()
  ui.command_entry.run(function(file)
    if file ~= '' and not file:find('^%a?:?[/\\]') then
      -- Convert relative path into an absolute one.
      file = (buffer.filename or lfs.currentdir() .. '/'):match('^.+[/\\]') ..
        file
    end
    if WIN32 then file = win32_normalize(file) end
    io.open_file(file ~= '' and file or nil)
  end, {
    ['\t'] = function()
      if ui.command_entry:auto_c_active() then return end
      -- Autocomplete the filename in the command entry
      local files = {}
      local path = ui.command_entry:get_text()
      if not path:find('^%a?:?[/\\]') then
        -- Convert relative path into an absolute one.
        path = (buffer.filename or lfs.currentdir() .. '/'):match('^.+[/\\]') ..
          path
      end
      if WIN32 then path = win32_normalize(path) end
      local dir, part = path:match('^(.-)\\?([^/\\]*)$')
      if WIN32 and dir:find('^%a:$') then dir = dir .. '\\' end -- C: --> C:\
      if lfs.attributes(dir, 'mode') == 'directory' then
        -- Iterate over directory, finding file matches.
        local patt = '^' .. part:gsub('(%p)', '%%%1')
        for filename in lfs.walk(dir, nil, 0, true) do
          filename = filename:match('[^/\\]+[/\\]?$')
          if filename:find(patt) then files[#files + 1] = filename end
        end
        table.sort(files)
        local sep = ui.command_entry.auto_c_separator
        ui.command_entry.auto_c_separator = string.byte(';')
        ui.command_entry.auto_c_order = buffer.ORDER_PRESORTED
        ui.command_entry:auto_c_show(#part, table.concat(files, ';'))
        ui.command_entry.auto_c_separator = sep -- restore
      end
    end
  })
end

return ui.command_entry.open_file
