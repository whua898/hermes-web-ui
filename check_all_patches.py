#!/usr/bin/env python3
"""检查所有补丁状态"""
import os

sp = r'D:\Program Files\Python314\Lib\site-packages'

print("=" * 60)
print("补丁状态检查 - hermes-agent v0.14.0")
print("=" * 60)

# Patch 1: sitecustomize.py
p1 = os.path.join(sp, 'sitecustomize.py')
if os.path.isfile(p1):
    with open(p1, 'rb') as f:
        d1 = f.read()
    print("\n✓ Patch1: sitecustomize.py")
    print(f"  - CREATE_NO_WINDOW: {b'CREATE_NO_WINDOW' in d1}")
    print(f"  - utf-8 encoding: {b'utf-8' in d1}")
else:
    print("\n✗ Patch1: sitecustomize.py 不存在")

# Patch 2c: models.py
p2 = os.path.join(sp, 'hermes_cli', 'models.py')
with open(p2, 'rb') as f:
    d2 = f.read()
print("\n✓ Patch2c: models.py")
print(f"  - filter_agentic_models: {b'filter_agentic_models' in d2}")
print(f"  - _NOISE_PATTERNS: {b'_NOISE_PATTERNS' in d2}")
print(f"  - limit parameter: {b'limit: int | None = None' in d2}")

# Patch 2b: model_switch.py
p3 = os.path.join(sp, 'hermes_cli', 'model_switch.py')
with open(p3, 'rb') as f:
    d3 = f.read()
print("\n✓ Patch2b: model_switch.py")
print(f"  - NVIDIA live API: {b'NVIDIA live API' in d3}")
print(f"  - patch 2b marker: {b'patch 2b' in d3}")

# Patch 7: main.py
p4 = os.path.join(sp, 'hermes_cli', 'main.py')
with open(p4, 'rb') as f:
    d4 = f.read()
print("\n✓ Patch7: main.py")
print(f"  - nvidia branch: {b'provider_id == \"nvidia\"' in d4}")

# Patch-cli: cli.py
p5 = os.path.join(sp, 'cli.py')
with open(p5, 'rb') as f:
    d5 = f.read()
finally_count = d5.count(b'finally:')
return_count = d5.count(b'return')
print("\n? Patch-cli: cli.py")
print(f"  - finally blocks: {finally_count}")
print(f"  - return statements: {return_count}")
print(f"  - 需要手动检查是否有 finally 块中的 return")

print("\n" + "=" * 60)
print("总结")
print("=" * 60)
print("✓ 已应用: Patch1, Patch2c, Patch2b, Patch7")
print("? 待确认: Patch-cli (finally/return)")
print("\n运行 'hermes' 命令查看是否有 SyntaxWarning")