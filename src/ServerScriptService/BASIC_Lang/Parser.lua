--!strict
local module = {}

local common = require(script.Parent.Common);
local tokenizer = require(script.Parent.Tokenizer);
export type Operation = UnOperation | BinOperation;
export type UnOperation = {
	type: "unoperation";
	operator: string;
	expression: ParsedExpression
};
export type BinOperation = {
	type: "binoperation";
	operator: string;
	left: ParsedExpression;
	right: ParsedExpression;
};
export type FunctionCall = {
	type: "functionCall";
	name: string;
	arguments: {Operation | tokenizer.Token | FunctionCall}
};
export type ParsedExpression = Operation | FunctionCall | tokenizer.Token;
export type Declaration = {
	type: "declaration",
	name: string;
	value: ParsedExpression;
};
export type ParseResult = ParsedExpression | Declaration;
local unaryEquivalent = { -- cur.operator returns the operator type for binops
	SUB = "NEGATIVE",
	ADD = "POSITIVE"
};
local opPrecedence: {[string]: number} = {
	LESS = 1,
	GREATHER = 1,
	ELESS = 1,
	EGREATHER = 1,
	EQUAL = 1,
	NEQUAL = 1,
	
	ADD = 2,
	SUB = 2,
	MUL = 3,
	DIV = 3,
	
	POSITIVE = 4,
	NEGATIVE = 4
};
module.opPrecedence = opPrecedence;

local breakTokens = {"THENGOTO", "TO", "DO", "STEP", "IN"};

function module.is_binop(token: tokenizer.Token): boolean
	return token.type == "operator";
end
local function shouldBreak(cur: tokenizer.Token)
	return 
		cur == nil 
		or
		(cur.type == "keyword" and table.find(breakTokens, tostring(cur.name)) ~= nil)
		or
		cur.type == "separator" and (cur.separator == "ACONT" or cur.separator == "CBRACK" or cur.separator == "EINSTR");
end
function module.parseFunction(tokens: {tokenizer.Token}, min_prec: number, functionName: string): FunctionCall
	local openParenthesesToken = table.remove(tokens, 1);
	assert(openParenthesesToken ~= nil, "Unexpected EOF");
	assert(openParenthesesToken.type == "separator" and openParenthesesToken.separator == "OBRACK", "Expected OBRACK");
	
	local parsedFunction: FunctionCall = {
		type = "functionCall",
		name = functionName,
		arguments = {}
	};
	
	if shouldBreak(tokens[1]) then
		table.remove(tokens, 1);
		return parsedFunction;
	end
	repeat
		local expression = module.compute_expression(tokens, min_prec);
		local separatorToken = table.remove(tokens, 1);
		if expression ~= nil then
			table.insert(parsedFunction.arguments, expression);
		end
		assert(separatorToken ~= nil, "Unexpected EOF");
		assert(separatorToken.type == "separator", "Expected CBRACK or ACONT");
	until separatorToken.separator == "CBRACK";
	return parsedFunction;
end

