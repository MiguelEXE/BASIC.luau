--!strict
local common = require(script.Parent.Common);
local tokenizer = require(script.Parent.Tokenizer);

local function skipLineBreaks(tokens: {tokenizer.Token}): ()
	local token: tokenizer.Token? = tokens[1];
	while if token ~= nil then token.type == "lineBreak" else false do
		token = table.remove(tokens, 1);
	end
end

local parseOperation: (tokens: {tokenizer.Token}, breakOnCBrack: boolean) -> Operation | PrioritizedOperation | tokenizer.Token | FunctionCall | Identifier
export type Operation = {
	type: string;
	left: tokenizer.Token | Operation | FunctionCall | Identifier | PrioritizedOperation;
	right: tokenizer.Token | Operation | FunctionCall | Identifier | PrioritizedOperation;
};
export type PrioritizedOperation = {
	type: "prioritized";
	value: Operation | FunctionCall | Identifier | PrioritizedOperation | tokenizer.Token;
};
export type ParsedIdentifier = {
	name: string
};
export type Identifier = ParsedIdentifier | {
	type: "variable";
	arguments: nil;
};
export type FunctionCall = ParsedIdentifier | {
	type: "functionCall";
	arguments: {Operation | PrioritizedOperation | tokenizer.Token | FunctionCall | Identifier}
};
local breakTokens = {"THENGOTO", "TO", "DO", "STEP", "IN"};
local function isBreakToken(name: string?): boolean
	for _,tokenName in ipairs(breakTokens) do
		if tokenName == name then
			return true;
		end
	end
	return false;
end
local function parseIdentifier(tokens: {tokenizer.Token}): Identifier
	skipLineBreaks(tokens);
	local token = tokens[1];
	if token.type ~= "identifier" then
		error("Expected a identifier");
	end
	local variableName = token.name;
	if variableName == nil then -- impossible to get but ok
		error("Expected variable name");
	end
	table.remove(tokens, 1);
	return {
		type = "variable",
		name = variableName
	};
end
local function parseFunctionCall(tokens: {tokenizer.Token}): FunctionCall?
	skipLineBreaks(tokens);
	local token = tokens[1];
	if token.type ~= "keyword" then
		error("Expected a keyword (internal function)");
	end
	local variableName = token.name;
	if variableName == nil then -- impossible to get but ok
		error("Expected variable name");
	end
	if table.find(common.functionNames, variableName) == nil then
		error("Invalid function name");
	end
	table.remove(tokens, 1);
	skipLineBreaks(tokens);
	local token = tokens[1];
	if token == nil then
		return;
	end
	if token.type ~= "separator" then
		return;
	end
	if token.separator ~= "OBRACK" then
		return;
	end
	local argumentList = {};
	table.remove(tokens, 1);
	while true do
		skipLineBreaks(tokens);
		local token = tokens[1];
		if token == nil then
			error("Unexpected EOF");
		end
		if token.type == "separator" and token.separator == "CBRACK" then
			table.remove(tokens, 1);
			break;
		end
		if token.type == "separator" and token.separator == "ACONT" then
			table.remove(tokens, 1);
			continue;
		end
		table.insert(argumentList, parseOperation(tokens, true));
		--error("Expected closed brackets or comma");
	end
	return {
		type = "functionCall",
		name = variableName,
		arguments = argumentList
	};
