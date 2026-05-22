import os
from hermes_cli.models import probe_api_models, filter_agentic_models

# Get NVIDIA API key from env
nvidia_key = os.getenv('NVIDIA_API_KEY', '')
if not nvidia_key:
    print('ERROR: NVIDIA_API_KEY not set in environment')
    exit(1)

base_url = 'https://integrate.api.nvidia.com/v1'

print(f'Testing NVIDIA API with key: {nvidia_key[:10]}...')
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
        print(f'Last 5 agentic models:')
        for i, m in enumerate(agentic[-5:], len(agentic)-4):
            print(f'  {i}. {m}')
    
    # Show what was filtered out
    filtered_out = set(raw_models) - set(agentic)
    print(f'\nFiltered out: {len(filtered_out)} models')
    if filtered_out:
        print('Sample filtered models:')
        for i, m in enumerate(list(filtered_out)[:10], 1):
            print(f'  {i}. {m}')
            
except Exception as e:
    print(f'ERROR: {e}')
    import traceback
    traceback.print_exc()