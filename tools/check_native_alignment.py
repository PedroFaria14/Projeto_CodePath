"""Verifica PT_LOAD de bibliotecas ELF 64-bit dentro de APK/AAB (sem extrair)."""
import argparse
import struct
import zipfile


def check(path):
    checked, failures = 0, []
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if not name.endswith('.so') or not any('/' + abi + '/' in name for abi in ('arm64-v8a', 'x86_64')):
                continue
            data = archive.read(name)
            if data[:5] != b'\x7fELF\x02':
                failures.append(name + ': biblioteca ELF64 inválida')
                continue
            endian = '<' if data[5] == 1 else '>'
            offset = struct.unpack_from(endian + 'Q', data, 32)[0]
            size, count = struct.unpack_from(endian + 'HH', data, 54)
            alignments = []
            for index in range(count):
                header = struct.unpack_from(endian + 'IIQQQQQQ', data, offset + index * size)
                if header[0] == 1:  # PT_LOAD
                    alignments.append(header[7])
            checked += 1
            if not alignments or any(alignment < 16384 for alignment in alignments):
                failures.append(f'{name}: segmentos incompatíveis com páginas de 16 KB ({alignments})')
            else:
                print(f'OK: {name} — PT_LOAD >= 16 KB')
    if not checked:
        failures.append('Nenhuma biblioteca nativa de 64 bits encontrada no artefato.')
    if failures:
        raise SystemExit('\n'.join(failures))
    print(f'{checked} bibliotecas de 64 bits verificadas. A validação não substitui o teste em dispositivo de 16 KB.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact', help='Caminho do APK ou AAB')
    check(parser.parse_args().artifact)
