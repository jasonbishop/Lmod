#!@path_to_lua@/lua
-- -*- lua -*-
------------------------------------------------------------------------
-- Use command name to add the command directory to the package.path
------------------------------------------------------------------------
local LuaCommandName = arg[0]
local i,j = LuaCommandName:find(".*/")
local LuaCommandName_dir = "./"
if (i) then
   LuaCommandName_dir = LuaCommandName:sub(1,j)
end
package.path = LuaCommandName_dir .. "?.lua;" .. package.path

------------------------------------------------------------------------
-- Try to load a SitePackage Module,  If it is not there then do not
-- abort.  Sites do not have to have a Site package.
------------------------------------------------------------------------
pcall(require, "SitePackage") 

function cmdDir()
   return LuaCommandName_dir
end
package.path = LuaCommandName_dir .. "?.lua;"      ..
               package.path

HashSum = "@path_to_hashsum@"

require("myGlobals")
require("strict")

require("fileOps")
require("capture")
require("firstInPath")
MasterControl = require("MasterControl")
MCP           = {}
mcp           = {}
require("modfuncs")
require("cmdfuncs")

BaseShell       = require("BaseShell")
Dbg             = require("Dbg")
Master          = require("Master")
ModuleStack     = require("ModuleStack")
MT              = require("MT")

local fh        = nil
local getenv    = os.getenv
local concatTbl = table.concat


function loadModuleFile(obj)
   local f
   if (type(obj) == "table") then
      f = obj.file
   else
      f = obj
   end

   local dbg     = Dbg:dbg()
   dbg.start("computeHashSum-> loadModuleFile(\"",tostring(f),"\")")
   local myType = extname(f)
   local func
   if (myType == ".lua") then
      func = loadfile(f)
   else
      local a     = {}
      a[#a + 1]	  = pathJoin(cmdDir(),"tcl2lua.tcl")
      a[#a + 1]	  = f
      local cmd   = table.concat(a," ")
      local s     = capture(cmd)
      func = loadstring(s)
   end
   if (func) then
      func()
   end
   dbg.fini()
end


function main()
   
   local dbg     = Dbg:dbg()
   local master  = Master:master(false)
   local mStack  = ModuleStack:moduleStack()
   master.shell  = BaseShell.build("bash")
   local fn      = os.tmpname()
   fh            = io.open(fn,"w")
   local verbose = false
   local i       = 1
   if (arg[1] == "-v") then
      i = i + 1
      verbose = true
   end
   --dbg:activateDebug()
   dbg.start("computeHashSum()")
   
   MCP           = MasterControl.build("computeHash","load")
   mcp           = MasterControl.build("computeHash","load")
   dbg.print("mcp set to ",mcp:name(),"\n")

   mStack:push("something",arg[i])
   loadModuleFile(arg[i])
   mStack:pop()
   local s = concatTbl(ComputeModuleResultsA,"")
   if (verbose) then
      io.stderr:write(s)
   end
   fh:write(s)
   if (HashSum:sub(1,1) == "@" ) then
      HashSum = findInPath("sha1sum")
   end

   local result = capture(HashSum .. " " .. fn)
   os.remove(fn)
   local i,j = result:find(" ")
   print (result:sub(1,i-1))
   dbg.fini()
end

main()