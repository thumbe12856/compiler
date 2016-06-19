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
		{ System.out.println(".text"); 
		  System.out.println("main:"); 
		}
	BEGIN
	statements
		{ System.out.println("exit:"); }
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

getEtrueFalseNextLabel [int EnextSwit, int EbeginSwit] returns [int Etrue, int Efalse, int Enext, int Ebegin]:
	{
		$Etrue = newLabel();
		$Efalse = newLabel();
		$Enext = -1;
		$Ebegin = -1;
		if($EnextSwit == 1) $Enext = newLabel();
		else if($EbeginSwit == 1) $Ebegin = newLabel();
	}
;

if_statement : 
	'if'
	LABEL = getEtrueFalseNextLabel[0, 0]
	bool_expression[$LABEL.Etrue, $LABEL.Efalse, $LABEL.Enext] 'then' 
		{
			System.out.println("\nL" + $LABEL.Etrue + ":");
		}
	statements 
		{
			System.out.println("\nL" + $LABEL.Efalse + ":");
		}
	'end' 'if' ';'

	| 'if' 
	LABEL = getEtrueFalseNextLabel[1, 0]
	bool_expression[$LABEL.Etrue, $LABEL.Efalse, $LABEL.Enext] 'then' 
		{
			System.out.println("\nL" + $LABEL.Etrue + ":");
		}
	
	statements 'else' 
		{
  			System.out.println("\nj L" + $LABEL.Enext + ":");
			System.out.println("\nL" + $LABEL.Efalse + ":");
		}
	
	statements 
	'end' 'if' ';'
		{
			System.out.println("\nL" + $LABEL.Enext + ":");
		}
;

for_statement :
	'for' 
	LABEL = getEtrueFalseNextLabel[0, 1]
	Identifier 'in' From=arith_expression '..' To=arith_expression 
		{
			//if(debug)	System.out.println("------From.place:" + $From.Eplace + ", To.place:" + $To.Eplace);
			
			System.out.println("\nL" + $LABEL.Ebegin + ":");
			
			if(debug)	System.out.println("#---for assign");
			int tempp = getReg();
			System.out.println("la\t\$t" + tempp + ", " + $Identifier.text);
			System.out.println("sw\t\$t" + $From.Eplace + ", 0(\$t" + tempp + ")");
			putReg();

			System.out.println("ble \$t" + $From.Eplace + ", \$t" + $To.Eplace + ", L" + $LABEL.Etrue);
			System.out.println("j L" + $LABEL.Efalse);
		}
	
	'loop'
		{
			System.out.println("\nL" + $LABEL.Etrue + ":");	
		}
	statements 
		{
			if(debug)	System.out.println("#---for i++");
			int temp = getReg();
			System.out.println("li \$t" + temp + ", 1");
			System.out.println("add \$t" + $From.Eplace + ", \$t" + $From.Eplace + ", \$t" + temp);
			putReg();

			System.out.println("j L" + $LABEL.Ebegin);
		}
	'end' 'loop' ';'
		{
			System.out.println("\nL" + $LABEL.Efalse + ":");
		}
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

bool_expression[int Etrue, int Efalse, int Enext]: bool_term[$Etrue, $Efalse, $Enext] bool_expression2[$Etrue, $Efalse, $Enext]
;
bool_expression2[int Etrue, int Efalse, int Enext]: '||' bool_term[$Etrue, $Efalse, $Enext] bool_expression2[$Etrue, $Efalse, $Enext]
|
;

bool_term[int Etrue, int Efalse, int Enext]:
	bool_factor[$Etrue, $Efalse, $Enext]
	bool_term2[$Etrue, $Efalse, $Enext]
;
bool_term2[int Etrue, int Efalse, int Enext]: '&&' bool_factor[$Etrue, $Efalse, $Enext] bool_term2[$Etrue, $Efalse, $Enext]
|
;

bool_factor[int Etrue, int Efalse, int Enext]:
	'!' bool_primary[$Etrue, $Efalse, $Enext]
	| bool_primary[$Etrue, $Efalse, $Enext]
;

bool_primary[int Etrue, int Efalse, int Enext]: 

	E1 = arith_expression 
	{
		//if(debug) System.out.println("------bool E1.place:" + $E1.Eplace);
	}
	
	relation_op 
	
	E2 = arith_expression
	{
		//if(debug) System.out.println("------bool E2.place:" + $E2.Eplace);

		if($relation_op.op == 0) {
			System.out.println("beq \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + $Etrue);
		} else if($relation_op.op == 1) {
			System.out.println("bne \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + $Etrue);
		} else if($relation_op.op == 2) {
			System.out.println("bgt \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + $Etrue);
		} else if($relation_op.op == 3) {
			System.out.println("bge \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + $Etrue);
		} else if($relation_op.op == 4) {
			System.out.println("blt \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + $Etrue);
		} else if($relation_op.op == 5) {
			System.out.println("ble \$t" + $E1.Eplace + ", \$t" + $E2.Eplace + ", L" + $Etrue);
		}
		System.out.println("j L" + Efalse);
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

