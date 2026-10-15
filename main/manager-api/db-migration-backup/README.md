# db-migration-backup

Backup of the original 108 Liquibase changelog files of manager-api, kept for reference only.
It is NOT on the classpath (not under `src/main/resources`) and is NOT loaded or packaged by the app.

- `changelog/*.sql`: the original files, unmodified.
- `db.changelog-master.original.yaml`: the original master. Its order is the real execution order
  and differs from the file-name order, so never sort by name.
- `merge_changelog.py`: generator for the baseline `src/main/resources/db/changelog/202610150000.sql`.
  Run from `main/manager-api`: `python db-migration-backup/merge_changelog.py 202610150000`.
  It reads the originals in master order, strips the BOM and `-- liquibase formatted sql` /
  `-- changeset` marker lines, adds a missing trailing `;`, escapes the apostrophes listed in `FIXES`
  (translation bugs that broke string literals), preserves CR/LF bytes, wraps each file in
  begin/end comment banners, and asserts that the merged file splits into exactly the same SQL
  statements as the (fixed) originals.

New schema changes go into new files and new changeSets after the baseline, never into this folder.
