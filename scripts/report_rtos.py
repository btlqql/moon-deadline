"""Collect previously executed QEMU results; does not manufacture test outcomes."""
from pathlib import Path
import hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'_build/rtos'
dest=ROOT/'docs/evidence/rtos-20261106'
dest.mkdir(parents=True,exist_ok=True)
results=[]
for name in [*(f'scenario-{i}' for i in range(1,6)),'scenario-1-stack','scenario-1-allocation']:
    item=json.loads((source/name/'result.json').read_text())
    log=(source/name/'uart.log').read_text()
    elf=source/name/'firmware.elf'
    assert item['elf_sha256']==hashlib.sha256(elf.read_bytes()).hexdigest()
    if item['expected_panic'] is None:
        assert item['exit_code']==0 and 'RTOS_PASS\n' in log
    else:
        assert item['exit_code']!=0 and f"PANIC {item['expected_panic']}\n" in log and 'RTOS_PASS' not in log
    for filename in ('result.json','uart.log'):
        shutil.copyfile(source/name/filename,dest/(name+'-'+filename))
    item['name']=name
    item['metrics']={line.split()[0]:int(line.split()[1]) for line in log.splitlines() if len(line.split())==2 and line.split()[1].isdigit()}
    results.append(item)
report={'source_head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'platform':'QEMU MPS2 AN385 Cortex-M3; no physical-board validation',
    'positive_cases':5,'expected_guard_rejections':2,'results':results}
(dest/'summary.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('Collected 5 executed passes and 2 expected guard rejections with matching ELF hashes')
