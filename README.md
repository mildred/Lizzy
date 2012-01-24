Lizzy
=====

Lizzy is a language with a very simple syntax, that compiles to Lua. The syntax
is almost already completely defined ... see the parser.
It aims at being similar to Io, while still being different.

Syntax (without static typing)
==============================

Messages
--------

Send a message to a receiver:

    receiver message(arg1. arg2)

Send multiple messages to the same parent (result is the result of the last
message):

    receiver message1(arg1. arg2),
             message2(arg1. arg2)

Multiple instructions (result is the result of the last instruction):

    receiver message;
    receiver message;

Send a message to the implicit self receiver:

    message(args)

Each identifier can be included in quotes in case it contain special characters:

    "message with spaces"(args)

Quotes are quoted with another quote ("")

Variables
---------

It is possible to define local variables:

    local_variable := expr

This is just an alias for:

    ":="(local_variable. expr)

And the first argument of ":=" gets passed as an output value

Literals
--------

It is possible to prevent execution of the code using a backtick. This is how we
can create literals:

    `"literal string"
    `42
    42

A good practice is not to define messages with only numbers, this way we can
omit the backtick for literal numbers.

Types
-----

It is possible to check type conformance using the ollowing syntax:

    expr : type_expr

Which is just an alias for:

    type_expr ":"(expr)

Operator shifting
-----------------

This is defined at the parsing stage, and needs to be further defined given the
requirements exposed earlier. Among binary operators, we can define the
following characteristics:

- Swap operands or not

- Is the operator a message passed to an operand, or a message to the
  environment

Then we have the unary operands that can apply to the operand before or after.
And we have all the different priorities.

Static Typing
=============

Statis typing will be integrated in the language. It would be a core feature
that allows lazy evaliation of some parameters. This will be the only way to
create functions/methods.

When a message is sent, is must conform with an interface. If it does not, then
there is an error when it is detected. The interface tells the caller if the
argument must be evaluated, or passed in a lazy fashion.

To create a function, you send the message "function" which has an interface
that tells the argument is lazy evaluated. The argument is then evaluated when
the function is called.

ISSUE
-----

Static typing verification must be done before the code is executed, when
exactly:

- (A) Probably when the function gets compiled, but then the types must have
been defined by then. probably in another compilation unit, or in a meta
language run during compilation.

- (B) We can also check the types completely at runtime at the expense of
specialization at compile time (we have to make sure all arguments can be used
as inout, outputs or AST. This would induce runtime costs.

I would favour (A) with a special syntax marking the code to be evaluated at
compile time.

Environments
============

Each function or code unit has an environment that contain its local variables
and links to the environment of higher lexical context. At the top, we have the
default slots like ":=" implemented. This corresponds to the local variables in
Lua (including ":=").

If the matching is not found, then a global environment is called, which
contains the global variables. The different APIs ...

Lastly, if no matching is found, a string or a number gets created (TODO: define
exactly how intelligently)

When calling a function, it is possible to override its global environment to
expose it to a different API. This must be included in the static type
definition if a code is to be called in a different environment.

