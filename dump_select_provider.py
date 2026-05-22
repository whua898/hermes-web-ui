import inspect
from hermes_cli import main as m
src = inspect.getsource(m.select_provider_and_model)
with open(r'D:\Users\wh898\PycharmProjects\hermes-web-ui\select_provider_src.txt', 'w', encoding='utf-8') as f:
    f.write(src)
print('Written to select_provider_src.txt')
print(f'Length: {len(src)} chars')

# Also check for nvidia mentions
if 'nvidia' in src.lower():
    print('FOUND nvidia in select_provider_and_model!')
else:
    print('NO nvidia in select_provider_and_model')