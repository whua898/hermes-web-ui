import os, sys

sp = r'D:\Program Files\Python314\Lib\site-packages'
models = os.path.join(sp, 'hermes_cli', 'models.py')
print(f'File size: {os.path.getsize(models)} bytes')

with open(models, 'rb') as f:
    data = f.read()

print(f'filter_agentic_models: {b"filter_agentic_models" in data}')
print(f'probe_api_models: {b"probe_api_models" in data}')
print(f'nvidia (models.py): {b"nvidia" in data}')
print(f'has raw_models: {b"raw_models" in data}')

# Check main.py
main = os.path.join(sp, 'hermes_cli', 'main.py')
with open(main, 'rb') as f:
    main_data = f.read()
print(f'main.py nvidia: {b"elif provider_id" in main_data and b"nvidia" in main_data}')

# Check what 'hermes' actually uses
import subprocess
result = subprocess.run([sys.executable, '-m', 'pip', 'show', 'hermes-agent'], capture_output=True, text=True)
print(f'\npip show hermes-agent:')
print(result.stdout[:500])