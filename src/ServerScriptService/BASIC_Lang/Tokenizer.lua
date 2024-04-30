--!strict
local common = require(script.Parent.Common);

local function findSep(char: string): common.Separator?
	for _,sep in ipairs(common.separators) do
		if sep.separator == char then
			return sep;
		end
	end
	return nil;
end
local function tokenize_string(splitted: {string}, index: number): (string?, number)
	local singleQuote = splitted[index] == "'";
	if splitted[index] ~= "\"" and not singleQuote then
		return nil, index;
	end
	index = index + 1;
	local value = "";
	while true do
		local char = splitted[index];
		if char == "\n" and singleQuote then
			error("Syntax error: Invalid string");
		end
		if char == nil then
			error("Syntax error: Invalid string");
		end
		if char == "\"" and not singleQuote then
			index = index + 1;
			break;
		end
		if char == "'" and singleQuote then
			index = index + 1;
			break;
		end
		value = value .. char;
		index = index + 1;
	end
	return value, index;
end
local asciiNum2num: {[string]: number} = {
	["1"] = 1,
	["2"] = 2,
	["3"] = 3,
	["4"] = 4,
	["5"] = 5,
	["6"] = 6,
	["7"] = 7,
	["8"] = 8,
	["9"] = 9,
	["0"] = 0
};
local floatBreakCharacters = {
	",",
	";",
	")",
	"=",
	"!",
	">",
	"<",
	"+",
	"-",
	"*",
	"/"
};
local function tokenize_float(splitted: {string}, index: number): (number?, boolean?, number)
	--[[local negative = false;
	if splitted[index] == "+" then
		index = index + 1;
	elseif splitted[index] == "-" then
		index = index + 1;
		negative = true;
	end]]--
	
	if asciiNum2num[splitted[index]] == nil then
		return nil, nil, index;
	end
	local num = 0;
	local numDecimal = 0;
	local parsingDecimal = false;
	while true do
		local char = splitted[index];
		if char == nil then
			break;
		end
		if table.find(floatBreakCharacters, char) ~= nil then
			break;
		end
		index = index + 1;
		if char == " " or char == "\n" then
			break;
		end
		if (char == "." and parsingDecimal) or (asciiNum2num[char] == nil and char ~= ".") then
			error("Syntax error: Invalid float");
		end
		if char == "." and not parsingDecimal then
			parsingDecimal = true;
			continue;
		end
		local charNum = asciiNum2num[char];
		if parsingDecimal then
			numDecimal = numDecimal * 10 + charNum;
			continue;
		end
		num = num * 10 + charNum;
	end
	if numDecimal ~= 0 then
		num = num + numDecimal / math.pow(10, math.floor(math.log10(numDecimal)) + 1);
		return num, true, index;
	end
	return num, false, index;
end
local function has(haystack: {any}, needle: any): boolean -- table.find is horrible dealing with containing nil tables
	for i=1, #haystack do
		local something = haystack[i];
		if something == needle then
			return true;
		end
	end
	return false;
end
local whiteSpaceCharacters: {string?} = {nil," ","\r","\n"};
local function tokenize_boolean(splitted: {string}, index: number): (boolean?, number)
	if splitted[index + 3] == nil then
		return nil, index;
	end
	local possiblyTrue = splitted[index] .. splitted[index + 1] .. splitted[index + 2] .. splitted[index + 3];
	if possiblyTrue == "TRUE" and has(whiteSpaceCharacters, splitted[index + 5]) then
		return true, index + 4;
	end

	if splitted[index + 5] == nil then
		return nil, index;
	end
	local possiblyFalse = splitted[index] .. splitted[index + 1] .. splitted[index + 2] .. splitted[index + 3] .. splitted[index + 4];
	if possiblyFalse == "FALSE" and has(whiteSpaceCharacters, splitted[index + 5]) then
		return false, index + 5;
	end
	return nil, index;
end
local function tokenize_identifier_or_keyword(splitted: {string}, index: number): (string, boolean, number)
	local something = "";
	local oldIndex = index;
	while true do
		local char = splitted[index];
		if char == nil then
			break;
		end
		if (string.find(char, "%a") ~= 1) and (char ~= "_") then
			break;
		end
		something = something .. char;
		index = index + 1;
	end
	local abc = table.find(common.keywords, something);
	return something, abc ~= nil, index;
