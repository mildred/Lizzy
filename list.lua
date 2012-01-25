#!/usr/bin/env lua

local mt = {__index = table}

function table.last(t)
  return t[#t]
end

return function(o)
  o = o or {}
  return setmetatable(o, mt)
end

