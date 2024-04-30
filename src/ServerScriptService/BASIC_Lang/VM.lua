local common = require(script.Parent.Common);
type VirtualType = VirtualString | VirtualNumber | VirtualArray | VirtualBoolean;
type VirtualNumber = {
	type: "number";
	value: number;
};
type VirtualString = {
	type: "string";
	value: string;
};
type VirtualBoolean = {
	type: "boolean";
	value: boolean;
};
type VirtualArray = {
	type: "array";
	value: {
		VirtualType
	};
};
type State = {
	constants: {VirtualString | VirtualNumber | VirtualBoolean};
	registers: {VirtualType};
	bytecode: {number};
	jumpTable: {[number]: number};
	instructionPointer: number;
	halted: boolean;
	writeTerminal: (string) -> nil,
	readTerminal: () -> string;
	debugMode: boolean;
};

local function toBoolean(something: VirtualType): boolean
	if something == nil then
		error("casting null");
		return false;
	end
	if something.type == "boolean" then
		return something.value;
	end
	if something.type == "number" then
		return something.value ~= 0;
	end
	if something.type == "array" or something.type == "string" then
		return (#something.value) > 0;
	end
end
local function toString(something: VirtualType): string
	if something.type == "string" then
		return something.value;
	end
	if something.type == "boolean" then
		return if something.value then "true" else "false";
	end
	if something.type == "number" then
		return tostring(something.value);
	end
	if something.type == "array" then
		return `<ARRAY: {#something.value} ELEMENTS>`;
	end
end

local function readUint16(state: State): number
	state.instructionPointer = state.instructionPointer + 1;
	local num1 = state.bytecode[state.instructionPointer];
	state.instructionPointer = state.instructionPointer + 1;
	local num2 = state.bytecode[state.instructionPointer];
	return bit32.bor((bit32.rshift(num1, 8)), num2);
end
local function readUint32(state: State): number
	local num1 = readUint16(state);
	local num2 = readUint16(state);
	return bit32.bor(bit32.lshift(num1, 16), num2);
end
local function checkType(state: State, register: number, typeToCheck: "string" | "number" | "array" | "boolean"): ()
	if state.registers[register] == nil then
		error("Value is nil");
	end
	if state.registers[register].type ~= typeToCheck then
		error(`Expected {typeToCheck} received {state.registers[register].type}`);
	end
end
local bytecodeInstructions = {
	function(state: State): () -- END
		state.halted = true;
	end,
	function(state: State): () -- CLONE_CONST
		local constIndex = readUint32(state) + 1;
		local registerIndex = readUint32(state) + 1;
		state.registers[registerIndex] = state.constants[constIndex];
	end,
	function(state: State): () -- COPY_REG
		local oldRegisterIndex = readUint32(state) + 1;
		local newRegisterIndex = readUint32(state) + 1;
		state.registers[newRegisterIndex] = state.registers[oldRegisterIndex];
	end,
	function(state: State): () -- JUMP
		local newIP = readUint32(state);
		state.instructionPointer = state.jumpTable[newIP];
	end,
	function(state: State): () -- IFJUMP
		local registerIndex = readUint32(state) + 1;
		local newIP = readUint32(state);
		if toBoolean(state.registers[registerIndex]) then
			state.instructionPointer = state.jumpTable[newIP];
		end
	end,
	function(state: State): () -- --PRINT-- NOOP
		--[[local howMany = readUint32(state);
		for i=1, howMany do
			local registerIndex = readUint32(state) + 1;
			state.writeTerminal(toString(state.registers[registerIndex]));
			state.writeTerminal(" ");
		end
		state.writeTerminal("\n");]]--
	end,
	function(state: State): () -- INPUT
		local stringReigister = readUint32(state) + 1;
		local outputRegister = readUint32(state) + 1;
		checkType(state, stringReigister, "string");
		state.writeTerminal(toString(state.registers[stringReigister]));
		local str = {};
		repeat
			local char = state.readTerminal();
			table.insert(str, char);
			state.writeTerminal(char);
		until char == "\n";
		table.remove(str, #str);
		state.registers[outputRegister] = {
			type = "string",
			value = table.concat(str, "")
		};
	end,
	function(state: State): () -- WRITE
		local arrayRegister = readUint32(state) + 1;
		local indexRegister = readUint32(state) + 1;
		local valueRegister = readUint32(state) + 1;
		checkType(state, arrayRegister, "array");
		checkType(state, indexRegister, "number");
		state.registers[arrayRegister].value[state.registers[indexRegister].value - 1] = state.registers[valueRegister];
	end,
	
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		state.registers[register3] = {
			type = "number",
			value = state.registers[register1].value + state.registers[register2].value
		};
	end,
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		state.registers[register3] = {
			type = "number",
			value = state.registers[register1].value - state.registers[register2].value
		};
	end,
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		state.registers[register3] = {
			type = "number",
			value = state.registers[register1].value * state.registers[register2].value
		};
	end,
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		state.registers[register3] = {
			type = "number",
			value = state.registers[register1].value / state.registers[register2].value
		};
	end,
	
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		state.registers[register2] = {
			type = "boolean",
			value = not toBoolean(state.registers[register1])
		};
	end,
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		state.registers[register3] = {
			type = "boolean",
			value = state.registers[register1].value == state.registers[register2].value
		};
	end,
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "boolean",
			value = state.registers[register1].value > state.registers[register2].value
		};
	end,
	function(state: State): ()
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "boolean",
			value = state.registers[register1].value < state.registers[register2].value
		};
	end,
	function(state: State): () -- IAND
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "number",
			value = bit32.band(math.floor(state.registers[register1].value), math.floor(state.registers[register2].value))
		};
	end,
	function(state: State): () -- IOR
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "number",
			value = bit32.bor(math.floor(state.registers[register1].value), math.floor(state.registers[register2].value))
		};
	end,
	function(state: State): () -- IXOR
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "number",
			value = bit32.bxor(math.floor(state.registers[register1].value), math.floor(state.registers[register2].value))
		};
	end,
	function(state: State): () -- MOD
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "number",
			value = state.registers[register1].value % state.registers[register2].value
		};
	end,
	
	function(state: State): () -- SQRT
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		checkType(state, register1, "number");
		state.registers[register2] = {
			type = "number",
			value = math.sqrt(state.registers[register1].value)
		};
	end,

	function(state: State): () -- POW
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		checkType(state, register1, "number");
		checkType(state, register2, "number");
		state.registers[register3] = {
			type = "number",
			value = state.registers[register1].value ^ state.registers[register2].value
		};
	end,
	
	function(state: State): () -- CEIL
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		checkType(state, register1, "number");
		state.registers[register2] = {
			type = "number",
			value = math.ceil(state.registers[register1].value)
		};
	end,
	function(state: State): () -- ROUND
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		checkType(state, register1, "number");
		state.registers[register2] = {
			type = "number",
			value = math.round(state.registers[register1].value)
		};
	end,
	function(state: State): () -- LEN
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local length;
		local registerValue = state.registers[register1];
		if registerValue.type == "boolean" then
			error("Expected number or string or array");
		elseif registerValue.type == "string" or registerValue.type == "array" then
			length = #registerValue.value;
		elseif registerValue.type == "number" then
			length = math.abs(registerValue);
		end
		
		state.registers[register2] = {
			type = "number",
			value = length
		};
	end,
	function(state: State): () -- CONCAT
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local register3 = readUint32(state) + 1;
		
		local register1Value = state.registers[register1];
		local register2Value = state.registers[register2];
		if register1Value.type ~= register2Value.type then
			error("Incompatible types. Both concat argument 1 and 2 needs to be a string or array");
		end
		if register1Value.type == "string" then
			state.registers[register3] = {
				type = "string",
				value = register1Value.value .. register2Value.value
			};
		elseif register1Value.type == "array" then
			state.registers[register3] = {
				type = "array",
				value = {table.unpack(register1Value.value), table.unpack(register2Value.value)}
			};
		else
			error("Incompatible types. Both concat argument 1 and 2 needs to be a string or array");
		end
	end,
	function(state: State) -- OUTPUT
		local register = readUint32(state) + 1;
		state.writeTerminal(toString(state.registers[register]));
	end,
	function(state: State) -- VAL
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local r1 = state.registers[register1];
		if r1.type == "string" then
			local newValue = tonumber(r1.value);
			assert(newValue ~= nil, "error converting");
			state.registers[register2] = {
				type = "number",
				value = newValue
			};
		elseif r1.type == "boolean" then
			state.registers[register2] = {
				type = "number",
				value = if r1.value then 1 else 0
			};
		elseif r1.type == "number" then
			state.registers[register2] = {
				type = "number",
				value = r1.value
			};
		else
			error("Expected string | number | boolean");
		end
	end,
	function(state: State) -- CREATE_ARRAY
		local register = readUint32(state) + 1;
		state.registers[register] = {
			type = "array",
			value = {};
		};
	end,
	function(state: State) -- ARR_READ
		local arrayRegister = readUint32(state) + 1;
		local indexRegister = readUint32(state) + 1;
		local resultRegister = readUint32(state) + 1;
		checkType(state, arrayRegister, "array");
		checkType(state, indexRegister, "number");
		local index = state.registers[indexRegister];
		local realIndex = math.floor(index.value);
		assert(realIndex >= 0, "Expected index to be a value greather than or equal than zero");
		local array = state.registers[arrayRegister];
		local result = array.value[realIndex];
		assert(result ~= nil, "Expected any type. Received nothing");
		state.registers[resultRegister] = {
			type = result.type,
			value = result.value
		};
	end,
	function(state: State) -- VALUE_EXISTS
		local arrayRegister = readUint32(state) + 1;
		local indexRegister = readUint32(state) + 1;
		local resultRegister = readUint32(state) + 1;
		checkType(state, arrayRegister, "array");
		checkType(state, indexRegister, "number");
		local index = state.registers[indexRegister];
		local realIndex = math.floor(index.value);
		assert(realIndex >= 0, "Expected index to be a value greather than or equal than zero");
		local array = state.registers[arrayRegister];
		local result = array.value[realIndex];
		state.registers[resultRegister] = {
			type = "boolean",
			value = result ~= nil
		};
	end,
	function(state: State) -- CHAR
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		checkType(state, register1, "number");
		local r1 = state.registers[register1];
		state.registers[register2] = {
			type = "string",
			value = string.char(bit32.band(math.abs(r1.value), 255))
		};
	end,
	function(state: State) -- SWAP
		local register1 = readUint32(state) + 1;
		local register2 = readUint32(state) + 1;
		local r1 = state.registers[register1];
		local r2 = state.registers[register2];
		state.registers[register1] = {
			type = r2.type,
			value = r2.value
		};
		state.registers[register2] = {
			type = r1.type,
			value = r1.value
		};
	end,
	function(state: State) -- OFFSET_IF
		local registerIndex = readUint32(state) + 1;
		local newIP = readUint32(state);
		if toBoolean(state.registers[registerIndex]) then
			state.instructionPointer += newIP;
		end
	end,
	function(state: State) -- OFFSET_GOTO
		local newIP = readUint32(state);
		state.instructionPointer += newIP;
	end,
	function(state: State) -- OFFSETTED_GOTO
		local newIP = readUint32(state);
		local offsetIP = readUint32(state);
		state.instructionPointer = state.jumpTable[newIP] + offsetIP;
	end,
	function(state: State) -- NEGATE
		local registerIndex = readUint32(state) + 1;
		local outputRegister = readUint32(state) + 1;
		checkType(state, registerIndex, "number");
		state.registers[outputRegister] = {
			type = "number",
			value = -state.registers[registerIndex].value
		};
	end,
};
local module = {};
function module.createState(bytecode: {number}, constants: {VirtualString | VirtualNumber | VirtualBoolean}, jumpTable: {[number]: number}, writeTerminal: (string) -> nil, readTerminal: () -> string, debugMode: boolean): State
	return {
		halted = false,
		constants = constants,
		registers = {},
		jumpTable = jumpTable,
		bytecode = bytecode,
		instructionPointer = 0,
		writeTerminal = writeTerminal,
		readTerminal = readTerminal,
		debugMode = debugMode
	};
end
function module.runState(state: State): ()
	while not state.halted do
		task.wait(.05);
		state.instructionPointer = state.instructionPointer + 1;
		local bytecodeInstruction = (state.bytecode[state.instructionPointer] or 0) + 1;
		if state.debugMode then
			print(`Running: {common.bytecodeInstructions[bytecodeInstruction]} (bytecode index: {state.instructionPointer - 1})`);
		end
		bytecodeInstructions[bytecodeInstruction](state);
	end
end
return module;