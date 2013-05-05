--------------------------------------------------------------------------
-- Lmod License
--------------------------------------------------------------------------
--
--  Lmod is licensed under the terms of the MIT license reproduced below.
--  This means that Lua is free software and can be used for both academic
--  and commercial purposes at absolutely no cost.
--
--  ----------------------------------------------------------------------
--
--  Copyright (C) 2008-2013 Robert McLay
--
--  Permission is hereby granted, free of charge, to any person obtaining
--  a copy of this software and associated documentation files (the
--  "Software"), to deal in the Software without restriction, including
--  without limitation the rights to use, copy, modify, merge, publish,
--  distribute, sublicense, and/or sell copies of the Software, and to
--  permit persons to whom the Software is furnished to do so, subject
--  to the following conditions:
--
--  The above copyright notice and this permission notice shall be 
--  included in all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
--  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
--  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
--  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
--  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
--  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
--  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.
--
--------------------------------------------------------------------------


require("strict")

Dbg               = require("Dbg")
MC_Access         = inheritsFrom(MasterControl)
MC_Access.my_name = "MC_Access"
concatTbl         = table.concat

local M           = MC_Access

M.accessT = { help = false, whatis = false}

function M.activate(name, value)
   M.accessT[name] = value
end

function M.help(self, ...)   
   local arg = { n = select('#', ...), ...}
   if (M.accessT.help == true) then
      for i = 1, arg.n do
         io.stderr:write(tostring(arg[i]))
      end
      io.stderr:write("\n")
   end
end

function M.whatis(self, msg)
   if (M.accessT.whatis) then
      local nm     = ModuleName or ""
      local l      = nm:len()
      local nblnks
      if (l < 20) then
         nblnks = 20 - l
      else
         nblnks = l + 2
      end
      local prefix = nm .. string.rep(" ",nblnks) .. ": "
      io.stderr:write(prefix, msg, "\n")
   end
end


M.report               = MasterControl.warning
M.always_load          = MasterControl.quiet
M.always_unload        = MasterControl.quiet
M.add_property         = MasterControl.quiet
M.append_path          = MasterControl.quiet
M.conflict             = MasterControl.quiet
M.error                = MasterControl.quiet
M.family               = MasterControl.quiet
M.inherit              = MasterControl.quiet
M.load                 = MasterControl.quiet
M.message              = MasterControl.quiet
M.myFileName           = MasterControl.myFileName
M.myModuleFullName     = MasterControl.myModuleFullName
M.myModuleName         = MasterControl.myModuleName
M.myModuleVersion      = MasterControl.myModuleVersion
M.prepend_path         = MasterControl.quiet
M.prereq               = MasterControl.quiet
M.prereq_any           = MasterControl.quiet
M.pushenv              = MasterControl.quiet
M.remove_path          = MasterControl.quiet
M.remove_property      = MasterControl.quiet
M.setenv               = MasterControl.quiet
M.set_alias            = MasterControl.quiet
M.set_shell_function   = MasterControl.quiet
M.try_load             = MasterControl.quiet
M.unload               = MasterControl.quiet
M.unloadsys            = MasterControl.quiet
M.unsetenv             = MasterControl.quiet
M.unset_shell_function = MasterControl.quiet
M.usrload              = MasterControl.quiet

return M
