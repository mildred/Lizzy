#!/usr/bin/env lua

local mt = {__index = table}

function table.last(t)
  return t[#t]
end

function table.compact(t, first, last)
  first = first or 1
  last  = last  or #t
  local res = {}
  for i = first, last do
    if t[i] ~= nil then
      res[#res+1] = t[i]
    end
  end
  return res
end

return function(o)
  o = o or {}
  return setmetatable(o, mt)
end

