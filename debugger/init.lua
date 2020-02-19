-- Copyright 2007-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- [Experimental]
-- Language debugging support.
--
-- All this module does is emit debugger events. Submodules that implement
-- debuggers listen for these events and act on them.
--
-- This module is not loaded by default. `require('debugger')` must be called
-- from *~/.textadept/init.lua*.
--
-- ## Key Bindings
--
-- Linux / Win32 | Mac OSX | Terminal | Command
-- --------------|---------|----------|--------
-- **Debug**     |         |          |
-- F5            |F5       |F5        |Start debugging
-- F10           |F10      |F10       |Step over
-- F11           |F11      |F11       |Step into
-- Shift+F11     |⇧F11     |S-F11     |Step out
-- Shift+F5      |⇧F5      |S-F5      |Stop debugging
-- Alt+=         |⌘=       |M-=       |Inspect variable
-- Alt++         |⌘+       |M-+       |Evaluate expression...
--
-- @field _G.events.DEBUGGER_BREAKPOINT_ADDED (string)
--   Emitted when a breakpoint is added.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint). Breakpoints added while the debugger is not running are queued
--   up until the debugger starts.
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language to add a breakpoint for.
--   * _`filename`_: The filename to add a breakpoint in.
--   * _`line`_: The 1-based line number to break on.
-- @field _G.events.DEBUGGER_BREAKPOINT_REMOVED (string)
--   Emitted when a breakpoint is removed.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`filename`_: The filename to remove a breakpoint from.
--   * _`line`_: The 1-based line number to stop breaking on.
-- @field _G.events.DEBUGGER_WATCH_ADDED (string)
--   Emitted when a watch is added.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint). Watches added while the debugger is not running are queued up
--   until the debugger starts.
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language to add a watch for.
--   * _`expr`_: The expression or variable to watch, depending on what the
--     debugger supports.
--   * _`id`_: The expression's ID number.
-- @field _G.events.DEBUGGER_WATCH_REMOVED (string)
--   Emitted when a breakpoint is removed.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`expr`_: The expression to stop watching.
--   * _`id`_: The expression's ID number.
-- @field _G.events.DEBUGGER_START (string)
--   Emitted when a debugger should be started.
--   The debugger should not start executing yet, as there will likely be
--   incoming breakpoint and watch add events. Subsequent events will instruct
--   the debugger to begin executing.
--   If a listener creates a debugger, it *must* return `true`. Otherwise, it is
--   assumed that no debugger was created and subsequent debugger functions will
--   not work. Listeners *must not* return `false` (they can return `nil`).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language to start debugging.
--   * _`...`_: Any arguments passed to [`debugger.start()`]().
-- @field _G.events.DEBUGGER_CONTINUE (string)
--   Emitted when a execution should be continued.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`...`_: Any arguments passed to [`debugger.continue()`]().
-- @field _G.events.DEBUGGER_STEP_INTO (string)
--   Emitted when execution should continue by one line, stepping into
--   functions.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`...`_: Any arguments passed to [`debugger.step_into()`]().
-- @field _G.events.DEBUGGER_STEP_OVER (string)
--   Emitted when execution should continue by one line, stepping over
--   functions.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`...`_: Any arguments passed to [`debugger.step_over()`]().
-- @field _G.events.DEBUGGER_STEP_OUT (string)
--   Emitted when execution should continue, stepping out of the current
--   function.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`...`_: Any arguments passed to [`debugger.step_out()`]().
-- @field _G.events.DEBUGGER_PAUSE (string)
--   Emitted when execution should be paused.
--   This is only emitted when the debugger is running and executing (e.g. not
--   at a breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`...`_: Any arguments passed to [`debugger.pause()`]().
-- @field _G.events.DEBUGGER_RESTART (string)
--   Emitted when execution should restart from the beginning.
--   This is only emitted when the debugger is running.
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`...`_: Any arguments passed to [`debugger.restart()`]().
-- @field _G.events.DEBUGGER_STOP (string)
--   Emitted when a debugger should be stopped.
--   This is only emitted when the debugger is running.
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language to stop debugging.
--   * _`...`_: Any arguments passed to [`debugger.stop()`]().
-- @field _G.events.DEBUGGER_SET_FRAME (string)
--   Emitted when a stack frame should be switched to.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`level`_: The 1-based stack level number to switch to. This value
--     depends on the stack levels given to [`debugger.update_state()`]().
-- @field _G.events.DEBUGGER_INSPECT (string)
--   Emitted when a symbol should be inspected.
--   Debuggers typically show a symbol's value in a calltip via
--   [`buffer:call_tip_show()`]().
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`position`_: The buffer position of the symbol to inspect. The debugger
--     responsible for identifying the symbol's name, as symbol characters vary
--     from language to language.
-- @field _G.events.DEBUGGER_COMMAND (string)
--   Emitted when a debugger command should be run.
--   This is only emitted when the debugger is running and paused (e.g. at a
--   breakpoint).
--   Arguments:
--
--   * _`lexer`_: The lexer name of the language being debugged.
--   * _`text`_: The text of the command to run.
-- @field MARK_BREAKPOINT_COLOR (number)
--   The color of breakpoint markers.
-- @field MARK_DEBUGLINE_COLOR (number)
--   The color of the current debug line marker.
module('debugger')]]

