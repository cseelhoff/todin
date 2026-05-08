#!/usr/bin/env python3
"""Two-way fixup. Reads /tmp/odin_errors.txt and applies:
- 'map[K]V' arg to '^map[K]V' param  → prefix arg with `&`
- '^map[K]V' arg to 'map[K]V' param  → suffix arg with `^`
- '^map[K]V' arg to 'map[K]V' assignment/return → suffix with `^`
"""
import re
errors = open("/tmp/odin_errors.txt").read()

err_re_addptr = re.compile(
    r"(/home/caleb/todin/[^\(]+\.odin)\((\d+):(\d+)\) Error: Cannot assign value '([a-z_][a-z_0-9]*)' of type 'map\[",
    re.MULTILINE,
)
err_re_deref = re.compile(
    r"(/home/caleb/todin/[^\(]+\.odin)\((\d+):(\d+)\) Error: Cannot assign value '([a-z_][a-z_0-9]*)' of type '\^map\[",
    re.MULTILINE,
)

addptr = []
deref = []
for m in err_re_addptr.finditer(errors):
    addptr.append((m.group(1), int(m.group(2)), m.group(4)))
for m in err_re_deref.finditer(errors):
    deref.append((m.group(1), int(m.group(2)), m.group(4)))

def apply(file_lines, edits, op):
    seen = set()
    for ln, name in edits:
        if (ln, name, op) in seen:
            continue
        seen.add((ln, name, op))
        idx = ln - 1
        if idx >= len(file_lines):
            continue
        line = file_lines[idx]
        if op == "addptr":
            pat = re.compile(r"(?<![a-zA-Z0-9_\.&])" + re.escape(name) + r"(?![a-zA-Z0-9_])")
            new = pat.sub("&" + name, line, count=1)
        else:  # deref
            pat = re.compile(r"(?<![a-zA-Z0-9_\.&])" + re.escape(name) + r"(?![a-zA-Z0-9_\^])")
            new = pat.sub(name + "^", line, count=1)
        if new != line:
            file_lines[idx] = new
            print(f"  {ln}  {op}  {name}")

by_file = {}
for f, ln, n in addptr:
    by_file.setdefault(f, ([],[]))[0].append((ln, n))
for f, ln, n in deref:
    by_file.setdefault(f, ([],[]))[1].append((ln, n))

for f, (ap, dr) in by_file.items():
    print(f"=== {f} ===")
    lines = open(f).readlines()
    apply(lines, ap, "addptr")
    apply(lines, dr, "deref")
    open(f, "w").writelines(lines)
print(f"\n{len(addptr)} addptr + {len(deref)} deref attempted")
