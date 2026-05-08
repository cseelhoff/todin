#!/usr/bin/env python3
"""One-shot fixup: at every Odin compile-error site of the form
'Cannot assign value 'X' of type ^map[...] to map[...]', insert `^`
after the bare identifier X on that source line. Safe because the
callee is read-only (we already converted mutating callees to take ^map
explicitly)."""
import re, sys, subprocess

errors = open("/tmp/odin_errors.txt").read()
fixes = []  # (file, line, ident)

# Pattern: Cannot assign value 'NAME' of type '^map' ... -- match name pattern
# We also need the file:line which is in preceding line (Odin error format)
err_re = re.compile(
    r"(/home/caleb/todin/[^\(]+\.odin)\((\d+):(\d+)\) Error: Cannot assign value '([a-z_][a-z_0-9]*)' of type '\^map",
    re.MULTILINE,
)

for m in err_re.finditer(errors):
    fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)))

# Also handle return-statement error: "Cannot assign value 'result' ... in return statement"
ret_re = re.compile(
    r"(/home/caleb/todin/[^\(]+\.odin)\((\d+):(\d+)\) Error: Cannot assign value '([a-z_][a-z_0-9]*)' of type '\^map.*?in return statement",
    re.MULTILINE,
)
for m in ret_re.finditer(errors):
    f, ln, col, n = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
    if (f, ln, col, n) not in fixes:
        fixes.append((f, ln, col, n))

# Also handle parenthesized expressions like
# pro_my_move_options_get_territory_map(...)
expr_re = re.compile(
    r"(/home/caleb/todin/[^\(]+\.odin)\((\d+):(\d+)\) Error: Cannot assign value '(pro_my_move_options_get_[a-z_]+\([^)]+\))'",
    re.MULTILINE,
)
expr_fixes = []
for m in expr_re.finditer(errors):
    expr_fixes.append((m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)))

# Group by file
by_file = {}
for f, ln, col, n in fixes:
    by_file.setdefault(f, []).append((ln, n))

for f, ln, col, expr in expr_fixes:
    by_file.setdefault(f, []).append((ln, expr))

for f, edits in by_file.items():
    with open(f) as fh:
        lines = fh.readlines()
    # Process edits in line order, deduping
    seen = set()
    for ln, ident in edits:
        if (ln, ident) in seen:
            continue
        seen.add((ln, ident))
        idx = ln - 1
        line = lines[idx]
        # Find the identifier as a standalone arg (not an attribute)
        # Replace first occurrence of `ident,` or `ident)` or `ident\n`
        # with `ident^,` etc.
        if "(" in ident:  # parenthesized expression
            new_line = line.replace(ident, ident + "^", 1)
        else:
            # word boundary
            pat = re.compile(r"(?<![a-zA-Z0-9_\.])" + re.escape(ident) + r"(?![a-zA-Z0-9_])")
            new_line = pat.sub(ident + "^", line, count=1)
        if new_line != line:
            lines[idx] = new_line
            print(f"  {f}:{ln}  fix {ident!r}")
    with open(f, "w") as fh:
        fh.writelines(lines)

print(f"\n{len(fixes)+len(expr_fixes)} total fixes attempted")
