%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object

int lines = 1;
int error_count = 0;

ofstream outlog;
ofstream errorlog;

#define BUCKET_SIZE 10

symbol_table *table;

string current_type;
string current_function_name;
vector<pair<string, string>> pending_params;

void semantic_error(string msg)
{
	outlog << "At line no: " << lines << " " << msg << endl << endl;
	errorlog << "At line no: " << lines << " " << msg << endl << endl;
	error_count++;
}

void insert_variable(symbol_info *id_sym, string data_type, bool is_array, string array_size)
{
	if (data_type == "void")
	{
		semantic_error("variable type can not be void ");
		return;
	}
	id_sym->set_symbol_type(is_array ? "array" : "variable");
	id_sym->set_data_type(data_type);
	if (is_array)
		id_sym->set_array_size(array_size);

	if (!table->insert(id_sym))
		semantic_error("Multiple declaration of variable " + id_sym->get_name());
}

void register_function(symbol_info *id_sym, string return_type, vector<pair<string, string>> params)
{
	if (table->lookup(id_sym) != NULL)
		semantic_error("Multiple declaration of function " + id_sym->get_name());

	for (size_t i = 0; i < params.size(); i++)
	{
		if (params[i].second.empty()) continue;
		for (size_t j = 0; j < i; j++)
		{
			if (params[j].second == params[i].second)
			{
				semantic_error("Multiple declaration of variable " + params[i].second + " in parameter of " + id_sym->get_name());
				break;
			}
		}
	}

	id_sym->set_symbol_type("function");
	id_sym->set_data_type(return_type);
	for (auto &p : params)
		id_sym->add_param(p.first, p.second);

	table->insert(id_sym);
	current_function_name = id_sym->get_name();
	pending_params = params;
}

void open_block_scope()
{
	table->enter_scope(outlog);

	for (auto &p : pending_params)
	{
		if (p.second.empty()) continue; // unnamed parameter, nothing to insert

		symbol_info *param_sym = new symbol_info(p.second, "ID");
		param_sym->set_symbol_type("variable");
		param_sym->set_data_type(p.first);

		if (!table->insert(param_sym)) 
		{
			delete param_sym; // duplicate already reported by register_function
		}
	}
	pending_params.clear();
}

void close_block_scope()
{
	table->print_all_scopes(outlog);
	table->exit_scope(outlog);
}

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;

    // you may need to reinitialize variables if you find an error
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN param_list RPAREN
		{
			register_function($2, $1->get_name(), $4->get_params());
		}
		compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"("+$4->get_name()+")\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$7->get_name(),"func_def");	
		}
		| type_specifier ID LPAREN RPAREN
		{
			register_function($2, $1->get_name(), {});
		}
		compound_statement
		{
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$6->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()\n"+$6->get_name(),"func_def");	
		}
 		;

param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;
			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");

			for (auto &p : $1->get_params())
				$$->add_param(p.first, p.second);
            $$->add_param($3->get_name(), $4->get_name());
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");

            for (auto &p : $1->get_params())
                $$->add_param(p.first, p.second);
            $$->add_param($3->get_name(), ""); // unnamed parameter
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;
			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");

            $$->add_param($1->get_name(), $2->get_name());
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			$$ = new symbol_info($1->get_name(),"param_list");

            $$->add_param($1->get_name(), ""); // unnamed parameter
		}
 		;

compound_statement : LCURL
			{
				open_block_scope();
			}
			statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->get_name()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");

				close_block_scope();
 		    }
 		    | LCURL
 		    {
				open_block_scope();
			}
			RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");

				close_block_scope();
 		    }
 		    ;
 		    
