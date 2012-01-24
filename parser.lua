#!/usr/bin/env lua

local dump = require "DataDumper"

local function read_spaces(str, i)
  while str:match("^%s", i) do
    i = i + 1
  end
  return i
end

local function read_identifier(str, i)
  local start = i
  while str:match("^%w", i) do
    i = i + 1
  end
  if start == i then
    return i
  else
    return i, str:sub(start, i-1)
  end
end

local function parse(str, i, code, append)
  i    = i    or 1
  code = code or {"self"}
  local idf, c
  i = read_spaces(str, i)
  c = str:sub(i, i)
  if c == "," then
    return parse(str, i+1, code, true)
  elseif c == ";" then
    code[#code+1] = "self"
    return parse(str, i+1, code)
  elseif c == "(" then
    local args = {}
    local m = code[#code].messages
    m[#m].args = args
    repeat
      args[#args+1], i = parse(str, i+1)
      c = str:sub(i, i)
    until c ~= "."
    if c == ")" then
      i = i + 1
    end
    return parse(str, i+1, code)
  elseif c == "." or c == "" then
    return code, i
  else
    i, idf = read_identifier(str, i)
    if idf then
      if append then
        local m = code[#code].messages
        m[#m+1] = {name=idf}
      else
        code[#code] = {receiver = code[#code], messages = {{name=idf}}}
      end
      return parse(str, i, code)
    else
      return code, i, "Unexpected '"..str:sub(i, i).."'"
    end
  end
  return code, i, "End of code reached"
end

return parse
