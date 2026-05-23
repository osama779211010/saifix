import os
import re

lib_dir = r'd:\Hashem\saifix\lib'
helper_file = r'd:\Hashem\saifix\lib\helper\custom_print_helper.dart'

def get_relative_path(from_path, to_path):
    from_dir = os.path.dirname(from_path)
    rel_path = os.path.relpath(to_path, from_dir)
    return rel_path.replace(os.sep, '/')

modified_count = 0

for root, _, files in os.walk(lib_dir):
    for file in files:
        if not file.endswith('.dart'):
            continue
            
        file_path = os.path.join(root, file)
        
        # Skip the helper file itself
        if os.path.abspath(file_path) == os.path.abspath(helper_file):
            continue
            
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Check if replacement needed
        if not re.search(r'\b(print|debugPrint)\(', content):
            continue
            
        # Replace
        new_content = re.sub(r'\b(print|debugPrint)\(', 'customPrint(', content)
        
        # Determine import statement
        rel_path = get_relative_path(file_path, helper_file)
        import_stmt = f"import '{rel_path}';"
        
        if import_stmt not in new_content and 'custom_print_helper.dart' not in new_content:
            # Add import after the last import statement
            import_matches = list(re.finditer(r'^import\s+.*;\s*$', new_content, flags=re.MULTILINE))
            if import_matches:
                last_import = import_matches[-1]
                pos = last_import.end()
                new_content = new_content[:pos] + '\n' + import_stmt + new_content[pos:]
            else:
                new_content = import_stmt + '\n\n' + new_content
                
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
            
        modified_count += 1

print(f'Modified {modified_count} files.')
