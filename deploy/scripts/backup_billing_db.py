import argparse
import sqlite3
import time
from pathlib import Path


def backup_sqlite(db_path: Path, backup_dir: Path) -> Path:
    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = time.strftime("%Y%m%d_%H%M%S", time.gmtime())
    out_path = backup_dir / f"billing_{timestamp}.sqlite3"

    src = sqlite3.connect(str(db_path))
    dst = sqlite3.connect(str(out_path))
    try:
        src.backup(dst)
    finally:
        dst.close()
        src.close()

    return out_path


def rotate_backups(backup_dir: Path, keep_count: int) -> int:
    if keep_count <= 0:
        return 0

    files = sorted(
        [p for p in backup_dir.glob("billing_*.sqlite3") if p.is_file()],
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )

    removed = 0
    for old in files[keep_count:]:
        old.unlink(missing_ok=True)
        removed += 1

    return removed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Backup and rotate Scan2DOCX billing SQLite DB")
    parser.add_argument("--db-path", default="data/billing.sqlite3", help="Path to SQLite DB")
    parser.add_argument("--backup-dir", default="backups", help="Directory to store backup files")
    parser.add_argument("--keep-count", type=int, default=14, help="Number of latest backups to keep")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    db_path = Path(args.db_path).resolve()
    backup_dir = Path(args.backup_dir).resolve()

    if not db_path.exists():
        raise FileNotFoundError(f"Database file not found: {db_path}")

    backup_file = backup_sqlite(db_path, backup_dir)
    removed = rotate_backups(backup_dir, args.keep_count)

    print(f"Backup created: {backup_file}")
    print(f"Rotation removed: {removed}")


if __name__ == "__main__":
    main()