local events = events
events.DEBUGGER_BREAKPOINT_ADDED = 'breakpoint_added'
events.DEBUGGER_BREAKPOINT_REMOVED = 'breakpoint_removed'
events.DEBUGGER_WATCH_ADDED = 'watch_added'
events.DEBUGGER_WATCH_REMOVED = 'watch_removed'
events.DEBUGGER_START = 'debug_start'
events.DEBUGGER_CONTINUE = 'debug_continue'
events.DEBUGGER_STEP_INTO = 'debug_step_into'
events.DEBUGGER_STEP_OVER = 'debug_step_over'
events.DEBUGGER_STEP_OUT = 'debug_step_out'
events.DEBUGGER_PAUSE = 'debug_pause'
events.DEBUGGER_RESTART = 'debug_restart'
events.DEBUGGER_STOP = 'debug_stop'
events.DEBUGGER_SET_FRAME = 'debug_set_frame'
events.DEBUGGER_INSPECT = 'debug_inspect'
events.DEBUGGER_COMMAND = 'debug_command'

M.MARK_BREAKPOINT_COLOR = 0x6D6DD9
--M.MARK_BREAKPOINT_ALPHA = 128
M.MARK_DEBUGLINE_COLOR = 0x6DD96D
--M.MARK_DEBUGLINE_ALPHA = 128

-- Localizations.
local _L = _L
if _L['Remove Breakpoint']:find('^No Localization') then
  -- Debugger messages.
  _L['Debugging'] = 'Debugging'
  _L['paused'] = 'paused'
  _L['executing'] = 'executing'
  _L['Cannot Set Breakpoint'] = 'Cannot Set Breakpoint'
  _L['Debugger is executing'] = 'Debugger is executing'
  _L['Please wait until debugger is stopped or paused'] = 'Please wait until debugger is stopped or paused'
  _L['Cannot Remove Breakpoint'] = 'Cannot Remove Breakpoint'
  _L['Remove Breakpoint'] = 'Remove Breakpoint'
  _L['Breakpoint:'] = 'Breakpoint:'
  _L['Cannot Set Watch'] = 'Cannot Set Watch'
  _L['Set Watch'] = 'Set Watch'
  _L['Expression:'] = 'Expression:'
  _L['Cannot Remove Watch'] = 'Cannot Remove Watch'
  _L['Remove Watch'] = 'Remove Watch'
  _L['Error Starting Debugger'] = 'Error Starting Debugger'
  _L['Debugger started'] = 'Debugger started'
  _L['Debugger stopped'] = 'Debugger stopped'
  _L['Variables'] = 'Variables'
  _L['Name'] = 'Name'
  _L['Value'] = 'Value'
  _L['Call Stack'] = 'Call Stack'
  _L['_OK'] = '_OK'
  _L['_Set Frame'] = '_Set Frame'
  -- Menu.
  _L['_Debug'] = '_Debug'
  _L['Go/_Continue'] = 'Go/_Continue'
  _L['Step _Over'] = 'Step _Over'
  _L['Step _Into'] = 'Step _Into'
  _L['Step Ou_t'] = 'Step Ou_t'
  _L['Pause/_Break'] = 'Pause/_Break'
  _L['_Restart'] = '_Restart'
  _L['_Stop'] = 'Sto_p'
  _L['I_nspect'] = 'I_nspect'
  _L['_Variables...'] = '_Variables...'
  _L['Call Stac_k...'] = 'Call Stac_k...'
  _L['_Evaluate...'] = '_Evaluate...'
  _L['_Toggle Breakpoint'] = 'Toggle _Breakpoint'
  _L['Remo_ve Breakpoint...'] = 'Remo_ve Breakpoint...'
  _L['Set _Watch Expression'] = 'Set _Watch Expression'
  _L['Remove Watch E_xpression...'] = 'Remove Watch E_xpression...'