function module.compute_expression(tokens: {tokenizer.Token}, min_prec: number, lastToken: ParsedExpression?): ParsedExpression
	while true do
		local cur = tokens[1];
		-- if its a break keyword (like THENGOTO, STEP, etc...) or if it's a break separator (like CBRACK, ACONT, etc)
		if shouldBreak(cur) then 
			break;
		end
		-- if it's not a break keyword, it's a function for sure (we don't have user-defined functions here)
		if cur.type == "keyword" then
			table.remove(tokens, 1); 												-- remove the keyword
			lastToken = module.parseFunction(tokens, min_prec, tostring(cur.name)); -- and pass that to the parseFunction
			-- ugly but update the cur to the next token
			cur = tokens[1];
			if shouldBreak(cur) then
				break;
			end
		end
		-- we can have a case where a input like "20 40" is given, we throw if that happens
		if not module.is_binop(cur) then
			assert(lastToken == nil, "Cannot parse two consecutive atoms");
			table.remove(tokens, 1);
			return module.compute_expression(tokens, min_prec, cur);
		end
		
		-- also we can have a case where the input is " + 40" is given, the parser doesn't support unary expression (for now) so we throw also if that happens
		-- assert(lastToken ~= nil, "Binops need two hand sides");
		if lastToken == nil then
			local unaryEquivalent = unaryEquivalent[tostring(cur.operator)];
			assert(unaryEquivalent ~= nil, "Unknown operator");
			local prec = opPrecedence[unaryEquivalent];
			if prec < min_prec then
				break;
			end
			table.remove(tokens, 1);
			lastToken = {
				type = "unoperation",
				operator = unaryEquivalent,
				expression = module.compute_expression(tokens, prec + 1)
			};
			continue;
		end
		
		local prec = opPrecedence[tostring(cur.operator)];
		if prec < min_prec then
			break;
		end
		
		table.remove(tokens, 1);
		local right = module.compute_expression(tokens, prec + 1);
		--we can have a case where a input like "40 + " is given, we throw if that happens
		assert(right ~= nil, "Binops needs two hand sides");
		
		lastToken = {
			type 		= "binoperation",
			operator	= tostring(cur.operator),
			left 		= lastToken,
			right 		= right
		};
	end
	-- parser always gives a result, throw if the parser didn't get a result.
	assert(lastToken ~= nil, "Unexpected instruction end, closing brackets, EOF or multiple negative/positive operators in row.");
	return lastToken;
end
local function parseDeclaration(tokens: {tokenizer.Token}): Declaration
	local variableToken = table.remove(tokens, 1);
	assert(variableToken ~= nil, "Expected identifier")
	assert(variableToken.type == "identifier", "Expected a variable name");
	local signToken = table.remove(tokens, 1);
	assert(signToken ~= nil, "Expected a '=' operator");
	assert(signToken.type == "operator", "Expected a operator");
	assert(signToken.operator == "DECL", "Expected a declaration operator");
	local declaration: Declaration = {
		type = "declaration",
		name = tostring(variableToken.name),
		value = module.compute_expression(tokens, 0)
	};
	return declaration;
end
local function endInstruction(tokens: {tokenizer.Token}): ()
	local endInstructionToken = table.remove(tokens, 1);
	assert(endInstructionToken ~= nil, "Expected semi-colon");
	assert(endInstructionToken.type == "separator", "Expected semi-colon");
	assert(endInstructionToken.separator == "EINSTR", "Expected semi-colon");
end

local function parseLetInstruction(tokens: {tokenizer.Token})
	local declaration = parseDeclaration(tokens);
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "LET",
		identifier = declaration.name,
		value = declaration.value
	}
end
local function parseGotoInstruction(tokens: {tokenizer.Token})
	local integerToken = table.remove(tokens, 1);
	assert(integerToken ~= nil, "Expected constant line number");
	assert(integerToken.literal ~= nil, "Expected constant line number");
	assert(integerToken.literal.literalType == "integer", "Expected constant line number");
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "GOTO",
		line = integerToken.literal.value
	}
end
local function parseIfInstruction(tokens: {tokenizer.Token})
	local operation = module.compute_expression(tokens, 0);
	local thenGotoToken = table.remove(tokens, 1);
	assert(thenGotoToken ~= nil, "Expected THENGOTO");
	assert(thenGotoToken.type == "keyword", "Expected THENGOTO");
	assert(thenGotoToken.name == "THENGOTO", "Expected THENGOTO");
	local lineNumToken = table.remove(tokens, 1);
	assert(lineNumToken ~= nil, "Expected constant line number");
	assert(lineNumToken.literal ~= nil, "Expected constant line number");
	assert(lineNumToken.literal.literalType == "integer", "Expected constant line number");
	local thenGotoInteger = lineNumToken.literal.value;
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "IF",
		operation = operation,
		thenGotoLine = thenGotoInteger
	}
end
local function parseInputInstruction(tokens: {tokenizer.Token})
	local variable = table.remove(tokens, 1);
	assert(variable ~= nil, "Expected variable name");
	assert(variable.type == "identifier", "Expected variable");
	local separator = table.remove(tokens, 1);
	assert(separator ~= nil, "Expected separation");
	assert(separator.type == "separator", "Expected separation");
	assert(separator.separator == "ACONT", "Expected separation");
	local operation = module.compute_expression(tokens, 0);
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "INPUT",
		operation = operation,
		variableName = variable.name
	};
