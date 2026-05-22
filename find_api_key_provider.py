with open(r'D:\Program Files\Python314\Lib\site-packages\hermes_cli\main.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for i, line in enumerate(lines, 1):
        if 'def _model_flow_api_key_provider' in line:
            print(f'Line {i}: {line.strip()}')
            # Print next 50 lines
            for j in range(i, min(i+50, len(lines))):
                print(f'{j}: {lines[j-1].rstrip()}')
            break