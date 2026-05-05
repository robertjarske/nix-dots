import re
import sys


def parse(s):
    m = re.search(r"-(\d[^-]*)$", s)
    return (s[: m.start()], m.group(1)) if m else (s, "")


def load(path):
    pkgs = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                name, ver = parse(line)
                pkgs[name] = ver
    return pkgs


def section(title, base_f, current_f):
    base = load(base_f)
    current = load(current_f)
    changed, added, removed = [], [], []
    for pkg in sorted(set(base) | set(current)):
        if pkg in base and pkg in current:
            if base[pkg] != current[pkg]:
                changed.append(f"| `{pkg}` | `{base[pkg]}` | `{current[pkg]}` |")
        elif pkg in current:
            added.append(f"| `{pkg}` | — | `{current[pkg]}` |")
        else:
            removed.append(f"| `{pkg}` | `{base[pkg]}` | — |")

    print(f"\n## {title}\n")
    if not (changed or added or removed):
        print("No package changes.")
        return
    print("| Package | Before | After |")
    print("|---------|--------|-------|")
    for row in changed + added + removed:
        print(row)


section("bastion", "/tmp/bastion-base.txt", "/tmp/bastion-current.txt")
section("forge", "/tmp/forge-base.txt", "/tmp/forge-current.txt")