end

local MARK_BREAKPOINT = _SCINTILLA.next_marker_number()
local MARK_DEBUGLINE = _SCINTILLA.next_marker_number()

-- Map of lexers to breakpoints.
-- @class table
-- @name breakpoints
local breakpoints = {}

-- Map of lexers to watches.
-- @class table
-- @name watches
local watches = {}

-- Map of lexers to debug states.
-- @class table
-- @name states
local states = {}

-- Notifies via the statusbar that debugging is happening.
local function update_statusbar()
  local lexer = buffer:get_lexer()
  local status = states[lexer] and
                 _L[states[lexer].executing and 'executing' or 'paused'] or '?'
  ui.statusbar_text = string.format('%s (%s)', _L['Debugging'], status)
end

-- Sets a breakpoint in file *file* on line number *line*.
-- Emits a `DEBUGGER_BREAKPOINT_ADDED` event if the debugger is running, or
-- queues up the event to run in [`debugger.start()`]().
-- If the debugger is executing (e.g. not at a breakpoint), assumes a breakpoint
-- cannot be set and shows an error message.
-- @param file Filename to set the breakpoint in.
-- @param line The 1-based line number to break on.
local function set_breakpoint(file, line)
  local lexer = buffer:get_lexer()
  if states[lexer] and states[lexer].executing then
    ui.dialogs.ok_msgbox{
      title = _L['Cannot Set Breakpoint'], text = _L['Debugger is executing'],
      informative_text = _L['Please wait until debugger is stopped or paused'],
      icon = 'gtk-dialog-error', no_cancel = true
    }
    return
  end
  if not breakpoints[lexer] then breakpoints[lexer] = {} end
  if not breakpoints[lexer][file] then breakpoints[lexer][file] = {} end
  breakpoints[lexer][file][line] = true
  if file == buffer.filename then
    buffer:marker_add(line - 1, MARK_BREAKPOINT)
  end
  if not states[lexer] then return end -- not debugging
  events.emit(events.DEBUGGER_BREAKPOINT_ADDED, lexer, file, line)
end

