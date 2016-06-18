grammar Rose;

options {
	language = Java;
}

@header {
	import java.util.*;
	import java.io.*;                                                                                                                                 
}

@members {
	private boolean debug = true;
	private int reg = 0;
	private int label = 0;

	private int getReg() {
		return reg++;
	}

	private int putReg() {
		return reg--;
	}

	private int newLabel() {
		return label++;
	}
}


program : 
	PROCEDURE
	Identifier
	IS
		{ System.out.println(".data"); }
	DECLARE
	variables
		{ System.out.println(".main"); }
	BEGIN
	statements
		{ System.out.println("exit"); }
	END
	SEMI;

PROCEDURE: 'procedure';

Identifier
  : ( Uppercase
      | '_'
    )
    ( Uppercase
      | '_'
      | Digit
    )*
;

IS: 'is';
DECLARE: 'declare';
BEGIN: 'begin';
END: 'end';
SEMI: ';';

variables: variables2;
variables2: variable variables2
|
;

variable : Identifier ':' 'integer' ';' 
	{
		System.out.println($Identifier.text + " : \t .word \t 0");
	}
;

statements: statements2;
statements2: statement statements2
|
;

statement : assignment_statement
| if_statement
| for_statement
| exit_statement
| read_statement
| write_statement
;

assignment_statement : Identifier ':=' temp2 = arith_expression ';'
	{
		int temp1 = getReg();
		if(debug)	System.out.println("#---ASS");
		System.out.println("la\t\$t" + temp1 + ", " + $Identifier.text);
		System.out.println("sw\t\$t" + $temp2.Eplace + ", 0(\$t" + temp1 + ")");
		putReg();
		putReg();
	}
;


if_statement : 
	'if'
		{
			int Etrue = newLabel();
			int Efalse = newLabel();
		}
	bool_expression 'then' 
		{
			System.out.println("\nL" + Etrue + ":");
		}
	statements 
		{
			System.out.println("\nL" + Efalse + ":");
		}
	'end' 'if' ';'

	| 'if' 
		{
			int Etrue = newLabel();
			int Efalse = newLabel();
			int Enext = newLabel();
		}
	
	bool_expression 'then' 
		{
			System.out.println("\nL" + Etrue + ":");
		}
	
	statements 'else' 
		{
			System.out.println("\nj L" + Enext + ":");
			System.out.println("\nL" + Efalse + ":");
		}
	
	statements 
	'end' 'if' ';'
		{
			System.out.println("\nL" + Enext + ":");
		}
;

for_statement :
'for' Identifier 'in' arith_expression '..' arith_expression 'loop' statements 'end' 'loop' ';'
;

exit_statement : 
	'exit' ';'
	{
		System.out.println("li\t\$v0, 10");
		System.out.println("syscall");
	}
;

read_statement : 'read' Identifier ';'
	{
	    System.out.println("li\t\$v0, 5");
    	System.out.println("syscall");
   		int temp = getReg();
	    System.out.println("la\t\$t" + temp + ", " + $Identifier.text);
    	System.out.println("sw\t\$v0, 0(\$t" + temp + ")");
	    putReg();
	}
;

write_statement : 'write' arith_expression ';'
	{
   		int temp = $arith_expression.Eplace;
	    System.out.println("move \t\$a0, \$t" + temp);
	    System.out.println("li\t\$v0, 1");
	    System.out.println("syscall");
	    putReg();
	}
;

bool_expression: bool_term bool_expression2
;
bool_expression2: '||' bool_term bool_expression2
|
;

bool_term:
	bool_factor
	bool_term2
;
bool_term2: '&&' bool_factor bool_term2
|
;

bool_factor:
	'!' bool_primary
	| bool_primary
;

