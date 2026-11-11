#!/usr/bin/env python3
# copy_lua.py — собирает .lua из аддона в один файл с сохранением структуры

import argparse
import datetime
import re
import sys
from pathlib import Path


# ============================================================================
# Настройки
# ============================================================================

# Файлы, которые НЕ копируем целиком — вырезаем только модули ns_llua['lua'][N]
EXTRACT_MODULES_FILE = "Course/Modules.lua"

# Какие номера модулей вытаскивать из EXTRACT_MODULES_FILE (None = все)
EXTRACT_MODULE_NUMS = {1, 2, 3, 4, 5}

# Шаблон: ns_llua['lua'][N] = {
MODULE_HEADER_RE = re.compile(r"ns_llua\['lua'\]\[(\d+)\]\s*=\s*\{", re.MULTILINE)

# content = [=[ ... ]=]
MODULE_CONTENT_RE = re.compile(r"content\s*=\s*\[=\[(.*?)\]=\]", re.DOTALL)


# ============================================================================
# Вырезание модулей из Course/Modules.lua
# ============================================================================
def extract_modules(src: str, wanted: set[int] | None) -> tuple[str, int]:
    matches = list(MODULE_HEADER_RE.finditer(src))
    if not matches:
        return "-- [extract_modules] не найдено модулей\n", 0

    parts = []
    extracted = 0

    for i, m in enumerate(matches):
        num = int(m.group(1))
        if wanted is not None and num not in wanted:
            continue

        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(src)
        block = src[start:end]

        cm = MODULE_CONTENT_RE.search(block)
        if cm:
            parts.append(f"===== МОДУЛЬ {num} =====\n{cm.group(1).strip()}")
        else:
            # content не найден — выводим блок как есть
            parts.append(f"===== МОДУЛЬ {num} (без content) =====\n{block.strip()}")

        extracted += 1

    if not parts:
        return "-- [extract_modules] ни один модуль не подошёл под фильтр\n", 0

    return "\n\n".join(parts) + "\n", extracted


# ============================================================================
# Основной сбор
# ============================================================================
def build_dump(src_dir: Path, out_file: Path) -> None:
    src_dir = src_dir.resolve()
    out_file = out_file.resolve()

    # Если выходной файл внутри src_dir — исключаем его из поиска
    out_resolved = out_file if out_file.exists() else None

    files = sorted(
        p for p in src_dir.rglob("*.lua")
        if p.resolve() != out_file
    )

    header = (
        "=" * 70 + "\n"
        f" LUA DUMP: {src_dir}\n"
        f" Date: {datetime.datetime.now():%Y-%m-%d %H:%M:%S}\n"
        + "=" * 70 + "\n\n"
    )

    with out_file.open("w", encoding="utf-8") as f:
        f.write(header)

        for path in files:
            rel = path.relative_to(src_dir).as_posix()

            f.write("=" * 70 + "\n")
            f.write(f" FILE: {rel}\n")
            f.write("=" * 70 + "\n\n")

            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                # fallback: бинарный/сломанный файл — пропускаем
                f.write(f"-- [copy_lua] не удалось прочитать как UTF-8: {rel}\n\n\n")
                continue

            if rel == EXTRACT_MODULES_FILE:
                body, count = extract_modules(text, EXTRACT_MODULE_NUMS)
                f.write(body)
                f.write(f"\n-- [copy_lua] извлечено модулей: {count}\n\n\n")
            else:
                f.write(text)
                if not text.endswith("\n"):
                    f.write("\n")
                f.write("\n\n")

    size = out_file.stat().st_size
    print(f"Готово: {out_file}")
    print(f"Файлов .lua: {len(files)}")
    print(f"Размер: {size} байт")


# ============================================================================
# CLI
# ============================================================================
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Собирает все .lua из аддона в один файл с сохранением структуры."
    )
    parser.add_argument(
        "src_dir",
        nargs="?",
        default=".",
        help="Папка аддона (по умолчанию — текущая)",
    )
    parser.add_argument(
        "out_file",
        nargs="?",
        default="lua_dump.txt",
        help="Выходной файл (по умолчанию — lua_dump.txt)",
    )
    args = parser.parse_args()

    src_dir = Path(args.src_dir)
    if not src_dir.is_dir():
        print(f"Ошибка: папка '{src_dir}' не найдена", file=sys.stderr)
        return 1

    build_dump(src_dir, Path(args.out_file))
    return 0


if __name__ == "__main__":
    sys.exit(main())