"""Build and run the MoonBit Cortex-M3 firmware (Python 3, no pip dependencies)."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, subprocess, time

ROOT = Path(__file__).resolve().parents[1]

def tool(name, env):
    found = os.environ.get(env) or shutil.which(name)
    if not found and os.name == 'nt':
        found = next(Path('D:/Codex/tools/rtos').rglob(name + '.exe'), None)
    if not found:
        raise SystemExit(f'Set {env} or add {name} to PATH')
    return str(found)

def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, cwd=ROOT, **kwargs)

def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--scenario', type=int, choices=range(1, 6), default=1)
    parser.add_argument('--ticks', type=int)
    parser.add_argument('--timeout', type=int, default=180)
    parser.add_argument('--output', type=Path, default=ROOT / '_build/rtos')
    parser.add_argument('--build-only', action='store_true')
    a = parser.parse_args()
    ticks = a.ticks or (150010 if a.scenario == 5 else 100)
    out = a.output.resolve() / f'scenario-{a.scenario}'
    out.mkdir(parents=True, exist_ok=True)
    home = Path(os.environ.get('MOON_HOME', 'D:/Codex/toolchains/moon-20261018' if os.name == 'nt' else str(Path.home()/'.moon')))
    moonc = home / 'bin' / ('moonc.exe' if os.name == 'nt' else 'moonc')
    gcc, qemu = tool('arm-none-eabi-gcc', 'ARM_GCC'), tool('qemu-system-arm', 'QEMU_ARM')
    bundle = home / 'lib/core/_build/native/release/bundle'
    common = ['-std-path', bundle, '-i', str(bundle/'prelude/prelude.mi')+':prelude', '-target', 'native']
    kernel_sources = [ROOT/'rtos'/f for f in ('kernel.mbt','sync.mbt','queue.mbt')]
    run([moonc, 'build-package', *kernel_sources, '-o', out/'rtos.core', '-pkg', 'btlqql/moon_deadline/rtos', *common])
    run([moonc, 'build-package', ROOT/'firmware/bridge.mbt', ROOT/'firmware/application.mbt', '-o', out/'bare.core', '-pkg', 'btlqql/moon_deadline_firmware', '-pkg-type', 'foreign_library', '-i', str(out/'rtos.mi')+':rt', *common])
    generated = out/'moonbit.c'
    run([moonc, 'link-core', bundle/'abort/abort.core', bundle/'core.core', out/'rtos.core', out/'bare.core', '-main', 'btlqql/moon_deadline_firmware', '-o', generated, '-target', 'native', '-pkg-config-path', ROOT/'firmware/moon.pkg'])
    port = ROOT/'ports/cortex-m3'
    elf = out/'firmware.elf'
    run([gcc, '-mcpu=cortex-m3', '-mthumb', '-Os', '-ffreestanding', '-fno-builtin', '-fwrapv', '-fno-strict-aliasing', '-ffunction-sections', '-fdata-sections', '-DMOONBIT_NATIVE_NO_SYS_HEADER', f'-DSCENARIO={a.scenario}', f'-DRUN_TICKS={ticks}', '-I', home/'include', '-nostdlib', '-Wl,--gc-sections', '-Wl,-Map='+str(out/'firmware.map'), '-T', port/'link.ld', port/'port.c', port/'runtime.c', port/'context.S', generated, '-lgcc', '-o', elf])
    manifest = {'scenario':a.scenario, 'ticks':ticks, 'elf_sha256':hashlib.sha256(elf.read_bytes()).hexdigest(), 'gcc':run([gcc,'--version'],capture_output=True,text=True).stdout.splitlines()[0], 'moonc':run([moonc,'-v'],capture_output=True,text=True).stdout.strip(), 'qemu':run([qemu,'--version'],capture_output=True,text=True).stdout.splitlines()[0], 'platform':'QEMU mps2-an385 Cortex-M3; not a physical board'}
    if not a.build_only:
        start=time.monotonic()
        result=subprocess.run([qemu,'-M','mps2-an385','-nographic','-semihosting','-icount','shift=10,align=off,sleep=off','-kernel',str(elf)],capture_output=True,text=True,timeout=a.timeout)
        output=result.stdout+result.stderr
        (out/'uart.log').write_text(output,encoding='utf-8')
        manifest.update(exit_code=result.returncode,wall_seconds=round(time.monotonic()-start,3))
        (out/'result.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
        print(output)
        if result.returncode or 'RTOS_PASS' not in output:
            raise SystemExit('Firmware validation failed; see uart.log')
    else:
        (out/'result.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')

if __name__ == '__main__':
    main()
