#!/usr/bin/env lua

local dump = require "DataDumper"
local dbg  = require "dbg"

local walk_args
local walk_msg
local walk_alt
local walk_expr
local walk_instr
local walk_instrs

function walk_args(res, ast)
  for k, v in ipairs(ast) do
    walk_instrs(res, v)
  end
end

function walk_msg(res, ast)
  assert(ast[1] == "msg")
  res[#res+1] = ("%q"):format(ast.name)
  if ast.args then
    res[#res+1] = "("
    walk_args(res, ast.args)
    res[#res] = ")"
  end
end

function walk_alt(res, ast)
  for k, v in ipairs(ast) do
    if v[1] == "msg" then
      walk_msg(res, v)
      res[#res] = ", "
    else
      walk_alt(res, v)
    end
  end
end

function walk_expr(res, ast)
  dbg(ast)
  for k, v in ipairs(ast) do
    if v[1] == "msg" then
      walk_msg(res, v)
    else
      walk_alt(res, v)
    end
  end
end

function walk_instr(res, ast)
  walk_expr(res, ast)
  res[#res+1] = ";\n"
end

function walk_instrs(res, ast)
  for k, v in ipairs(ast) do
    walk_instr(res, v)
  end
  res[#res] = ".\n"
end

local function walker(ast)
  local res = {}
  walk_instrs(res, ast)
  return table.concat(res)
end

return walker
