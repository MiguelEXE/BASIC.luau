local function inputFunction(): string
	-- ...
end

local tokenizer = require(script.Parent.BASIC_Lang.Tokenizer);
local parser = require(script.Parent.BASIC_Lang.Parser);
local compiler = require(script.Parent.BASIC_Lang.Compiler);
local VM = require(script.Parent.BASIC_Lang.VM);

local a = parser.parse(tokenizer.scan([[]]));
local bytecode, constants, jumpTable = compiler.compile(a);
local state = VM.createState(bytecode, constants, jumpTable, print, inputFunction, true);
VM.runState(state);