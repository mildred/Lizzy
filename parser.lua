#!/usr/bin/env lua

local dump = require "DataDumper"
local list = require "list"
local dbg  = require "dbg"
local show = require "show"

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
    if #sequence > 1 then
      error("syntax error:\n" .. dbg(sequence))
      return sequence
    else
      return sequence[1]
    end
  end

  -- make a list of unary operators that can still be found
  local unary_ops = {}
  for key, op_desc in ipairs(operators) do
    if op_desc.ary == 1 then
      unary_ops[op_desc[1]] = op_desc
    end
  end
  
  -- get the current operator spec
  local op      = operators[1][1]
  local ary     = operators[1].ary
  local scope   = operators[1].scope
  local assoc   = operators[1].assoc
  local special = operators[1].special
  
  if ary == 2 and op ~= '' and  special == nil then
    -----------------------------------------------
    -- standard binary operators
    -----------------------------

    local seqs = list{list{}}
    
    local function is_binary(i, item)
      local last_seq = seqs:last()
      local next_seq = list{table.unpack(sequence, i+1)}
      -- check there are only left unary operators in next_seq
      local passed = false
      for j = 1, #next_seq do
        local itm = next_seq[j]
        if itm[1] == "msg" then
          passed = true -- next_seq passed the test
          break
        elseif itm[1] == "op"
          and unary_ops[itm.op] ~= nil
          and unary_ops[itm.op].assoc ~= "right" then
          -- go to next item, this is a left unary operator
        else
          -- if this is an operator, it is either binary or unary right
          return false
        end
      end
      if not passed then
        return false
      end
      -- check there are only right unary operators right of in last_seq
      local passed = false
      for j = #last_seq, 1, -1 do
        local itm = last_seq[j]
        if itm[1] == "msg" then
          passed = true -- last_seq passed the test
          break;
        elseif itm[1] == "op"
          and unary_ops[itm.op] ~= nil
          and unary_ops[itm.op].assoc ~= "left" then
          -- go to next item, this is a right unary operator
        else
          -- if this is an operator, it is either binary or unary left
          return false
        end
      end
      if not passed then
        return false
      end
      -- all tests passed
      return true
    end
    
    for i, item in ipairs(sequence) do
      if item[1] == "op" and item.op == op and is_binary(i, item) then
        seqs:insert(list{})
      else
        seqs:last():insert(item)
      end
    end
    if #seqs == 1 then
      seqs = seqs[1]
    else
      local expr
      while #seqs > 0 do
        local item
        if assoc == "right" then
          item = seqs:remove()
        else
          item = seqs:remove(1)
        end
        item = loc_shuffle({table.unpack(operators, 2)}, item)
        if expr == nil then
          expr = item
        elseif scope == "loc" then
          expr = {"msg", name=op, receiver=expr, args={item}}
        elseif scope == "env" then
          expr = {"msg", name=op, receiver=nil,  args={expr, item}}
        end
      end
      return expr
    end

  elseif ary == 2 and op == '' then
    -------------------------------
    -- send operator
    -----------------
    assert(special == 'send', "empty operator should be special send")
    assert(assoc   == 'left', "empty operator should have left associativity")

    local max = #sequence
    for i = 2, max do
      local receiver = sequence[i-1]
      local message  = sequence[i]
      if receiver[1] == "msg" and message[1] == "msg" then
        message.receiver = receiver
        sequence[i-1] = nil
      end
    end

    sequence = list(sequence:compact(1, max))
    
  elseif ary == 1 and special == nil then
    -------------------------------------
    -- standard unary operators
    ----------------------------
    
    assert(assoc == "left" or assoc == "right",
           "association must be one of 'left', 'right', 'both'")
    assert(scope == "loc", "scope must be local for unary operators")
    
    local function find_next_message(i)
      local j = i
      if assoc == "left" then
        i = i + 1
        while j <= #sequence and sequence[j][1] ~= "msg" do
          j = j + 1
        end
        if j > #sequence then
          return nil
        end
      elseif assoc == "right" then
        i = i - 1
        while j >= 1 and sequence[j][1] ~= "msg" do
          j = j - 1
        end
        if j < 1 then
          return nil
        end
      end
      return i, j
    end
    
    -- TODO: doesn't work for right assoc
    
    local pos = 'left'
    local i = 1
    while i <= #sequence do
      local item = sequence[i]
      if item[1] == "msg" then
        pos = 'right'
      elseif item[1] == "op" and item.op == op and assoc == pos then
        pos = 'right'
        local a, b = find_next_message(i) -- a is i+1, b is a message
        local rec = loc_shuffle(operators, list{sequence:unpack(a, b)})
        sequence[i] = {"msg", name=op, receiver=rec}
        if a > b then
          a, b = b, a
        end
        for k = b, a, -1 do
          sequence:remove(k)
        end
      end
      i = i + 1
    end
    
    
    
    -- local max = #sequence
    -- 
    -- if assoc == "left" or assoc == "both" then
    --   dbg{op, left=sequence}
    --   for i = max, 2, -1 do
    --     local itm_op  = sequence[i-1]
    --     local itm_msg = sequence[i]
    --     if itm_op[1] == "op" and itm_op[1].op == op and itm_msg[1] == "msg" then
    --       sequence[i] = {"msg", receiver=itm_msg, name=op}
    --       sequence[i-1] = nil
    --     end
    --   end
    --   sequence = list(sequence:compact(1, max))
    -- end
    -- 
    -- if assoc == "right" or assoc == "both" then
    --   dbg{op, right=sequence}
    --   for i = 1, max - 1 do
    --     local itm_msg = sequence[i]
    --     local itm_op  = sequence[i+1]
    --     if itm_op[1] == "op" and itm_op[1].op == op and itm_msg[1] == "msg" then
    --       sequence[i] = {"msg", receiver=itm_msg, name=op}
    --       sequence[i+1] = nil
    --     end
    --   end
    --   sequence = list(sequence:compact(1, max))
    -- end
    -- dbg{op, unary=sequence}
    
  end
  
  -- next operator
  return loc_shuffle({table.unpack(operators, 2)}, sequence)
end

local function shuffle(cfg, code)
  code.next = nil
  show(code)
  print "..."
  for k, seq in ipairs(code) do
    code[k] = loc_shuffle(cfg.operators, seq)
  end
  code.next = nil
  show(code)
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
