# Design: separate `x:` and `rule:` (DEFERRED)

> **Status: documented, not yet applied.** See
> [`x-cmd-install/mneme/profile/design/separate-x-and-rule.md`](https://github.com/x-cmd-install/mneme/blob/main/profile/design/separate-x-and-rule.md)
> for the full design rationale and migration plan.

## TL;DR

The current yml entries have both:
- `x: apt: foo`, `x: brew: foo`, `x: yay: foo` (etc. — standard PM
  shortcuts)
- `rule: /apt: cmd: apt install foo`, `rule: /brew: cmd: brew install foo`
  (etc. — standard PM install commands)

Both express the same information: "this tool is available via apt /
brew / yay". The duplication is wrong because:

- **x-cmd's job** is to make the tool usable (via `x pkg use foo`)
- **The user's job** is to choose how to install on their machine

x-cmd should not prescribe standard PMs.

## New shape (target)

### `x:` block (x-cmd's own install path)

```yaml
x:
  pkg:
    exist: true
  source: https://github.com/owner/repo
  eget: owner/repo      # → x eget owner/repo
  x: foo                # → x pkg use foo
```

Only `pkg`, `source`, `eget`, `x`. No `apt`, `brew`, `yay`, etc.

### `rule:` block (only non-normalizable installs)

```yaml
rule:
  /curl:    # curl | sh style
    cmd: curl -fsSL https://... | sh
  /wget:    # tarball download + extract
    cmd: wget ... && tar xf
  /make:    # custom build
    cmd: ./configure && make install
  /asdf:    # multi-tool version manager (special case)
    cmd: asdf plugin add foo && asdf install foo latest
```

NO `apt`, `brew`, `yay`, `pacman`, `dnf`, `pip`, `npm`, etc.

## Status: DEFERRED

Currently 2,375 yml files have the old shape. Migration is a separate
future project — pilot first (e.g. `data-line/` category with 17
entries), then expand.