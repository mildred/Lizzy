#!/usr/bin/env lua

io     = require "io"
parser = require "parser"
walker = require "walker"
dump   = require "DataDumper"

local ast, i, msg = parser(io.stdin:read("*all"))
if msg then
  print(i, msg)
end
-- print(dump(ast))
print(walker(ast))

