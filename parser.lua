#!/usr/bin/env lua

local dump = require "DataDumper"
local list = require "list"
local dbg  = require "dbg"

table.unpack = table.unpack or unpack

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

local function walk_direction(table, direction)
  if direction == "right" then
    return #table, 1, -1
  else
    return 1, #table, 1
  end
end

local function loc_shuffle(operators, sequence)
  if operators[1] == nil then
    return sequence
  end
  local op      = operators[1][1]
  local ary     = operators[1].ary
  local scope   = operators[1].scope
  local assoc   = operators[1].assoc
  local special = operators[1].special
  local a, b, c = walk_direction(sequence, assoc)
  for i = a, b, c do
    print(i)
  end
  return loc_shuffle({table.unpack(operators, 2)}, sequence)
end

local function shuffle(cfg, code)
  code.next = nil
  dbg(code)
  print "..."
  for k, seq in ipairs(code) do
    code[k] = loc_shuffle(cfg.operators, seq)
  end
  code.next = nil
  dbg(code)
  print "---"
end

local function parse(cfg, str, i, code)
  i         = i         or 1
  code      = code      or list{list{}}
  code.next = code.next or code[#code]
  local idf, c
  i = read_spaces(str, i)
  c = str:sub(i, i)
  if c == "(" then
    local args = {}
    code.next:last().args = args
    repeat
      args[#args+1], i = parse(cfg, str, i+1)
      c = str:sub(i, i)
    until c ~= "."
    if c == ")" then
      i = i + 1
    end
    return parse(cfg, str, i+1, code)
  elseif c == "," then
    local next = list{}
    next:insert(code.next:last())
    code.next[#code.next] = next
    code.next = next
    return parse(cfg, str, i+1, code)
  elseif c == ";" then
    code:insert(list{})
    code.next = code[#code]
    return parse(cfg, str, i+1, code)
  elseif c == "." or c == "" then
    shuffle(cfg, code)
    return code, i
  else
    i, idf = read_identifier(str, i)
    if idf then
      code.next:insert({"msg", name=idf})
      return parse(cfg, str, i, code)
    else
      local op = str:match("^%S+", i)
      if op then
        i = i + #op
      end
      code.next:insert({"op", op=op})
      return parse(cfg, str, i, code)
    end
  end
  shuffle(cfg, code)
  return code, i, "End of code reached"
end

return function(config, i)
  config = config or {}
  config.operators = config.operators or {
    {":=", ary=2, scope='env', assoc='left'},
    {":",  ary=2, scope='loc', assoc='right'},
    {"/",  ary=2, scope='loc', assoc='left'},
    {"*",  ary=2, scope='loc', assoc='right'},
    {"-",  ary=2, scope='loc', assoc='left'},
    {"+",  ary=2, scope='loc', assoc='right'},
    {"",   ary=2, scope='***', assoc='left',  special='send'},
    {",",  ary=1, scope='***', assoc='right', special='parent'},
    {"!",  ary=1, scope='loc', assoc='right'},
    {"-",  ary=1, scope='loc', assoc='left'}
  }
  return parse(config, config.string, i)
end