variable_decl : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			$$ = new symbol_info("int","type");
			current_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			$$ = new symbol_info("float","type");
			current_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			$$ = new symbol_info("void","type");
			current_type = "void";
	    }
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;
			$$ = new symbol_info("char","type");
			current_type = "char";
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<endl<<endl;
            $$ = new symbol_info($1->get_name()+","+$3->get_name(),"decl_list");

            insert_variable($3, current_type, false, "");
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;

            $$ = new symbol_info($1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]","decl_list");

            insert_variable($3, current_type, true, $5->get_name());
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"decl_list");

            insert_variable($1, current_type, false, "");
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

            $$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","decl_list");

            insert_variable($1, current_type, true, $3->get_name());
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
	   }
	   ;
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 

			symbol_info* var = table->lookup($3); 
			if (var == NULL) 
			{
				semantic_error("Undeclared variable " + $3->get_name());
			}
			
			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->get_name()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->get_name()+";","expr_stmt");
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		$$ = new symbol_info($1->get_name(),"varbl");

		symbol_info* var = table->lookup($1);
		if (var == NULL) {
			semantic_error("Undeclared variable " + $1->get_name());
			$$->set_data_type("error");
		} else {
			if (var->get_symbol_type() == "array") {
                semantic_error("variable is of array type : " + $1->get_name());
			}
			$$->set_data_type(var->get_data_type());
			$$->set_symbol_type(var->get_symbol_type());
		}
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;
		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");

		symbol_info* var = table->lookup($1);
		if (var == NULL) {
			semantic_error("Undeclared variable " + $1->get_name());
			$$->set_data_type("error");
		} else {
			if (var->get_symbol_type() != "array") {
				semantic_error("variable is not of array type : " + $1->get_name());
			}
			if ($3->get_data_type() != "int" && $3->get_data_type() != "error") {
				semantic_error("array index is not of integer type : " + $1->get_name());
			}
			$$->set_data_type(var->get_data_type());
		}
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"expr");
			$$->set_data_type($1->get_data_type());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");

			if ($1->get_data_type() != "error" && $3->get_data_type() != "error") {
				if ($1->get_data_type() == "int" && $3->get_data_type() == "float") {
					semantic_error("floating point number assigned to integer type variable");
				}
				else if ($1->get_data_type() != $3->get_data_type() && 
				    !($1->get_data_type() == "float" && $3->get_data_type() == "int")) {
					semantic_error("Type mismatch in assignment");
				}
			}
			$$->set_data_type($1->get_data_type());
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"lgc_expr");
			$$->set_data_type($1->get_data_type()); 
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
			$$->set_data_type("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"rel_expr");
			$$->set_data_type($1->get_data_type());
		}
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
			$$->set_data_type("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"simp_expr");
			$$->set_data_type($1->get_data_type());
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");

			if ($1->get_data_type() == "float" || $3->get_data_type() == "float")
				$$->set_data_type("float");
			else if ($1->get_data_type() != "error" && $3->get_data_type() != "error")
				$$->set_data_type("int");
			else
				$$->set_data_type("error");
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"term");
			$$->set_data_type($1->get_data_type());
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");
			
			if ($2->get_name() == "%") {
				if ($1->get_data_type() != "int" || $3->get_data_type() != "int") {
					semantic_error("Modulus operands must be integers");
				}
				if ($3->get_name() == "0") {
					semantic_error("Modulus by zero");
				}
				$$->set_data_type("int");
			} else {
				if ($2->get_name() == "/" && $3->get_name() == "0") {
					semantic_error("Division by zero");
				}
				if ($1->get_data_type() == "float" || $3->get_data_type() == "float")
					$$->set_data_type("float");
				else if ($1->get_data_type() != "error" && $3->get_data_type() != "error")
					$$->set_data_type("int");
				else
					$$->set_data_type("error");
			}
	 }
     ;

unary_expression : ADDOP unary_expression  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
			$$->set_data_type($2->get_data_type());
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;
			$$ = new symbol_info("!"+$2->get_name(),"un_expr");
			$$->set_data_type("int"); 
	     }
		 | factor_info  
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			$$ = new symbol_info($1->get_name(),"un_expr");

			$$->set_data_type($1->get_data_type()); 
			$$->set_symbol_type($1->get_symbol_type()); 
	     }
		 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		$$ = new symbol_info($1->get_name(),"fctr_info");

		$$->set_data_type($1->get_data_type());
		$$->set_symbol_type($1->get_symbol_type()); 
	}	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		$$ = new symbol_info($1->get_name(),"fctr");

		$$->set_data_type($1->get_data_type());  
		$$->set_symbol_type($1->get_symbol_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;
		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");

    	symbol_info* func = table->lookup($1);
    	if (!func) {
			semantic_error("Undeclared function: " + $1->get_name());
			$$->set_data_type("error");
		} else if (func->get_symbol_type() != "function") {
			semantic_error($1->get_name() + " is not a function");
			$$->set_data_type("error");
    	} else {
    	    int exp = func->get_param_count(), act = $3->get_param_count();
    	    if (exp != act) {
    	        semantic_error("Inconsistencies in number of arguments in function call: " + $1->get_name());
    	    }
    	    // Type check arguments
    	    if (exp == act && exp > 0) {
			    auto exp_params = func->get_params();
			    auto act_args = $3->get_params();
			    for (int i = 0; i < exp; i++) {
			        if (act_args[i].first != "error") {
			            // Check if types match
			            bool type_match = false;
			            if (exp_params[i].first == act_args[i].first) {
			                type_match = true;
			            }
			            if (!type_match) {
			                semantic_error("argument " + to_string(i + 1) + " type mismatch in function call: " + $1->get_name());
			            }
			        }
			    }
			}
    	    $$->set_data_type(func->get_data_type());
    	}
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
		$$ = new symbol_info("("+$2->get_name()+")","fctr");
		$$->set_data_type($2->get_data_type());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
    	outlog<<$1->get_name()<<endl<<endl;
    	$$ = new symbol_info($1->get_name(),"fctr");
    	$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
	
		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"++","fctr");
		$$->set_data_type($1->get_data_type());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"--","fctr");
		$$->set_data_type($1->get_data_type());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;
						
					$$ = new symbol_info($1->get_name(),"arg_list");
					for (auto &p : $1->get_params())
						$$->add_param(p.first, p.second);
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");

				for (auto &p : $1->get_params())
					$$->add_param(p.first, p.second);
				$$->add_param($3->get_data_type(), $3->get_name());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name(),"arg");
				$$->add_param($1->get_data_type(), $1->get_name());
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("24241372_22201804_log.txt", ios::trunc);
	errorlog.open("24241372_22201804_error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	table = new symbol_table(BUCKET_SIZE);
	table->enter_scope(outlog);

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: " << error_count << endl;
	errorlog << "Total errors: " << error_count << endl;
	
	outlog.close();
	errorlog.close();
	
	fclose(yyin);
	delete table;
	
	return 0;
}