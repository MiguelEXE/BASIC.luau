--[[
variable: [A-Za-z0-9_] (cannot start with number)

instructions: needs to end with ;
LET <variable>=<any>;
FOR <variable>=<integer> TO <integer> [STEP <integer>]; <...instruction>;
NEXT <variable>;
GOTO <integer>;
PRINT <...any>;
IF <boolean> THENGOTO <integer>
INPUT <variable>, <string>;
internal_routine(<...any>);
RUN (only will run on REPL mode)
WRITE <any> TO <variable> IN <operation>;

syntax:
when declaring variables (in FOR or LET) the space between the variable and the integer is optional
when using operators, the space between the argument 1 and argument 2 is optional
REPL = Read, Eval, Print, Loop (Read input from user, Eval/Execute the given input, Print the result if needed, Loop to the Read input section)

internal routines/functions:
VAL(<string>): <number> => Tries to convert the string to a number
POW(<number 1>, <number 2>): <number> => Calculates number 1 ^ number 2
SQRT(<number>): <number> => SQuare RooT
MOD(<number>,<number>): <number> => Modular arithmetic operation (rest of division)
LEN(<string | array>): <integer> => Length of a string or array
FLOOR(<number>): <integer> => Floor of a number
CEIL(<number>): <integer> => Ceil of a number
ROUND(<number>): <integer> => Round of a number
CHAR(<...integer>): <string> => Converts 1 or many ASCII character codes to string
IAND(<integer 1>, <integer 2>): <integer> => Calculates a integer AND with integer 1 and integer 2
IOR(<integer 1>, <integer 2>): <integer> => Calculates a integer OR with integer 1 and integer 2
IXOR(<integer 1>, <integer 2>): <integer> => Calculates a integer XOR with integer 1 and integer 2
CONCAT(<string 1>, <string 2>): <string> => Concat two strings
CREATE_ARRAY(): <array> => Creates a array
ARR_READ(<array | string>, <integer>): <any> => Reads <integer> index in the array/string and returns <any (or string if array is a string)>, errors if trying to read a value that is null
VALUE_EXISTS(<array>, <integer>): <boolean> => Reads <integer> index in the array and returns <boolean> if the value is not null

literal types:
boolean => FALSE or TRUE
float => a number which CAN HAVE the decimal separation (.) which means the decimals. Example: 103.2, 103.84
integer => a number which DOESN'T have the decimal separation. Example: 103, 204
string => "text" or 'text'
any: number | string | boolean;

operators:
<number 1> < <number 2>: <boolean> => Checks if number 1 is less than number 2
<number 2> > <number 2>: <boolean> => Checks if number 1 is greather than number 2
<any 1> == <any 2>: <boolean> => Checks if any 1 is equal than any 2
For strings: Compare if the length and all the characters in the string is equal.
<any 1> != <any 2>: <boolean> => Checks if any 1 is NOT equal than any 2
<number 1> <= <number 2>: <boolean> => Checks if number 1 is equal or less than number 2
<number 1> >= <number 2>: <boolean> => Checks if number 1 is equal or greather than number 2
<number 1> + <number 2>: <number> => Adds number 1 with number 2
<number 2> - <number 2>: <number> => Subs number 1 to number 2
<number 1> * <number 2>: <number> => Multiplies number 1 with number 2
<number 1> / <number 2>: <number> => Divides number 1 to number 2
! <boolean>: <boolean> => Negates a boolean value
<variable> = <any> => Declares variable to be any

float numbers is represented with fixed-point arithmetic
integers is a 16-bit signed integers

numbered instruction:
<integer> <instruction>

bytecode:
LOADCONST <32 bit signed non integer>
GOTO <32 bit unsigned>
IFGOTO <32 bit unsigned>
ADD
SUB
MUL
DIV
POW
SQRT
CONCAT
LEN
CEIL
ROUND
FLOOR == IAND | IOR
IAND
IOR
IXOR
MOD
NARR (New array)
WARR (Write array)
RARR (Read array)

NOT
LESS
GREATHER
ELESS		== NOT GREATHER
EGREATHER 	== NOT LESS
EQUAL
NEQUAL		== NOT EQUAL

]]--