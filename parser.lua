#!/usr/bin/env lua

local dump = require "DataDumper"
local list = require "list"

local function read_spaces(str, i)
  while str:match("^%s", i) do
    i = i + 1
  end
  return i
end

local function read_identifier(str, i)
  local start = i
  local idf = str:match("^%w+", i)
  if idf then
    i = i + #idf
  else
    local stridf = list{}
    repeat
      local m = str:match('^"[^"]+"', i)
      if m then
        stridf:insert(m)
        i = i + #m
      end
    until m == nil
    if #stridf > 0 then
      idf = stridf:concat()
    end
  end
  return i, idf
end

local function shuffle(cfg, sequence)
  return sequence
end

local function parse(cfg, str, i, code, param)
  i     = i     or 1
  code  = code  or list{"self"}
  param = param or {}
  local idf, c
  i = read_spaces(str, i)
  c = str:sub(i, i)
  if c == "," then
    return parse(cfg, str, i+1, code, {append=true})
  elseif c == "`" then
    param.escape=true
    return parse(cfg, str, i+1, code, param)
  elseif c == ";" then
    code:insert("self")
    return parse(cfg, str, i+1, code)
  elseif c == "(" then
    local args = {}
    code[#code].messages:last().args = args
    repeat
      args[#args+1], i = parse(cfg, str, i+1)
      c = str:sub(i, i)
    until c ~= "."
    if c == ")" then
      i = i + 1
    end
    return parse(cfg, str, i+1, code)
  elseif c == "." or c == "" then
    return code, i
  else
    i, idf = read_identifier(str, i)
    if idf then
      if param.append then
        local m = code[#code].messages:insert({name=idf, escape=param.escape})
      else
        code[#code] = {expr="message", receiver = code[#code], messages = list{{name=idf, escape=param.escape}}}
      end
      return parse(cfg, str, i, code)
    else
      return code, i, "Unexpected '"..str:sub(i, i).."'"
    end
  end
  return code, i, "End of code reached"
end

return function(config, i)
  return parse(config, config.string, i)
end
