"""Run public-source compile checks on an Apple-hosted macOS runner. No game inputs."""
import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import time

PIN = '269d61ff974b2e8e073d7357466ae130c3f6812f'
GAME = '0100F2C0115B6000'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--logs', type=Path, required=True)
    parser.add_argument('--plan', action='store_true', help='Print steps without executing any Apple tool')
    args = parser.parse_args()
    source, logs = args.source.resolve(), args.logs.resolve()
    steps = ['Verify pinned Git commit', 'Record Xcode and iPhoneOS SDK versions',
             'Check Metal compiler against upstream lock', 'Compile upstream iOS sources',
             'Compile Windows UIKit front end with Apple clang', 'Compile synthetic Metal shader']
    if args.plan:
        print(json.dumps({'commit': PIN, 'profile': GAME, 'steps': steps,
                          'uploads': ['diagnostic logs', 'results.json'], 'game_inputs': False}, indent=2))
        return 0
    logs.mkdir(parents=True, exist_ok=True)
    results = []
    def record():
        (logs / 'results.json').write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8')
    if platform.system() != 'Darwin':
        results.append({'name': 'platform', 'exit_code': 1, 'detail': 'Requires macOS; no Apple tool was invoked'})
        record()
        print('Requires macOS', file=sys.stderr)
        return 1
    env = os.environ.copy()
    for key in list(env):
        if key.startswith(('DM_', 'NXW_')) or key in ('GAME', 'PYTHONPATH', 'PYTHONHOME'):
            env.pop(key)
    env.update(DM_GAME=GAME, GAME=GAME)
    def run(name, command, timeout=600):
        started = time.monotonic()
        try:
            p = subprocess.run(command, cwd=source, env=env, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, text=True, errors='replace', timeout=timeout)
            code, output = p.returncode, p.stdout
        except (OSError, subprocess.TimeoutExpired) as exc:
            code, output = 1, str(exc)
        (logs / (name + '.log')).write_text(output, encoding='utf-8')
        results.append({'name': name, 'exit_code': code, 'seconds': round(time.monotonic()-started, 2)})
        record()
        print(name, 'exit', code, flush=True)
        print(output[-6000:], flush=True)
        if code:
            raise RuntimeError(name + ' failed; see logs')
        return output.strip()
    try:
        actual = run('commit', ['git', 'rev-parse', 'HEAD'])
        if actual != PIN:
            raise RuntimeError('Unexpected source commit')
        run('xcode', ['xcodebuild', '-version'], 60)
        sdk = run('sdk-path', ['xcrun', '--sdk', 'iphoneos', '--show-sdk-path'], 60)
        version = run('sdk-version', ['xcrun', '--sdk', 'iphoneos', '--show-sdk-version'], 60)
        if int(version.split('.')[0]) < 26:
            raise RuntimeError('iPhoneOS SDK 26+ required')
        clang = run('clang-path', ['xcrun', '--sdk', 'iphoneos', '--find', 'clang'], 60)
        env['PATH'] = str(Path(clang).parent) + os.pathsep + env.get('PATH', '')
        env['NXW_IOS_SDK'] = sdk
        run('metal-lock', [sys.executable, 'dm/gfx/tools/own_compilers.py', '--check-metal'], 120)
        run('upstream-ios-compile', [sys.executable, 'dm/ios/tools/compile_check.py'])
        with tempfile.TemporaryDirectory(prefix='nxnative-public-check-') as scratch:
            work = Path(scratch)
            run('windows-frontend-apple-compile', [sys.executable, 'win/compile_check.py', GAME, str(work / 'compile')])
            shader = work / 'smoke.metal'
            shader.write_text('#include <metal_stdlib>\nusing namespace metal;\nkernel void smoke(device uint* output [[buffer(0)]], uint i [[thread_position_in_grid]]) { output[i] = i; }\n', encoding='utf-8')
            air, lib = work / 'smoke.air', work / 'smoke.metallib'
            run('metal-compile', ['xcrun', '--sdk', 'iphoneos', 'metal', '-c', '-mios-version-min=18.0', str(shader), '-o', str(air)], 120)
            run('metal-library', ['xcrun', '--sdk', 'iphoneos', 'metallib', str(air), '-o', str(lib)], 120)
    except (RuntimeError, ValueError) as exc:
        results.append({'name': 'summary', 'exit_code': 1, 'detail': str(exc)})
        record()
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
