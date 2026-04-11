import ast
import sys
import os

def validate_syntax(filepath):

    with open(filepath,'r') as f:
       source = f.read()
    
    try:
       ast.parse(source)
       return True, None
    except SyntaxError as e:
       return False, str(e)


def validate_dag_definition(filepath):

    with open(filepath,'r') as f:
       source = f.read()

    if "from airflow" not in source:
       return False, "No Airflow Import found"
    if "DAG(" not in source:
       return False, "No DAG definition found here"
    return True, None

def main(filepath):
   
    if not os.path.exists(filepath):
      print(f"ERROR: File not found: {filepath}")
      sys.exit(1)

    syntax_okay, syntax_error = validate_syntax(filepath)
    dag_def_okay, dag_def_error  = validate_dag_definition(filepath)
    
    if syntax_okay and dag_def_okay:
       print("All checks passed")
    else:
        if not syntax_okay:
          print(f"Syntax Error : {syntax_error}")
        if not dag_def_okay:
          print(f"Dag Definition Error : {dag_def_error}")
        
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
      print("Usage: python validate_dag.py <filepath>")
      sys.exit(1)
    filepath = sys.argv[1]
    main(filepath)