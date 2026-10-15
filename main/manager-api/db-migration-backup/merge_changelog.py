"""Merge the 108 Liquibase sqlFile changesets into one baseline file.

Run from main/manager-api. Reads the ORIGINAL files from db-migration-backup/changelog/
in the order listed in the ORIGINAL master (db-migration-backup/db.changelog-master.original.yaml),
writes src/main/resources/db/changelog/<NEW_ID>.sql and verifies that the merged file splits
into exactly the same SQL statements as the originals.
"""
import re, sys, pathlib

NEW_ID = sys.argv[1] if len(sys.argv) > 1 else "202610150000"
BK = pathlib.Path("db-migration-backup")
OUT = pathlib.Path("src/main/resources/db/changelog") / f"{NEW_ID}.sql"

master = (BK / "db.changelog-master.original.yaml").read_text(encoding="utf-8")
ids = re.findall(r"path: classpath:db/changelog/(\d+)\.sql", master)
assert len(ids) == 108 and len(set(ids)) == 108, len(ids)


# Unescaped apostrophes introduced by the English translation commit inside single-quoted SQL
# strings (e.g. 'my boyfriend's books'). They terminate the string early and break the file, so
# they are escaped with a backslash (MySQL/Liquibase accept \'; the originals already use it
# for "Rocky\'s"). (file id, old text, new text, expected occurrences)
FIXES = [
    ("202504092335", "boyfriend\'s", "boyfriend\\'s", 1),
    ("202504092335", "child\'s", "child\\'s", 1),
    ("202504092335", "Chase\'s", "Chase\\'s", 1),
    ("202504092335", "Skye\'s", "Skye\\'s", 1),
    ("202504092335", "Rocky's", "Rocky\\'s", 1),
    ("202508081701", "project\'s", "project\\'s", 2),
    ("202602021555", "Let\'s", "Let\\'s", 1),
]


def read(i):
    # utf-8-sig drops a BOM; newline='' keeps every CR/LF exactly (embedded newlines in string data)
    with open(BK / "changelog" / f"{i}.sql", encoding="utf-8-sig", newline="") as f:
        t = f.read()
    for fid, old, new, cnt in FIXES:
        if fid == i:
            assert t.count(old) == cnt, (fid, old, t.count(old))
            t = t.replace(old, new)
    return t


MARKER = re.compile(r"^[ \t]*--[ \t]*(liquibase formatted sql|changeset[ \t].*)[ \t]*(\r?\n|$)", re.M | re.I)


def strip_markers(t):
    return MARKER.sub("", t)


def split_statements(t):
    """Minimal MySQL-aware splitter: respects '', \"\", ``, -- , # , /* */ comments. Returns stripped statements."""
    out, cur, i, n = [], [], 0, len(t)
    while i < n:
        c = t[i]
        if c in "'\"`":
            q, j = c, i + 1
            while j < n:
                if t[j] == "\\" and q != "`":
                    j += 2
                    continue
                if t[j] == q:
                    if j + 1 < n and t[j + 1] == q:
                        j += 2
                        continue
                    break
                j += 1
            cur.append(t[i:j + 1]); i = j + 1
        elif t.startswith("/*", i):
            j = t.find("*/", i + 2); i = n if j < 0 else j + 2
        elif t.startswith("--", i) and (i + 2 >= n or t[i + 2] in " \t\r\n"):
            while i < n and t[i] not in "\r\n": i += 1
        elif c == "#":
            while i < n and t[i] not in "\r\n": i += 1
        elif c == ";":
            s = "".join(cur).strip()
            if s: out.append(s)
            cur = []; i += 1
        else:
            cur.append(c); i += 1
    s = "".join(cur).strip()
    if s: out.append(s)
    return out


def ends_with_terminator(t):
    t = re.sub(r"/\*.*?\*/", "", t, flags=re.S)
    lines = [l for l in t.splitlines() if l.strip() and not l.strip().startswith("--")]
    return bool(lines) and lines[-1].rstrip().endswith(";")


parts, expected, fixed = [], [], []
for i in ids:
    raw = read(i)
    expected += split_statements(raw)           # what Liquibase ran per file
    body = strip_markers(raw)
    if not body.endswith(("\n", "\r\n")):
        body += "\n"
    if not ends_with_terminator(body):
        body = body.rstrip() + ";\n"
        fixed.append(i)
    parts.append(f"-- ===== begin {i}.sql =====\n{body}-- ===== end {i}.sql =====\n")

header = (
    "-- Baseline schema + seed data for the fresh custom install.\n"
    f"-- Merged from the original {len(ids)} changelog files (order = original master), see db-migration-backup/.\n"
    "-- Add new schema changes as NEW changesets (new file + new entry in db.changelog-master.yaml).\n\n"
)
merged = header + "\n".join(parts)
with open(OUT, "w", encoding="utf-8", newline="") as f:
    f.write(merged)
with open(OUT, encoding="utf-8", newline="") as f:
    got = split_statements(f.read())
assert got == expected, (len(got), len(expected))
print(f"OK: {len(ids)} files -> {OUT} ({len(merged)} chars), {len(got)} statements identical to originals")
print("added missing ';' to:", fixed)
