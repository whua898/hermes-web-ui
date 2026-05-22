import os
import json
from pathlib import Path

# Try to get NVIDIA key from hermes config
hermes_dir = Path.home() / '.hermes'
env_file = hermes_dir / '.env'
auth_file = hermes_dir / 'auth.json'

nvidia_key = None

# Try .env first
if env_file.exists():
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('NVIDIA_API_KEY='):
                nvidia_key = line.split('=', 1)[1].strip()
                print(f'Found key in .env: {nvidia_key[:10]}...')
                break

# Try auth.json credential_pool
if not nvidia_key and auth_file.exists():
    with open(auth_file, 'r') as f:
        auth = json.load(f)
        pool = auth.get('credential_pool', {}).get('nvidia', [])
        if pool:
            nvidia_key = pool[0].get('access_token', '')
            print(f'Found key in auth.json pool: {nvidia_key[:10]}...')

if not nvidia_key:
    print('ERROR: No NVIDIA_API_KEY found in .env or auth.json')
    exit(1)

from hermes_cli.models import probe_api_models, filter_agentic_models

base_url = 'https://integrate.api.nvidia.com/v1'

print(f'Base URL: {base_url}')
print()

try:
    result = probe_api_models(nvidia_key, base_url, limit=500)
    raw_models = result.get('raw_models') or result.get('models') or []
    print(f'Raw models from API: {len(raw_models)}')
    
    if raw_models:
        print(f'First 5 raw models:')
        for i, m in enumerate(raw_models[:5], 1):
            print(f'  {i}. {m}')
        print()
    
    agentic = filter_agentic_models(raw_models)
    print(f'After filter_agentic_models: {len(agentic)}')
    
    if agentic:
        print(f'First 10 agentic models:')
        for i, m in enumerate(agentic[:10], 1):
            print(f'  {i}. {m}')
        print()
        if len(agentic) > 10:
            print(f'Last 5 agentic models:')
            for i, m in enumerate(agentic[-5:], len(agentic)-4):
                print(f'  {i}. {m}')
    
    # Show what was filtered out
    filtered_out = set(raw_models) - set(agentic)
    print(f'\nFiltered out: {len(filtered_out)} models')
    if filtered_out:
        print('Sample filtered models (first 10):')
        for i, m in enumerate(list(filtered_out)[:10], 1):
            print(f'  {i}. {m}')
            
except Exception as e:
    print(f'ERROR: {e}')
    import traceback
    traceback.print_exc()