end
local function tokenize_operator(splitted: {string}, index: number): (string?, number)
	local sign = "";
	local signTable = {splitted[index], splitted[index + 1]};
	local usedTwoCharacters = false;
	if signTable[1] == "!" and signTable[2] == "=" then
		usedTwoCharacters = true;
		sign = "NEQUAL";
	elseif signTable[1] == ">" and signTable[2] == "=" then
		usedTwoCharacters = true;
		sign = "EGREATHER";
	elseif signTable[1] == "=" and signTable[2] == "=" then
		usedTwoCharacters = true;
		sign = "EQUAL";
	elseif signTable[1] == "<" and signTable[2] == "=" then
		usedTwoCharacters = true;
		sign = "ELESS";
	end

	if usedTwoCharacters then
		return sign, index + 2;
	end

	if signTable[1] == ">" then
		sign = "GREATHER";
	elseif signTable[1] == "=" then
		sign = "DECL";
	elseif signTable[1] == "<" then
		sign = "LESS";
	elseif signTable[1] == "+" then
		sign = "ADD";
	elseif signTable[1] == "-" then
		sign = "SUB";
	elseif signTable[1] == "*" then
		sign = "MUL";
	elseif signTable[1] == "/" then
		sign = "DIV";
	else
		return nil, index;
	end
	return sign, index + 1;
end
local function readLineNumber(splitted: {string}, index: number): (number?, number)
	if asciiNum2num[splitted[index]] == nil then
		return nil, index;
	end
	local num = 0;
	local numDecimal = 0;
	while true do
		local char = splitted[index];
		if char == nil then
			break;
		end
		index = index + 1;
		if char == " " then
			break;
		end
		if asciiNum2num[char] == nil then
			error("Syntax error: Invalid line number");
		end
		local charNum = asciiNum2num[char];
		num = num * 10 + charNum;
	end
	return num, index;
end

export type SeparatorName = string;
export type Literal = {
	literalType: "string" | "integer" | "float" | "boolean";
	value: string | number | boolean;
};
export type Token = {
	type: "literal" | "operator" | "lineBreak" | "separator" | "keyword" | "identifier" | "lineNumber" | "comment";
	operator: string?;
	literal: Literal?;
	separator: SeparatorName?;
	name: string?;
	lineNumber: number?;
};
local function tokenize_scan(str: string): {Token}
	local tokens: {Token} = {};
	local splitted = string.split(str, "");
	local i: number = 1;
	local curLine: number? = nil;
	local lineStart: boolean = true;
	local remMode = false;

	while true do
		local char = splitted[i];
		if char == " " then
			i = i + 1;
			continue;
		end
		if char == nil then
			i = i + 1;
			break;
		end

		-- lineBreak
		if char == "\n" then
			lineStart = true;
			i = i + 1;
			table.insert(tokens, {
				type = "lineBreak"
			});
			continue;
		end
		
		if lineStart then
			lineStart = false;
			local lineNumber, index = readLineNumber(splitted, i);
			if lineNumber == nil then
				continue;
			end
			i = index;
			table.insert(tokens, {
				type = "lineNumber",
				lineNumber = lineNumber
			});
		end

		-- separators
		local sep = findSep(char);
		if sep ~= nil then
			table.insert(tokens, {
				type = "separator",
				separator = sep.name
			});
			i = i + 1;
			continue;
		end
		
		-- float
		local num, isFloat, newIndex = tokenize_float(splitted, i);
		if num ~= nil then
			i = newIndex;
			table.insert(tokens, {
				type = "literal",
				literal = {
					literalType = if isFloat then "float" else "integer",
					value = num
				}
			});
			continue;
		end

		-- operator
		local operator, newIndex = tokenize_operator(splitted, i);
		if operator ~= nil then
			i = newIndex;
			table.insert(tokens, {
				type = "operator",
				operator = operator
			});
			continue;
		end

		-- string
		local str, newIndex = tokenize_string(splitted, i);
		if str ~= nil then
			i = newIndex;
			table.insert(tokens, {
				type = "literal",
				literal = {
					literalType = "string",
					value = str
				}
			});
			continue;
		end

		-- boolean
		local bool, newIndex = tokenize_boolean(splitted, i);
		if bool ~= nil then
			i = newIndex;
			table.insert(tokens, {
				type = "literal",
				literal = {
					literalType = "boolean",
					value = bool
				}
			});
			continue;
		end

		-- identifier
		local something, isKeyword, newIndex = tokenize_identifier_or_keyword(splitted, i);
		i = newIndex;
		if something == "REM" then
			while splitted[i] ~= "\n" do
				if splitted[i] == nil then
					break;
				end
				i = i + 1;
			end
			table.insert(tokens, {
				type = "comment"
			});
			continue;
		end
		if #something > 0 then
			table.insert(tokens, {
				type = if isKeyword then "keyword" else "identifier",
				name = something
			});
		end
	end
	return tokens;
end

return {
	tokenize_identifier_or_keyword = tokenize_identifier_or_keyword,
	tokenize_string = tokenize_string,
	tokenize_boolean = tokenize_boolean,
	tokenize_operator = tokenize_operator,
	tokenize_float = tokenize_float,
	readLineNumber = readLineNumber,
	scan = tokenize_scan
};