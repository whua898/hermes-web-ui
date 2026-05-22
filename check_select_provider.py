import inspect
from hermes_cli import main as m
src_file = inspect.getfile(m)
print(f'Source file: {src_file}')

import os
print(f'File size: {os.path.getsize(src_file)} bytes')

with open(src_file, 'rb') as f:
    data = f.read()

has_select = b'def select_provider_and_model' in data
print(f'has select_provider_and_model: {has_select}')

# Find all defs containing nvidia/select/model/cmd
import re
defs = re.findall(rb'def (\w+)', data)
for d in defs:
    name = d.decode()
    keywords = ['nvidia', 'NVIDIA', 'select', 'model', 'cmd']
    if any(k in name for k in keywords):
        print(f'  def: {name}')