---
-- Removes a breakpoint from line number *line* in file *file*, or prompts the
-- user for a breakpoint(s) to remove.
-- Emits a `DEBUGGER_BREAKPOINT_REMOVED` event if the debugger is running.
-- If the debugger is executing (e.g. not at a breakpoint), assumes a breakpoint
-- cannot be removed and shows an error message.
-- @param file Optional filename of the breakpoint to remove.
-- @param line Optional 1-based line number of the breakpoint to remove.
-- @name remove_breakpoint
function M.remove_breakpoint(file, line)
  local lexer = buffer:get_lexer()
  if states[lexer] and states[lexer].executing then
    ui.dialogs.ok_msgbox{
      title = _L['Cannot Remove Breakpoint'],
      text = _L['Debugger is executing'],
      informative_text = _L['Please wait until debugger is stopped or paused'],
      icon = 'gtk-dialog-error', no_cancel = true
    }
    return
  end
  if (not file or not line) and breakpoints[lexer] then
    local items = {}
    for filename, file_breakpoints in pairs(breakpoints[lexer]) do
      if not file or file == filename then
        for line in pairs(file_breakpoints) do
          items[#items + 1] = filename..':'..line
        end
      end
    end
    table.sort(items)
    local button, breakpoints = ui.dialogs.filteredlist{
      title = _L['Remove Breakpoint'], columns = _L['Breakpoint:'],
      items = items, string_output = true, select_multiple = true
    }
    if button ~= _L['_OK'] or not breakpoints then return end
    for i = 1, #breakpoints do
      file, line = breakpoints[i]:match('^(.+):(%d+)$')
      M.remove_breakpoint(file, tonumber(line))
    end
    return
  end
  if breakpoints[lexer] and breakpoints[lexer][file] then
    breakpoints[lexer][file][line] = nil
    if file == buffer.filename then
      buffer:marker_delete(line - 1, MARK_BREAKPOINT)
    end
    if not states[lexer] then return end -- not debugging
    events.emit(events.DEBUGGER_BREAKPOINT_REMOVED, lexer, file, line)
  end
end

---
-- Toggles a breakpoint on line number *line* in file *file*, or the current
-- line in the current file.
-- May emit `DEBUGGER_BREAKPOINT_ADDED` and `DEBUGGER_BREAKPOINT_REMOVED` events
-- depending on circumstance.
-- May show an error message if the debugger is executing (e.g. not at a
-- breakpoint).
-- @param file Optional filename of the breakpoint to toggle.
-- @param line Optional 1-based line number of the breakpoint to toggle.
-- @see remove_breakpoint
-- @name toggle_breakpoint
function M.toggle_breakpoint(file, line)
  local lexer = buffer:get_lexer()
  if not file then file = buffer.filename end
  if not file then return end -- nothing to do
  if not line then line = buffer:line_from_position(buffer.current_pos) + 1 end
  if not breakpoints[lexer] or not breakpoints[lexer][file] or
     not breakpoints[lexer][file][line] then
    set_breakpoint(file, line)
  else
    M.remove_breakpoint(file, line)
  end
end

---
-- Watches string expression *expr* for changes and breaks on each change.
-- Emits a `DEBUGGER_WATCH_ADDED` event if the debugger is running, or queues up
-- the event to run in [`debugger.start()`]().
-- If the debugger is executing (e.g. not at a breakpoint), assumes a watch
-- cannot be set and shows an error message.
-- @param expr String expression to watch.
-- @name set_watch
function M.set_watch(expr)
  local lexer = buffer:get_lexer()
  if states[lexer] and states[lexer].executing then
    ui.dialogs.ok_msgbox{
      title = _L['Cannot Set Watch'], text = _L['Debugger is executing'],
      informative_text = _L['Please wait until debugger is stopped or paused'],
      icon = 'gtk-dialog-error', no_cancel = true
    }
    return
  end
  if not expr then
    local button
    button, expr = ui.dialogs.standard_inputbox{
      title = _L['Set Watch'], text = _L['Expression:']
    }
    if button ~= 1 or expr == '' then return end
  end
  if not watches[lexer] then watches[lexer] = {n = 0} end
  local watch_exprs = watches[lexer]
  watch_exprs.n = watch_exprs.n + 1
  watch_exprs[watch_exprs.n], watch_exprs[expr] = expr, watch_exprs.n
  if not states[lexer] then return end -- not debugging
  events.emit(events.DEBUGGER_WATCH_ADDED, lexer, expr, watch_exprs.n)
end

---
-- Stops watching the expression identified by *id*, or the expression selected
-- by the user.
-- Emits a `DEBUGGER_WATCH_REMOVED` event if the debugger is running.
-- If the debugger is executing (e.g. not at a breakpoint), assumes a watch
-- cannot be set and shows an error message.
-- @param id ID number of the expression, as given in the `DEBUGGER_WATCH_ADDED`
--   event.
-- @name remove_watch
function M.remove_watch(id)
  local lexer = buffer:get_lexer()
  if states[lexer] and states[lexer].executing then
    ui.dialogs.ok_msgbox{
      title = _L['Cannot Set Watch'], text = _L['Debugger is executing'],
      informative_text = _L['Please wait until debugger is stopped or paused'],
      icon = 'gtk-dialog-error', no_cancel = true
    }
    return
  end
  if not id and watches[lexer] then
    local items = {}
    for i = 1, watches[lexer].n do
      local watch = watches[lexer][i]
      if watch then items[#items + 1] = watch end
    end
    local button, expr = ui.dialogs.filteredlist{
      title = _L['Remove Watch'], columns = _L['Expression:'], items = items,
      string_output = true
    }
    if button ~= _L['_OK'] or not expr then return end
    id = watches[lexer][expr] -- TODO: handle duplicates
  end
  local watch_exprs = watches[lexer]
  if watch_exprs and watch_exprs[id] then
    local expr = watch_exprs[id]
    watch_exprs[id], watch_exprs[expr] = nil, nil
    -- TODO: handle duplicate exprs
    if not states[lexer] then return end -- not debugging
    events.emit(events.DEBUGGER_WATCH_REMOVED, lexer, expr, id)
  end
end

---
-- Starts a debugger and adds any queued breakpoints and watches.
-- Emits a `DEBUGGER_START` event, passing along any arguments given. If a
-- debugger cannot be started, the event handler should throw an error.
-- This only starts a debugger. [`debugger.continue()`](),
-- [`debugger.step_into()`](), or [`debugger.step_over()`]() should be called
-- next to begin debugging.
-- @param lexer Optional lexer name of the language to start debugging. The
--   default value is the current lexer.
-- @return whether or not a debugger was started
-- @name start
function M.start(lexer, ...)
  if not lexer then lexer = buffer:get_lexer() end
  if states[lexer] then return end -- already debugging
  local ok, errmsg = pcall(events.emit, events.DEBUGGER_START, lexer, ...)
  if not ok then
    ui.dialogs.msgbox{
      title = _L['Error Starting Debugger'], text = errmsg,
      icon = 'gtk-dialog-error', no_cancel = true
    }
    return
  elseif ok and not errmsg then
    return false -- no debugger for this language
  end
  states[lexer] = {} -- initial value
  if not breakpoints[lexer] then breakpoints[lexer] = {} end
  for file, file_breakpoints in pairs(breakpoints[lexer]) do
    for line in pairs(file_breakpoints) do
      events.emit(events.DEBUGGER_BREAKPOINT_ADDED, lexer, file, line)
    end
  end
  if not watches[lexer] then watches[lexer] = {n = 0} end
  for i = 1, watches[lexer].n do
    local watch = watches[lexer][i]
    if watch then events.emit(events.DEBUGGER_WATCH_ADDED, lexer, watch, i) end
  end
  ui.statusbar_text = _L['Debugger started']
  events.disconnect(events.UPDATE_UI, update_statusbar) -- just in case
  events.connect(events.UPDATE_UI, update_statusbar)
  return true
end

---
-- Continue debugger execution unless the debugger is already executing (e.g.
-- not at a breakpoint).
-- If no debugger is running, starts one, then continues execution.
-- Emits a `DEBUGGER_CONTINUE` event, passing along any arguments given.
-- @param lexer Optional lexer name of the language to continue executing. The
--   default value is the current lexer.
-- @name continue
function M.continue(lexer, ...)
  if not lexer then lexer = buffer:get_lexer() end
  if states[lexer] and states[lexer].executing then return end
  if not states[lexer] and not M.start(lexer) then return end
  buffer:marker_delete_all(MARK_DEBUGLINE)
  states[lexer].executing = true
  events.emit(events.DEBUGGER_CONTINUE, lexer, ...)
end

---
-- Continue debugger execution by one line, stepping into functions, unless the
-- debugger is already executing (e.g. not at a breakpoint).
-- If no debugger is running, starts one, then steps.
-- Emits a `DEBUGGER_STEP_INTO` event, passing along any arguments given.
-- @name step_into
function M.step_into(...)
  local lexer = buffer:get_lexer()
  if states[lexer] and states[lexer].executing then return end
  if not states[lexer] and not M.start(lexer) then return end
  buffer:marker_delete_all(MARK_DEBUGLINE)
  states[lexer].executing = true
  events.emit(events.DEBUGGER_STEP_INTO, lexer, ...)
end

---
-- Continue debugger execution by one line, stepping over functions, unless the
-- debugger is already executing (e.g. not at a breakpoint).
-- If no debugger is running, starts one, then steps.
-- Emits a `DEBUGGER_STEP_OVER` event, passing along any arguments given.
-- @name step_over
function M.step_over(...)
  local lexer = buffer:get_lexer()
  if states[lexer] and states[lexer].executing then return end
  if not states[lexer] and not M.start(lexer) then return end
  buffer:marker_delete_all(MARK_DEBUGLINE)
  states[lexer].executing = true
  events.emit(events.DEBUGGER_STEP_OVER, lexer, ...)
end

---
-- Continue debugger execution, stepping out of the current function, unless the
-- debugger is already executing (e.g. not at a breakpoint).
-- Emits a `DEBUGGER_STEP_OUT` event, passing along any additional arguments
-- given.
-- @name step_out
function M.step_out(...)
  local lexer = buffer:get_lexer()
  if not states[lexer] or states[lexer].executing then return end
  buffer:marker_delete_all(MARK_DEBUGLINE)
  states[lexer].executing = true
  events.emit(events.DEBUGGER_STEP_OUT, lexer, ...)
end

---
-- Pause debugger execution unless the debugger is already paused (e.g. at a
-- breakpoint).
-- Emits a `DEBUGGER_PAUSE` event, passing along any additional arguments given.
-- @name pause
function M.pause(...)
  local lexer = buffer:get_lexer()
  if not states[lexer] or not states[lexer].executing then return end
  events.emit(events.DEBUGGER_PAUSE, lexer, ...)
end

---
-- Restarts debugger execution from the beginning.
-- Emits a `DEBUGGER_PAUSE` event, passing along any additional arguments given.
-- @name restart
function M.restart(...)
  local lexer = buffer:get_lexer()
  if not states[lexer] then return end -- not debugging
  events.emit(events.DEBUGGER_RESTART, lexer, ...)
end

---
-- Stops debugging.
-- Debuggers should call this function when finished.
-- Emits a `DEBUGGER_STOP` event, passing along any arguments given.
-- @param lexer Optional lexer name of the language to stop debugging. The
--   default value is the current lexer.
-- @name stop
function M.stop(lexer, ...)
  if not lexer then lexer = buffer:get_lexer() end
  if not states[lexer] then return end -- not debugging
  events.emit(events.DEBUGGER_STOP, lexer, ...)
  buffer:marker_delete_all(MARK_DEBUGLINE)
  states[lexer] = nil
  events.disconnect(events.UPDATE_UI, update_statusbar)
  ui.statusbar_text = _L['Debugger stopped']
end

---
-- Updates the running debugger's state and marks the current debug line.
-- Debuggers need to call this function every time their state changes,
-- typically during `DEBUGGER_*` events.
-- @param state A table with four fields: `file`, `line`, `call_stack`, and
--   `variables`. `file` and `line` indicate the debugger's current position.
--   `call_stack` is a list of stack frames and a `pos` field whose value is the
--   1-based index of the current frame. `variables` is an optional map of known
--   variables to their values. The debugger can choose what kind of variables
--   make sense to put in the map.
-- @name update_state
function M.update_state(state)
  assert(type(state) == 'table', 'state must be a table')
  assert(state.file and state.line and state.call_stack,
         'state must have file, line, and call_stack fields')
  assert(type(state.call_stack) == 'table' and
         type(state.call_stack.pos) == 'number',
         'state.call_stack must be a table with a numeric pos field')
  if not state.variables then state.variables = {} end
  local file = state.file:iconv('UTF-8', _CHARSET)
  if state.file ~= buffer.filename then ui.goto_file(file) end
  states[buffer:get_lexer()] = state
  buffer:marker_delete_all(MARK_DEBUGLINE)
  buffer:marker_add(state.line - 1, MARK_DEBUGLINE)
  buffer:goto_line(state.line - 1)
end

---
-- Displays a dialog with variables in the current stack frame.
-- @name variables
function M.variables()
  local lexer = buffer:get_lexer()
  if not states[lexer] or states[lexer].executing then return end
  local names = {}
  for k in pairs(states[lexer].variables) do names[#names + 1] = k end
  table.sort(names)
  local variables = {}
  for i = 1, #names do
    local name = names[i]
    variables[#variables + 1] = name
    variables[#variables + 1] = states[lexer].variables[name]
  end
  ui.dialogs.filteredlist{
    title = _L['Variables'], columns = {_L['Name'], _L['Value']},
    items = variables
  }
end

---
-- Prompts the user to select a stack frame to switch to from the current
-- debugger call stack, unless the debugger is executing (e.g. not at a
-- breakpoint).
-- Emits a `DEBUGGER_SET_FRAME` event.
-- @name set_frame
function M.set_frame()
  local lexer = buffer:get_lexer()
  if not states[lexer] or states[lexer].executing then return end
  local call_stack = states[lexer].call_stack
  local button, level = ui.dialogs.dropdown{
    title = _L['Call Stack'], items = call_stack,
    select = call_stack.pos or 1, button1 = _L['_OK'],
    button2 = _L['_Set Frame']
  }
  if button ~= 2 then return end
  events.emit(events.DEBUGGER_SET_FRAME, lexer, tonumber(level))
end

---
-- Inspects the symbol (if any) at buffer position *position*, unless the
-- debugger is executing (e.g. not at a breakpoint).
-- Emits a `DEBUGGER_INSPECT` event.
-- @param position The buffer position to inspect.
-- @name inspect
function M.inspect(position)
  local lexer = buffer:get_lexer()
  if not states[lexer] or states[lexer].executing then return end
  events.emit(events.DEBUGGER_INSPECT, lexer, position or buffer.current_pos)
end

-- Sets view properties for debug markers.
local function set_marker_properties()
  buffer.mouse_dwell_time = 500
  buffer:marker_define(MARK_BREAKPOINT, buffer.MARK_FULLRECT)
  buffer:marker_define(MARK_DEBUGLINE, buffer.MARK_FULLRECT)
  buffer.marker_back[MARK_BREAKPOINT] = M.MARK_BREAKPOINT_COLOR
  --buffer.marker_alpha[MARK_BREAKPOINT] = M.MARK_BREAKPOINT_ALPHA
  buffer.marker_back[MARK_DEBUGLINE] = M.MARK_DEBUGLINE_COLOR
  --buffer.marker_alpha[MARK_DEBUGLINE] = M.MARK_DEBUGLINE_ALPHA
end
events.connect(events.VIEW_NEW, set_marker_properties)

-- Set breakpoint on margin-click.
events.connect(events.MARGIN_CLICK, function(margin, position, modifiers)
  if margin == 1 and modifiers == 0 then
    M.toggle_breakpoint(nil, nil, buffer:line_from_position(position) + 1)
  end
end)

-- Update breakpoints after switching buffers.
events.connect(events.BUFFER_AFTER_SWITCH, function()
  local lexer, file = buffer:get_lexer(), buffer.filename
  if not breakpoints[lexer] or not breakpoints[lexer][file] then return end
  buffer:marker_delete_all(MARK_BREAKPOINT)
  for line in pairs(breakpoints[lexer][file]) do
    buffer:marker_add(line - 1, MARK_BREAKPOINT)
  end
end)

-- Inspect symbols and show call tips during mouse dwell events.
events.connect(events.DWELL_START, function(pos) M.inspect(pos) end)
events.connect(events.DWELL_END, buffer.call_tip_cancel)

-- Add menu entries and configure key bindings.
-- (Insert 'Debug' menu after 'Tools'.)
local menubar = textadept.menu.menubar
for i = 1, #menubar do
  if menubar[i].title == _L['_Tools'] then
    table.insert(menubar, i + 1, {
      title = _L['_Debug'],
      {_L['Go/_Continue'], M.continue},
      {_L['Step _Over'], M.step_over},
      {_L['Step _Into'], M.step_into},
      {_L['Step Ou_t'], M.step_out},
      {_L['Pause/_Break'], M.pause},
      {_L['_Restart'], M.restart},
      {_L['_Stop'], M.stop},
      {''},
      {_L['I_nspect'], M.inspect},
      {_L['_Variables...'], M.variables},
      {_L['Call Stac_k...'], M.set_frame},
      {_L['_Evaluate...'], function()
        -- TODO: command entry loses focus when run from select command
        -- dialog. This works fine when run from menu directly.
        local lexer = buffer:get_lexer()
        if not states[lexer] or states[lexer].executing then return end
        ui.command_entry.run(function(text)
          events.emit(events.DEBUGGER_COMMAND, buffer:get_lexer(), text)
        end, 'lua')
      end},
      {''},
      {_L['_Toggle Breakpoint'], M.toggle_breakpoint},
      {_L['Remo_ve Breakpoint...'], M.remove_breakpoint},
      {_L['Set _Watch Expression'], M.set_watch},
      {_L['Remove Watch E_xpression...'], M.remove_watch},
    })
    break
  end
end
keys.f5 = M.continue
keys.f10 = M.step_over
keys.f11 = M.step_into
keys.sf11 = M.step_out
keys.sf5 = M.stop
keys[not OSX and not CURSES and 'a=' or 'm='] = M.inspect
local m_debug = textadept.menu.menubar[_L['_Debug']]
keys[not OSX and not CURSES and 'a+' or 'm+'] = m_debug[_L['_Evaluate...']][2]
keys.f9 = M.toggle_breakpoint

-- Automatically load a language debugger when a file of that language is
-- opened.
events.connect(events.LEXER_LOADED, function(lexer)
  if package.searchpath('debugger.'..lexer, package.path) then
    require('debugger.'..lexer)
  end
end)

return M
