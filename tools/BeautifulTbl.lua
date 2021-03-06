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

--------------------------------------------------------------------------
-- BeautifulTbl: This class is responsible for taking column data and
--               produce left or right justified columns.   The interface
--               is:
--                   local bt = BeautifulTbl:new{tbl = a,
--                                               column = TermWidth() - 1,
--                                               wrap   = true,
--                                               justifyT = {"L", "R", "R"},
--                                               length   = <len function>}
--
--                   io.stderr:write(bt:build_tbl())
--------------------------------------------------------------------------
-- Basic architecture of this class is:
--    a) The new member function computes the maximum size of every column
--       in the input table. It sets up the justifyT table.  Finally the
--       input table is copied over to an interal table (self.tbl) and
--       the correct left or right justification is added to the table.
--    b) the build_tbl() member function produces an output string of the
--       complete table.
--    c) If wrap is true then it checks to see if the table will fit the
--       available space (specified by the variable "column").  If it does
--       then the table is declared to be "simple" and the table is written
--       to the string.
--    d) If the table is too big (and wrap is true) then the last column
--       is word wrapped.
--------------------------------------------------------------------------
-- Here are ways this class can be used:
--    a) Present a column of words and numbers.  Here you might want to
--       left justify the columns with words and right justify the column
--       of numbers
--    b) Use the wrap=true option to word wrap the last column (note that
--       the last column will be left justified no matter what justifyT says).
--    c) The Help message for Lmod shows one other feature.  For a particular
--       row, if there is only one column in a multi-column table, that 1st
--       column is not used to count the maximum size of the column.  In
--       other words, these one column entries are allowed to span more than
--       one column.  Execute "module help" to see its effect.


require("strict")
require("string_split")
local dbg          = require("Dbg"):dbg()
local concatTbl	   = table.concat
local max	   = math.max
local min	   = math.min
local strlen       = string.len
local stdout       = io.stdout

local M = { gap = 2}

local blank = ' '

--------------------------------------------------------------------------
-- M.new(): Ctor for this class.  This member function calls M.__build_tbl
--          to do the heavy lifting.

function M.new(self, t)
   local tbl = t
   local o = {}
   if (t.tbl) then
      tbl = t.tbl
      o   = t
   end

   setmetatable(o, self)
   self.__index  = self

   o.length   = o.len or strlen
   o.justifyT = t.justifyT or {}
   o.tbl      = o:__build_tbl(tbl)
   o.column   = o.column  or 0
   o.wrapped  = o.wrapped or false
   return o
end

--------------------------------------------------------------------------
-- M.__build_tbl(): This is a private member function that client codes
--                  should not use.  It figures out the max size of each
--                  column.  Then adds spaces to make each column be
--                  justified.  By default all columns are left-justified.
--                  To get write right-justified, the client code must
--                  pass a "justifyT" array to specify.
--
--                  Each entry in the table is copied to an internal
--                  table and left or right justified (depending on
--                  justifyT).
   

function M.__build_tbl(self,tblIn)
   local length    = self.length
   local columnCnt = {}
   local tbl       = {}
   local justifyT  = {}


   -- find max column size.  Ignore one column rows.

   for irow = 1, #tblIn do
      local a    = tblIn[irow]
      local numC = #a
      for icol = 1, numC do
         local v = a[icol]
         if (numC > 1) then
            columnCnt[icol] = max(length(v), columnCnt[icol] or 0)
         end
      end
   end

   -- Build justifyT
   local maxnc = #columnCnt
   self.maxnc  = maxnc
   for icol = 1, maxnc do
      local s             = (self.justifyT[icol] or ""):lower():sub(1,1)
      justifyT[icol]      = (s == "r") and "r" or "l"
      self.justifyT[icol] = justifyT[icol]
   end


   -- Left or right justify every entry in tbl, except for
   -- single column rows.
   local gap = self.gap
   for irow = 1, #tblIn do
      local a    = tblIn[irow]
      local numC = #a
      local b    = {}
      

      for icol = 1, #a do
         local v = tostring(a[icol])
         if (numC == 1) then
            b[icol] = v
         else
            local nspaces = columnCnt[icol] - length(v)
            if (justifyT[icol] == "l") then
               b[icol] = v .. blank:rep(nspaces+gap)
            else
               b[icol] = blank:rep(nspaces) .. v .. blank:rep(gap)
            end
         end
         tbl[irow] = b
      end
   end

   self.columnCnt = columnCnt
   return tbl
end

--------------------------------------------------------------------------
-- Build "Beautiful Table" from internal table.

function M.build_tbl(self)
   local length = self.length
   
   local width  = 0
   local colgap = self.gap
   local simple = true
   if (self.wrapped and self.column > 0) then
      for i = 1, #self.columnCnt-1 do
         width = width + self.columnCnt[i] + colgap
      end
      local last = self.columnCnt[#self.columnCnt]
      simple = (width > self.column-20) or (width + last < self.column)
   end

   local a  = {}
   local tt = self.tbl

   if (next(tt) == nil) then
      return nil
   end

   -- If the table fits, then remove any trailing spaces in last
   -- column and build string of table.

   if (simple) then
      for j = 1,#tt do
         local t = tt[j]
         t[#t] = t[#t]:gsub("%s+$","")
         a[j]  = concatTbl(t,"")
      end
      return concatTbl(a,"\n")
   end

   -- If here then the last column must be wrapped. It removes any
   -- trailing spaces.  Note that the last column is the only column
   -- that is word wrapped.  Any short rows are copied straight
   -- across.

   self.column = self.column - 1
   local gap   = self.column - width
   local fill  = string.rep(" ",width)

   -- printing a wrapped last column
   local maxnc  = self.maxnc
   local maxnc1 = maxnc - 1
   for j = 1, #tt do
      local aa  = {}
      local t   = tt[j]
      local nc  = #t
      local nc1 = min(nc, maxnc1)
      
      -- For the current row copy every column but last.
      for i = 1, nc1 do
         aa[#aa+1] = t[i]
      end

      -- Now word wrap last column.
      if (nc == maxnc) then
         local icnt = width
         local s = t[#t] or ""
         for w in s:split("%s+") do
            local wlen = length(w)+1
            if (w == "") then
               wlen = 0
            elseif (icnt + wlen < self.column or wlen > gap) then
               aa[#aa+1] = w .. " "
            else
               aa[#aa]   = aa[#aa]:gsub("%s+$","")
               aa[#aa+1] = "\n"
               a[#a + 1] = concatTbl(aa,"")
               aa        = {}
               aa[1]     = fill
               icnt      = width
               aa[2]     = w .. " "
            end
            icnt = icnt + wlen
         end
      end
      aa[#aa]   = (aa[#aa] or ""):gsub("%s+$","")
      aa[#aa+1] = "\n"
      a[#a + 1] = concatTbl(aa,"")
   end
   return concatTbl(a,"")
end



return M
