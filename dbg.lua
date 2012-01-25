#!/usr/bin/env lua

list = require "list"

local function dbg(o, indent)
  indent = indent or ""
  local res = list{}
  local typ = type(o)
  if typ == "table" then
    local parts = list{}
    local totallen = 0
    local tablepart = 1
    for k, v in pairs(o) do
      local line = list{}
      if type(k) == "number" and tablepart == k then
        tablepart = tablepart + 1
      else
        tablepart = false
        if type(k) == "string" and k:match("^[%w_]+$") then
          line:insert(k)
          line:insert("=")
        else
          line:insert("[")
          line:insert(dbg(k, indent .. "  "))
          line:insert("] = ")
        end
      end
      line:insert(dbg(v, indent .. "  "))
      line = line:concat()
      parts:insert(line)
      totallen = totallen + #line + 1
    end
    if totallen + #indent > 70 then
      return "{ " .. parts:concat(",\n" .. indent .. "  ") .. "\n" .. indent .. "}"
    else
      return "{ " .. parts:concat(", ") .. " }"
    end
  elseif typ == "string" then
    res:insert(("%q"):format(o))
  else
    res:insert(tostring(o))
  end
  return res:concat()
end

return function(o)
  print(dbg(o))
end
