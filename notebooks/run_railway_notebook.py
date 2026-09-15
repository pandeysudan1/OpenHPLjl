#!/usr/bin/env python3
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path('/app')
NOTEBOOK = ROOT / 'notebooks' / 'OpenHPLjl_Railway_Validation_and_FCR_AGC.ipynb'
EXECUTED = ROOT / 'notebooks' / 'OpenHPLjl_Railway_Validation_and_FCR_AGC.executed.ipynb'

print(f'Executing notebook: {NOTEBOOK}', flush=True)
cmd = [
    'jupyter', 'nbconvert',
    '--to', 'notebook',
    '--execute', str(NOTEBOOK),
    '--output', EXECUTED.name,
    '--output-dir', str(EXECUTED.parent),
    '--ExecutePreprocessor.timeout=-1',
    '--allow-errors',
]
proc = subprocess.run(cmd, cwd=ROOT)
print(f'nbconvert exit code: {proc.returncode}', flush=True)

if not EXECUTED.exists():
    print('Executed notebook was not produced.', file=sys.stderr)
    sys.exit(proc.returncode or 1)

nb = json.loads(EXECUTED.read_text())
print('\n' + '=' * 88)
print('EXECUTED NOTEBOOK OUTPUT')
print('=' * 88)
for index, cell in enumerate(nb.get('cells', []), start=1):
    if cell.get('cell_type') != 'code':
        continue
    outputs = cell.get('outputs', [])
    if not outputs:
        continue
    print(f'\n--- Cell {index} ---')
    for output in outputs:
        if output.get('output_type') == 'stream':
            text = output.get('text', '')
            if isinstance(text, list):
                text = ''.join(text)
            print(text, end='' if text.endswith('\n') else '\n')
        elif output.get('output_type') == 'error':
            print('\n'.join(output.get('traceback', [])))
        elif 'data' in output and 'text/plain' in output['data']:
            text = output['data']['text/plain']
            if isinstance(text, list):
                text = ''.join(text)
            print(text)

print('\nExecuted notebook saved at:', EXECUTED)
sys.exit(proc.returncode)
