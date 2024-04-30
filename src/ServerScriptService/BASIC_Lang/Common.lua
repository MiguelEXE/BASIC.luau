--!strict
export type Separator = {
	name: string;
	separator: string
};
local separators: {Separator} = {
	{
		name = "EINSTR", -- End INSTRuction
		separator = ";"
	},
	{
		name = "ACONT", -- Argument CONTinuation
		separator = ","
	},
	{
		name = "OBRACK", -- Open BRACKets
		separator = "("
	},
	{
		name = "CBRACK", -- Closed Brackets
		separator = ")"
	}
};
local operatorTypes: {[string]: "integer" | "float" | "string" | "boolean" | "any"} = {
	["LESS"] = "float",
	["GREATHER"] = "float",
	["EGREATHER"] = "float",
	["ELESS"] = "float",

	["EQUAL"] = "any",
	["NEQUAL"] = "any",

	["ADD"] = "float",
	["SUB"] = "float",
	["MUL"] = "float",
	["DIV"] = "float"
};
local functionNames = {"POW", "SQRT", "CONCAT", "MOD", "LEN", "VAL", "FLOOR", "CEIL", "ROUND", "CHAR", "IAND", "IOR", "IXOR", "CREATE_ARRAY", "READ_ARRAY", "VALUE_EXISTS"};
local keywords = {
	"LET", "IF", "GOTO", "THENGOTO", "STEP", "PRINT", "FOR", "TO", "NEXT", "INPUT", "RUN", "WRITE", "END", "IN",
	table.unpack(functionNames)
};
local bytecodeInstructions = {
	"END",
	"CLONE_CONST",
	"MOVE",
	"JUMP",
	"IFJUMP",
	"PRINT",
	"INPUT",
	"WRITE",
	
	"ADD",
	"SUB",
	"MUL",
	"DIV",
	
	"NOT",
	"EQUAL",
	"GREATHER",
	"LESS",
	
	"IAND",
	"IOR",
	"IXOR",
	
	"MOD",
	"SQRT",
	"POW",
	"CEIL",
	"ROUND",
	"LEN",
	"CONCAT",
	"OUTPUT",
	"VAL",
	
	"CREATE_ARRAY",
	"ARR_READ",
	"VALUE_EXISTS",
	
	"CHAR",
	"SWAP",
	
	"OFFSET_IF",
	"OFFSET_GOTO",
	"OFFSETTED_GOTO",
	"NEGATE"
};

return {
	keywords 				= keywords,
	functionNames			= functionNames,
	separators 				= separators,
	operatorTypes 			= operatorTypes,
	bytecodeInstructions	= bytecodeInstructions,
};