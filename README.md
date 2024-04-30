BASIC.luau
============

A simple [BASIC](https://en.wikipedia.org/wiki/BASIC) interpreter for Roblox

The process of compiling the source is separated in two stages (top to bottom):
- Tokenizer (AKA lexer)
- Parser
- Compiler
- Virtual Machine (VM)

The tokenizer AKA [lexer](https://en.wikipedia.org/wiki/Lexical_analysis). Transforms the source code into a series of "tokens", which the parser will use as an input.

The parser will generate a [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree).

The compiler will generate a [bytecode](https://en.wikipedia.org/wiki/Bytecode), constants table and jump table.

The VM will interpret the bytecode using constants table and jump table.