bool_primary: 

	E1 = arith_expression 
	{
		//if(debug) System.out.println("------bool E1.place:" + $E1.Eplace);
	}
	
	relation_op 
	
	E2 = arith_expression
	{
		//if(debug) System.out.println("------bool E2.place:" + $E2.Eplace);

		if($relation_op.op == 0) {
			System.out.println("beq \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + (label-2));
		} else if($relation_op.op == 1) {
			System.out.println("bne \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + (label-2));
		} else if($relation_op.op == 2) {
			System.out.println("bgt \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + (label-2));
		} else if($relation_op.op == 3) {
			System.out.println("bge \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + (label-2));
		} else if($relation_op.op == 4) {
			System.out.println("blt \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + (label-2));
		} else if($relation_op.op == 5) {
			System.out.println("ble \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + (label-2));
		}
		System.out.println("j L" + (label-1));
	}
;

relation_op returns[int op] : 
	'='		{ $op = 0; }
	| '<>'	{ $op = 1; } 
	| '>' 	{ $op = 2; }
	| '>='	{ $op = 3; }
	| '<' 	{ $op = 4; }
	| '<='	{ $op = 5; }
;

arith_expression returns[int Eplace]: 
	arith_term arith_expression2[$arith_term.Eplace]
	{
		$Eplace = $arith_term.Eplace;
	}
;
arith_expression2 [int E1place] returns [int Eplace] :
	'+'
		E2 = arith_term
		{
			System.out.println("add\t\$t" + $E1place + ", \$t" + $E1place + ", \$t" + $E2.Eplace);
			putReg();
			$Eplace = $E1place;
		}
		arith_expression2[$E1place]
	| '-'
		E2 = arith_term
		{
			System.out.println("sub\t\$t" + $E1place + ", \$t" + $E1place + ", \$t" + $E2.Eplace);
			putReg();
			$Eplace = $E1place;
		}
		arith_expression2[$E1place]
	|
		{
			$Eplace = $E1place;
		}
;

arith_term returns [int Eplace]:
	arith_factor arith_term2[$arith_factor.Eplace]
	{
		$Eplace = $arith_factor.Eplace;
	}
;
arith_term2 [int E1place] returns [int Eplace]:
	'*' 
		E2 = arith_factor
		{
			System.out.println("mul\t\$t" + $E1place + ", \$t" + $E1place + ", \$t" + $E2.Eplace);
			putReg();
			$Eplace = $E1place;
		}
		arith_term2[$E1place]

	| '/'
		E2 = arith_factor
		{
			System.out.println("div\t\$t" + $E1place + ", \$t" + $E1place + ", \$t" + $E2.Eplace);
			putReg();
			$Eplace = $E1place;
		}
		arith_term2[$E1place]
		
	| '%'
		E2 = arith_factor
		{
			System.out.println("rem\t\$t" + $E1place + ", \$t" + $E1place + ", \$t" + $E2.Eplace);
			putReg();
			$Eplace = $E1place;
		}
		arith_term2[$E1place]

	|
		{
			$Eplace = $E1place;
		}
;


arith_factor returns [int Eplace]: 
	'-' arith_primary 
		{
			System.out.println("neg\t\$t" + $arith_primary.Eplace + ", \$t" + $arith_primary.Eplace);
			$Eplace = $arith_primary.Eplace;
		}
	| arith_primary
		{
			$Eplace = $arith_primary.Eplace;
		}
;

arith_primary returns [int Eplace] :
	Constant 
		{
			$Eplace = getReg();
			System.out.println("li\t\$t" + $Eplace + ", " + $Constant.text);
		}
	| Identifier 
		{
			if(debug)	System.out.println("#---ID");
			$Eplace = getReg();
			System.out.println("la\t\$t" + $Eplace + ", " + $Identifier.text);
			System.out.println("lw\t\$t" + $Eplace + ", 0(\$t" + $Eplace + ")");
		}
	| '(' arith_expression ')'
		{
			$Eplace = $arith_expression.Eplace;
		}
;

Constant: 
	NonzeroDigit Digit* | Digit
;

WhiteSpaces : [ \t\n]->skip;                                                                             
Comments : '//'~[\r\n]* ->skip;
Uppercase : [A-Z];
Underscore : '_';
NonzeroDigit : [1-9];
Digit : [0-9];

