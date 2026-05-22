import inspect
from hermes_cli import main as m
src = inspect.getsource(m.cmd_model)
with open(r'D:\Users\wh898\PycharmProjects\hermes-web-ui\cmd_model_src.txt', 'w') as f:
    f.write(src)
print('Written to cmd_model_src.txt')
print(f'Length: {len(src)} chars')