end
local function parsePrintInstruction(tokens: {tokenizer.Token})
	local operations = {};
	repeat
		local expression = module.compute_expression(tokens, 0);
		local separatorToken = table.remove(tokens, 1);
		if expression ~= nil then
			table.insert(operations, expression);
		end
		assert(separatorToken ~= nil, "Unexpected EOF");
		assert(separatorToken.type == "separator", "Expected separation or semi-colon");
	until separatorToken.separator == "EINSTR";
	
	return {
		type = "instruction",
		instruction = "PRINT",
		operations = operations
	};
end
local function parseEndOperation(tokens: {tokenizer.Token})
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "END"
	};
end
local function parseWriteInstruction(tokens: {tokenizer.Token})
	local operation = module.compute_expression(tokens, 0);
	local toToken = table.remove(tokens, 1);
	assert(toToken ~= nil, "Expected TO");
	assert(toToken.type == "keyword", "Expected TO");
	assert(toToken.name == "TO", "Expected TO");
	local variable = table.remove(tokens, 1);
	assert(variable ~= nil, "Expected variable");
	assert(variable.type == "identifier", "Expected variable");
	local inToken = table.remove(tokens, 1);
	assert(inToken ~= nil, "Expected IN");
	assert(inToken.type == "keyword", "Expected IN");
	assert(inToken.name == "IN", "Expected IN");
	local index = module.compute_expression(tokens, 0);
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "WRITE",
		operation = operation,
		variable = variable.name,
		index = index
	}
end
local function parseForInstruction(tokens: {tokenizer.Token})
	local declaration = parseDeclaration(tokens);
	local toToken = table.remove(tokens, 1);
	assert(toToken ~= nil, "Expected TO");
	assert(toToken.type == "keyword", "Expected TO");
	assert(toToken.name == "TO", "Expected TO");
	local toNum = module.compute_expression(tokens, 0);
	local token2 = tokens[1];
	local step = nil;
	if token2.type == "keyword" and token2.name == "STEP" then
		table.remove(tokens, 1);
		step = module.compute_expression(tokens, 0);
	end
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "FOR",
		to = toNum,
		step = step,
		variableName = declaration.name,
		startingValue = declaration.value
	};
end

local function parseNextInstruction(tokens: {tokenizer.Token})
	local variableToken = table.remove(tokens, 1);
	assert(variableToken ~= nil, "Expected variable");
	assert(variableToken.type == "identifier", "Expected variable");
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "NEXT",
		variable = variableToken.name
	};
end

local instructionParsers = {
	["GOTO"] 	= parseGotoInstruction,
	["LET"] 	= parseLetInstruction,
	["FOR"] 	= parseForInstruction,
	["IF"] 		= parseIfInstruction,
	["INPUT"] 	= parseInputInstruction,
	["PRINT"] 	= parsePrintInstruction,
	["WRITE"] 	= parseWriteInstruction,
	["NEXT"]	= parseNextInstruction,
	["END"]		= parseEndOperation
};

function module.parse(tokens: {tokenizer.Token})
	local lineNumber: number? = nil;
	local numberedInstructions = {
		["noLine"] = {}
	};
	while true do
		local token = table.remove(tokens, 1);
		if token == nil and lineNumber == nil then
			break;
		end
		assert(token ~= nil, "Unexpected EOF");
		if token.type == "comment" then
			lineNumber = nil;
			continue;
		end
		if token.type == "lineBreak" then
			continue;
		end
		if token.type == "lineNumber" then
			lineNumber = token.lineNumber;
			continue;
		end
		assert(token.type == "keyword", "Expected instruction");
		local parser = instructionParsers[token.name];
		assert(parser ~= nil, "Parser function doens't exist");
		local parsed = parser(tokens);
		if lineNumber == nil then
			table.insert(numberedInstructions["noLine"], parsed);
		end
		numberedInstructions[lineNumber] = parsed;
		lineNumber = nil;
	end
	return numberedInstructions;
end

return module
