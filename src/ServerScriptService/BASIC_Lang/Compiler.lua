local module = {};
local parser = require(script.Parent.Parser);

type Constant = {
	type: "number" | "boolean" | "number",
	value: string | boolean | number
};

local function writeUint32(value: number, bytecode: {number})
	local num24 = bit32.rshift(value, 24);
	local num16 = bit32.band(bit32.rshift(value, 16), 255);
	local num8 = bit32.band(bit32.rshift(value, 8), 255);
	local num = bit32.band(value, 255);
	table.insert(bytecode, num24);
	table.insert(bytecode, num16);
	table.insert(bytecode, num8);
	table.insert(bytecode, num);
end
local function rewriteUint32(value: number, bytecode: {number}, index: number)
	local num24 = bit32.rshift(value, 24);
	local num16 = bit32.band(bit32.rshift(value, 16), 255);
	local num8 = bit32.band(bit32.rshift(value, 8), 255);
	local num = bit32.band(value, 255);
	bytecode[index] = num24;
	bytecode[index + 1] = num16;
	bytecode[index + 2] = num8;
	bytecode[index + 3] = num;
end
local function copyConstant2buf(index, bytecode)
	table.insert(bytecode, 1);
	writeUint32(index, bytecode);
	writeUint32(2, bytecode);
end
local function copyRegister(from, to, bytecode)
	table.insert(bytecode, 2);
	writeUint32(from, bytecode);
	writeUint32(to, bytecode);
end

local function convert2constantType(typeString)
	if typeString == "integer" or typeString == "float" then
		return "number";
	end
	return typeString;
end
local function allocateOrFindVariable(variableTable: {[number]: string}, variableName: string): number
	local variableRegister = table.find(variableTable, variableName);
	if variableRegister ~= nil then
		return variableRegister;
	end
	variableRegister = #variableTable + 1;
	variableTable[variableRegister] = variableName;
	return variableRegister;
end
function compileOperation(operation: number, expression, bytecode: {number}, constants: {Constant}, variableTable: {[number]: string})
	module.compileExpression(expression.left, bytecode, constants, variableTable);
	copyRegister(2, 0, bytecode);
	module.compileExpression(expression.right, bytecode, constants, variableTable);
	copyRegister(2, 1, bytecode);
	table.insert(bytecode, operation);
	writeUint32(0, bytecode);
	writeUint32(1, bytecode);
	writeUint32(2, bytecode);
