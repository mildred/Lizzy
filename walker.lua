#!/usr/bin/env lua

local dump = require "DataDumper"

local walk_args
local walk_expr
local walk_instr
local walk_instrs

function walk_args(res, ast)
  for k, v in ipairs(ast) do
    walk_instrs(res, v)
  end
end

function walk_expr(res, ast)
  if type(ast) == "string" then
    res[#res+1] = "$"
    res[#res+1] = ("%q"):format(ast)
  else
    walk_expr(res, ast.receiver)
    res[#res+1] = " "
    for k, v in ipairs(ast.messages) do
      res[#res+1] = ("%q"):format(v.name)
      if v.args then
        res[#res+1] = "("
        walk_args(res, v.args)
        res[#res] = ")"
      end
      res[#res+1] = ", "
    end
    res[#res] = nil
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