end
parseOperation = function(tokens: {tokenizer.Token}, breakOnCBrack: boolean): Operation | PrioritizedOperation | tokenizer.Token | FunctionCall | Identifier
	local leftBuf: Operation | PrioritizedOperation | tokenizer.Token | FunctionCall | Identifier;
	local operatorType: string?;
	local hasOperator = false;
	local function postProcess(parsed: Operation | PrioritizedOperation | tokenizer.Token | FunctionCall | Identifier): ()
		if leftBuf == nil then
			leftBuf = parsed;
			return;
		end
		if operatorType == nil then
			error("Expected operator");
		end
		leftBuf = {
			left = leftBuf,
			type = operatorType,
			right = parsed
		};
		operatorType = nil;
	end
	while true do
		local token = tokens[1];
		if token == nil then
			break;
		end
		if token.type == "separator" then
			if token.separator == "CBRACK" then
				if leftBuf == nil then
					error("Cannot parse empty brackets");
				end
				if breakOnCBrack then
					break;
				end
				table.remove(tokens, 1);
				return {
					type = "prioritized",
					value = leftBuf
				};
			elseif token.separator == "OBRACK" then
				table.remove(tokens, 1);
				postProcess(parseOperation(tokens, false));
				continue;
			else
				break;
			end
		end
		if token.type == "identifier" then
			postProcess(parseIdentifier(tokens));
			continue;
		end
		if token.type == "keyword" then
			if isBreakToken(token.name) then
				break;
			end
			local functionCall = parseFunctionCall(tokens);
			if functionCall == nil then
				error("Unexpected keyword");
			end
			postProcess(functionCall);
			continue;
		end
		if token.type == "literal" then
			table.remove(tokens, 1);
			postProcess(token);
			continue;
		end
		if token.type == "operator" then
			if leftBuf == nil then
				error("Expected a left statement");
			end
			if operatorType ~= nil then
				error("Unexpected operator");
			end
			table.remove(tokens, 1);
			operatorType = token.operator;
			continue;
		end
		error("Expected operator, identifier or separator");
	end
	if leftBuf == nil then
		error("Expected expression");
	end
	return leftBuf;
end
local function parseDeclaration(tokens: {tokenizer.Token})
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Syntax error: Expected identifier");
	end
	if token.type ~= "identifier" then
		error("Syntax error: Expected a variable name");
	end
	skipLineBreaks(tokens);
	local token2 = table.remove(tokens, 1);
	if token2 == nil then
		error("Syntax error: Expected a '=' operator");
	end
	if token2.type ~= "operator" then
		error("Syntax error: Expected a operator");
	end
	if token2.operator ~= "DECL" then
		error("Syntax error: Expected a declaration operator");
	end
	local declaration = {
		name = token.name,
		value = parseOperation(tokens, false)
	};
	return declaration;
end

local function endInstruction(tokens: {tokenizer.Token}): ()
	skipLineBreaks(tokens);
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Syntax error: Expected INSTR");
	end
	if token.type ~= "separator" then
		error("Syntax error: Expected INSTR");
	end
	if token.separator ~= "EINSTR" then
		error("Syntax error: Expected INSTR");
	end
end

local function parseLetInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
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
	skipLineBreaks(tokens);
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Expected integer");
	end
	if token.literal == nil then
		error("Expected integer");
	end
	if token.literal.literalType ~= "integer" then
		error("Expected integer");
	end
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "GOTO",
		line = token.literal.value
	}
end
local function parseIfInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
	local operation = parseOperation(tokens, false);
	skipLineBreaks(tokens);
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Expected keyword");
	end
	if token.type ~= "keyword" then
		error("Expected keyword");
	end
	if token.name ~= "THENGOTO" then
		error("Expected THENGOTO");
	end
	skipLineBreaks(tokens);
	local thenGoto = table.remove(tokens, 1);
	if thenGoto == nil then
		error("Expected integer");
	end
	if thenGoto.literal == nil then
		error("Expected integer");
	end
	if thenGoto.literal.literalType ~= "integer" then
		error("Expected integer");
	end
	local thenGotoInteger = thenGoto.literal.value;
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "IF",
		operation = operation,
		thenGotoLine = thenGotoInteger
	}