end
function module.compileFunction(functionName: string, arguments, bytecode: {number}, constants: {Constant}, variableTable: {[number]: string})
	if functionName == "IAND" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 16);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "IOR" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 17);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "IXOR" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 18);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "MOD" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 19);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "SQRT" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		table.insert(bytecode, 20);
		writeUint32(0, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "POW" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 21);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "CEIL" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		table.insert(bytecode, 22);
		writeUint32(0, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "ROUND" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		table.insert(bytecode, 23);
		writeUint32(0, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "LEN" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		table.insert(bytecode, 24);
		writeUint32(0, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "FLOOR" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		copyRegister(0, 1, bytecode);
		table.insert(bytecode, 16);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "CONCAT" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 25);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "VAL" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		table.insert(bytecode, 27);
		writeUint32(0, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "CREATE_ARRAY" then
		table.insert(bytecode, 28);
		writeUint32(2, bytecode);
	elseif functionName == "ARR_READ" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		module.compileExpression(arguments[2], bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		table.insert(bytecode, 29);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "VALUE_EXISTS" then
		module.compileExpression(arguments[1], bytecode, constants, variableTable);
		copyRegister(2, 0, bytecode);
		table.insert(bytecode, 30);
		writeUint32(0, bytecode);
		writeUint32(2, bytecode);
	elseif functionName == "CHAR" then
		for i,argument in ipairs(arguments) do
			module.compileExpression(argument, bytecode, constants, variableTable);
			copyRegister(2, 0, bytecode);
			table.insert(bytecode, 31);
			writeUint32(0, bytecode);
			writeUint32(1, bytecode);
			if i == 1 then
				table.insert(bytecode, 1);
				writeUint32(0, bytecode);
				writeUint32(0, bytecode);
			else
				copyRegister(3, 0, bytecode);
			end
			table.insert(bytecode, 25);
			writeUint32(0, bytecode);
			writeUint32(1, bytecode);
			writeUint32(3, bytecode);
		end
		copyRegister(3, 2, bytecode);
	end
end
function module.compileExpression(expression, bytecode: {number}, constants: {Constant}, variableTable: {[number]: string}): {number}
	if expression.type == "literal" then
		copyConstant2buf(#constants, bytecode);
		table.insert(constants, {
			type = convert2constantType(expression.literal.literalType),
			value = expression.literal.value
		} :: Constant);
	elseif expression.type == "identifier" then
		local register = table.find(variableTable, expression.name);
		if register == nil then
			error(`Compiler error: Variable '{expression.name}' is not declared.`);
		end
		copyRegister(register, 2, bytecode);
	elseif expression.operator == "ADD" then
		compileOperation(8, expression, bytecode, constants, variableTable);
	elseif expression.operator == "SUB" then
		compileOperation(9, expression, bytecode, constants, variableTable);
	elseif expression.operator == "MUL" then
		compileOperation(10, expression, bytecode, constants, variableTable);
	elseif expression.operator == "DIV" then
		compileOperation(11, expression, bytecode, constants, variableTable);
	elseif expression.operator == "EQUAL" then
		compileOperation(13, expression, bytecode, constants, variableTable);
	elseif expression.operator == "NEQUAL" then
		compileOperation(13, expression, bytecode, constants, variableTable);
		table.insert(bytecode, 12);
		writeUint32(2, bytecode);
		writeUint32(2, bytecode);
	elseif expression.operator == "GREATHER" then
		compileOperation(14, expression, bytecode, constants, variableTable);
	elseif expression.operator == "ELESS" then
		compileOperation(14, expression, bytecode, constants, variableTable);
		table.insert(bytecode, 12);
		writeUint32(2, bytecode);
		writeUint32(2, bytecode);
	elseif expression.operator == "LESS" then
		compileOperation(15, expression, bytecode, constants, variableTable);
	elseif expression.operator == "EGREATHER" then
		compileOperation(15, expression, bytecode, constants, variableTable);
		table.insert(bytecode, 12);
		writeUint32(2, bytecode);
		writeUint32(2, bytecode);
	elseif expression.type == "functionCall" then
		module.compileFunction(expression.name, expression.arguments, bytecode, constants, variableTable);
	elseif expression.operator == "NEGATIVE" then
		module.compileExpression(expression.expression, bytecode, constants, variableTable);
		table.insert(bytecode, 36);
		writeUint32(2, bytecode);
		writeUint32(2, bytecode);
	elseif expression.operator == "POSITIVE" then
		module.compileExpression(expression.expression, bytecode, constants, variableTable);
	end
end

function module.compileInstruction(instruction, constants: {Constant}, variableTable: {[number]: string}): ({number}, any?)
	local bytecode: {number} = {};
	if instruction.instruction == "GOTO" then
		table.insert(bytecode, 3);
		writeUint32(instruction.line, bytecode);
		return bytecode, {
			type = "jumpTableProcess",
			lineNumber = instruction.line
		};
	elseif instruction.instruction == "IF" then
		module.compileExpression(instruction.operation, bytecode, constants, variableTable);
		table.insert(bytecode, 4);
		writeUint32(2, bytecode);
		writeUint32(instruction.thenGotoLine, bytecode);
		return bytecode, {
			type = "jumpTableProcess",
			lineNumber = instruction.thenGotoLine,
		};
	elseif instruction.instruction == "END" then
		table.insert(bytecode, 0);
	elseif instruction.instruction == "PRINT" then
		for _,operation in ipairs(instruction.operations) do
			module.compileExpression(operation, bytecode, constants, variableTable);
			table.insert(bytecode, 26);
			writeUint32(2, bytecode);
		end
	elseif instruction.instruction == "LET" then
		module.compileExpression(instruction.value, bytecode, constants, variableTable);
		local variableRegister = allocateOrFindVariable(variableTable, instruction.identifier);
		table.insert(bytecode, 2);
		writeUint32(2, bytecode);
		writeUint32(variableRegister, bytecode);
	elseif instruction.instruction == "WRITE" then
		module.compileExpression(instruction.operation, bytecode, constants, variableTable);
		copyRegister(2, 3, bytecode);
		module.compileExpression(instruction.index, bytecode, constants, variableTable);
		copyRegister(2, 1, bytecode);
		copyRegister(3, 2, bytecode);
		local register = table.find(variableTable, instruction.variable);
		if register == nil then
			error(`Compiler error: Variable '{instruction.variable}' is not declared.`);
		end
		copyRegister(register, 0, bytecode);
		table.insert(bytecode, 7);
		writeUint32(0, bytecode);
		writeUint32(1, bytecode);
		writeUint32(2, bytecode);
	elseif instruction.instruction == "INPUT" then
		module.compileExpression(instruction.operation, bytecode, constants, variableTable);
		local variableRegister = allocateOrFindVariable(variableTable, instruction.variableName);
		table.insert(bytecode, 6);
		writeUint32(2, bytecode);
		writeUint32(variableRegister, bytecode);
	elseif instruction.instruction == "FOR" then
		-- Variable initialization
		local forVariable = allocateOrFindVariable(variableTable, instruction.variableName);
		local forEndVariable = allocateOrFindVariable(variableTable, instruction.variableName .. "\0END");
		local forStepVariable = allocateOrFindVariable(variableTable, instruction.variableName .. "\0STEP");
		module.compileExpression(instruction.startingValue, bytecode, constants, variableTable);
		copyRegister(2, forVariable, bytecode);
		module.compileExpression(instruction.to, bytecode, constants, variableTable);
		copyRegister(2, forEndVariable, bytecode);
		if instruction.step == nil then
			copyConstant2buf(#constants, bytecode);
			table.insert(constants, {
				type = "number",
				value = 1
			} :: Constant);
		else
			module.compileExpression(instruction.step, bytecode, constants, variableTable);
		end
		copyRegister(2, forStepVariable, bytecode);
		
		-- Loop
		local loopStart = #bytecode;
		
		-- IF I_STEP < 0 THENGOTO 18;
		copyConstant2buf(1, bytecode);
		table.insert(bytecode, 15);
		writeUint32(forStepVariable, bytecode);
		writeUint32(2, bytecode);
		writeUint32(2, bytecode);
		table.insert(bytecode, 33);
		writeUint32(2, bytecode);
		writeUint32(27, bytecode);
		-- IF I > I_END THENGOTO 40;
		table.insert(bytecode, 14);
		writeUint32(forVariable, bytecode);
		writeUint32(forEndVariable, bytecode);
		writeUint32(2, bytecode);
		table.insert(bytecode, 4);
		writeUint32(2, bytecode);
		writeUint32(0xFFFF, bytecode);
		local replaceEnd = #bytecode - 3;
		-- GOTO 20;
		table.insert(bytecode, 34);
		writeUint32(22, bytecode);
		-- IF I < I_END THENGOTO 40;
		table.insert(bytecode, 15);
		writeUint32(forVariable, bytecode);
		writeUint32(forEndVariable, bytecode);
		writeUint32(2, bytecode);
		table.insert(bytecode, 4);
		writeUint32(2, bytecode);
		writeUint32(0xFFFF, bytecode);
		local replaceOtherEnd = #bytecode - 3;
		return bytecode, {
			type = "forProcess",
			loopStart = loopStart,
			replaceEnd = replaceEnd,
			replaceOtherEnd = replaceOtherEnd,
			variable = instruction.variableName
		};
		
	elseif instruction.instruction == "NEXT" then
		local forVariableRegister = table.find(variableTable, instruction.variable);
		local forStepVariableRegister = table.find(variableTable, instruction.variable .. "\0STEP");
		assert(forVariableRegister ~= nil, `Variable '{instruction.variable}' not defined.`);
		assert(forStepVariableRegister ~= nil, `Variable '{instruction.variable}' not used in a FOR loop.`);
		table.insert(bytecode, 8);
		writeUint32(forVariableRegister, bytecode);
		writeUint32(forStepVariableRegister, bytecode);
		writeUint32(forVariableRegister, bytecode);
		table.insert(bytecode, 35);
		writeUint32(0xFFFF, bytecode);
		local jumpTableIndex = #bytecode - 3;
		writeUint32(0xFFFF, bytecode);
		local offset = #bytecode - 3;
		return bytecode, {
			type = "linkNext",
			variable = instruction.variable,
			jumpTableIndex = jumpTableIndex,
			offset = offset
		};
	else
		warn(`Unknown instruction "{instruction.instruction}"`);
	end	
	
	return bytecode;
end
local function countUntilLine(compiled: {{number}}, lineNumber: number): number
	local offset = 0;
	local keysSorted = {};
	for line in pairs(compiled) do
		if line == "noLine" then
			continue;
		end
		table.insert(keysSorted, line);
	end
	table.sort(keysSorted);
	for _,key in ipairs(keysSorted) do
		if key >= lineNumber then
			break;
		end
		offset += #(compiled[key]);
	end
	return offset;
end
local function countAfterLine(compiled: {{number}}, lineNumber: number): (number, number)
	local offset = 0;
	local keysSorted = {};
	for line in pairs(compiled) do
		if line == "noLine" then
			continue;
		end
		table.insert(keysSorted, line);
	end
	table.sort(keysSorted);
	local lastKnownLineNumber: number;
	local afterLineNumber: number;
	for _,key in ipairs(keysSorted) do
		if key > lineNumber then
			afterLineNumber = lineNumber;
			break;
		end
		lastKnownLineNumber = key;
		offset += #(compiled[key]);
	end
	if afterLineNumber == nil then
		afterLineNumber = lastKnownLineNumber + 1;
	end
	return offset, afterLineNumber;
end
local function findFor(instructions: {{number}}, startingLine: number, variableName: string): number
	local lineNumber: number?;
	local keysSorted = {};
	for line in pairs(instructions) do
		if line == "noLine" then
			continue;
		end
		table.insert(keysSorted, line);
	end
	table.sort(keysSorted);
	local startingLineIndex = table.find(keysSorted, startingLine);
	assert(startingLineIndex ~= nil, "Cannot find NEXT current line");
	for i=startingLineIndex, 1, -1 do
		local line = keysSorted[i];
		local instruction = instructions[line];
		if instruction.instruction == "FOR" and instruction.variableName == variableName then
			lineNumber = line;
			break;
		end
	end
	assert(lineNumber ~= nil, "Expected FOR instruction");
	return lineNumber;
end

local function getNextLine(instructions, variableName: string, startingLine: number)
	local keySorted = {};
	for index in pairs(instructions) do
		if index == "noLine" then
			continue;
		end
		table.insert(keySorted, index);
	end
	table.sort(keySorted);
	while true do
		if keySorted[1] > startingLine then
			break;
		end
		table.remove(keySorted, 1);
	end
	local lineNumber = {};
	for _,key in ipairs(keySorted) do
		local instruction = instructions[key];
		if instruction.instruction == "NEXT" and instruction.variable == variableName then
			table.insert(lineNumber, key);
		elseif instruction.instruction == "FOR" and instruction.variableName == variableName then
			break;
		end
	end
	assert(lineNumber[1] ~= nil, "Expected NEXT instruction");
	local lastNextLine = lineNumber[#lineNumber];
	local index = table.find(keySorted, lastNextLine);
	assert(index ~= nil, "NEXT instruction must be found in the instructions table");
	return lastNextLine;
end

function module.compile(instructions): ({number}, {Constant}, {[number]: {number}})
	local compiled: {{number}} = {};
	local constants: {Constant} = {{type = "string", value = ""},{type = "number", value = 0}};
	local jumpTable: {[number]: number} = {};
	local variableTable = {"","","",""};
	local infos = {};
	local forTable = {};
	
	local keySorted = {};
	for index in pairs(instructions) do
		if index == "noLine" then
			continue;
		end
		table.insert(keySorted, index);
	end
	table.sort(keySorted);
	
	for i,key in ipairs(keySorted) do -- compile
		local bytecode, info = module.compileInstruction(instructions[key], constants, variableTable);
		if info ~= nil then
			info.__lineNumber = key;
			infos[i] = info;
		else
			infos[i] = "abcd";
		end
		compiled[key] = bytecode;
	end
	for _,info in ipairs(infos) do -- postcompile
		if info == "abcd" then
			continue;
		end
		if info.type == "jumpTableProcess" then
			jumpTable[info.lineNumber] = countUntilLine(compiled, info.lineNumber);
		elseif info.type == "forProcess" then
			local lineNumber = getNextLine(instructions, info.variable, info.__lineNumber);
			local afterNext, afterLineNumber = countAfterLine(compiled, lineNumber);
			jumpTable[afterLineNumber] = afterNext;
			rewriteUint32(afterLineNumber, compiled[info.__lineNumber], info.replaceEnd);
			rewriteUint32(afterLineNumber, compiled[info.__lineNumber], info.replaceOtherEnd);
		elseif info.type == "linkNext" then
			local forLineNumber = findFor(instructions, info.__lineNumber, info.variable);
			local infoFor = infos[table.find(keySorted, forLineNumber)];
			jumpTable[forLineNumber] = countUntilLine(compiled, forLineNumber);
			rewriteUint32(forLineNumber, compiled[info.__lineNumber], info.jumpTableIndex);
			rewriteUint32(infoFor.loopStart, compiled[info.__lineNumber], info.offset);
		end
	end
	local bytecode = {};
	for _,key in ipairs(keySorted) do -- join
		for _,instruction in ipairs(compiled[key]) do
			table.insert(bytecode, instruction);
		end
	end
	return bytecode, constants, jumpTable;
end

return module;