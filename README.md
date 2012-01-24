Lizzy
=====

Lizzy is a language with a very simple syntax, that compiles to Lua. The syntax
is almost already completely defined ... see the parser.
It aims at being similar to Io, while still being different.

Syntax (without static typing)
==============================

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

It is possible to prevent execution of the code using a backtick. This is how we
can create literals:

    `"literal string"
    `42
    42

A good practice is not to define messages with only numbers, this way we can
omit the backtick for literal numbers.

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