end
local function parseInputInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
	local variable = table.remove(tokens, 1);
	if variable == nil then
		error("Expected variable name");
	end
	if variable.type ~= "identifier" then
		error("Expected variable name");
	end
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Expected separator");
	end
	if token.type ~= "separator" then
		error("Expected separator");
	end
	if token.separator ~= "ACONT" then
		error("Expected ACONT");
	end
	local operation = parseOperation(tokens, false);
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "INPUT",
		operation = operation,
		variableName = variable.name
	};
end
local function parseForInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
	local declaration = parseDeclaration(tokens);
	skipLineBreaks(tokens);
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Expected TO");
	end
	if token.type ~= "keyword" then
		error("Expected TO");
	end
	if token.name ~= "TO" then
		error("Expected TO");
	end
	local toNum = parseOperation(tokens, false);
	skipLineBreaks(tokens);
	local token2 = tokens[1];
	local step = nil;
	if token2.type == "keyword" and token2.name == "STEP" then
		table.remove(tokens, 1);
		step = parseOperation(tokens, false);
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
local function parsePrintInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
	local operations = {};
	while true do
		table.insert(operations, parseOperation(tokens, false));
		local token = table.remove(tokens, 1);
		if token == nil then
			error("Expected separator");
		end
		if token.type ~= "separator" then
			error("Expected separator");
		end
		if token.separator == "EINSTR" then
			break;
		elseif token.separator == "ACONT" then
			continue;
		end
		error("Expected EINSTR or ACONT");
	end
	return {
		type = "instruction",
		instruction = "PRINT",
		operations = operations
	};
end
local function parseNextInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Expected variable");
	end
	if token.type ~= "identifier" then
		error("Expected variable");
	end
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "NEXT",
		variable = token.name
	};
end
local function parseWriteInstruction(tokens: {tokenizer.Token})
	skipLineBreaks(tokens);
	local operation = parseOperation(tokens, false);
	local toToken = table.remove(tokens, 1);
	if toToken == nil then
		error("Expected TO");
	end
	if toToken.type ~= "keyword" then
		error("Expected TO");
	end
	if toToken.name ~= "TO" then
		error("Expected TO");
	end
	local variable = table.remove(tokens, 1);
	if variable == nil then
		error("Expected variable");
	end
	if variable.type ~= "identifier" then
		error("Expected variable");
	end
	local inToken = table.remove(tokens, 1);
	if inToken == nil then
		error("Expected IN");
	end
	if inToken.type ~= "keyword" then
		error("Expected IN");
	end
	if inToken.name ~= "TO" then
		error("Expected IN");
	end
	local index = parseOperation(tokens, false);
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "WRITE",
		operation = operation,
		variable = variable.name,
		index = index
	}
end
local function parseNextOperation(tokens: {tokenizer.Token})
	local token = table.remove(tokens, 1);
	if token == nil then
		error("Expected variable");
	end
	if token.type ~= "identifier" then
		error("Expected variable");
	end
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "NEXT",
		variableName = token.name
	};
end
local function parseEndOperation(tokens: {tokenizer.Token})
	endInstruction(tokens);
	return {
		type = "instruction",
		instruction = "END"
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
	["NEXT"]	= parseNextOperation,
	["END"]		= parseEndOperation
};

local function parse(tokens: {tokenizer.Token})
	local lineNumber: number? = nil;
	local numberedInstructions = {
		["noLine"] = {}
	};
	while true do
		local token = table.remove(tokens, 1);
		if token == nil and lineNumber == nil then
			break;
		end
		if token == nil then
			error("Unexpected EOF");
		end
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
		if token.type ~= "keyword" then
			error("Expected instruction");
		end
		local parser = instructionParsers[token.name];
		if parser == nil then
			error("Expected valid instruction");
		end
		local parsed = parser(tokens);
		if lineNumber == nil then
			table.insert(numberedInstructions["noLine"], parsed);
		end
		numberedInstructions[lineNumber] = parsed;
		lineNumber = nil;
	end
	return numberedInstructions;
end

return {
	parse = parse,
};