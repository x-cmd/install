<!--
Thanks for contributing to x-cmd/install.

Please pick one of the categories below and fill out the matching block.
Delete the other blocks — keep only the one that matches your change.

For guidance see:
- README.md                              → repo overview
- CONTRIBUTING.md                        → contribution workflow + quality bar
- .vscode/install.schema.json            → canonical field schema
-->

## What kind of change?

- [ ] **rec:** add a new package under `src/<category>/`
- [ ] **update:** modify an existing entry
- [ ] **article:** correct prose in a generated article / README
- [ ] **chore:** non-content change (workflow, schema, docs)

---

## rec: — new package

- **owner/repo:** <owner>/<repo>
- **homepage:** <URL>
- **license (SPDX):** <e.g. MIT>
- **category:** <src/<category>/>
- **install rule:** <eget | brew | apt | cargo | npm | pip | go | …>
- **proposed file:** `src/<category>/<tool>.yml`

```yaml
# paste the full YAML block you intend to commit
```

- [ ] I ran `x ws lint src/<category>/<tool>.yml` locally
- [ ] I ran `x ws check` locally

---

## update: — modify existing entry

- **file changed:** `src/<category>/<tool>.yml`
- **field(s) touched:** <homepage | license | x.source | x.eget | rule | desc.* | …>

**Diff summary**

```diff
- old line
+ new line
```

**Why:** <link to upstream issue / release notes / source of truth>

- [ ] I ran `x ws lint` on the touched file
- [ ] I ran `x ws check`

---

## article: — correct prose

- **article URL:** <x-cmd.com/install/<tool>>
- **language:** <中文 | English | both>
- **kind:** <typo | factual error | broken link | bad translation | outdated>

**Before**
> paste the current text verbatim

**After**
> paste the suggested replacement

**Source:** <link>

---

## Checklist (always)

- [ ] I read [CONTRIBUTING.md](https://github.com/x-cmd/install/blob/main/CONTRIBUTING.md).
- [ ] My PR title follows `rec:` / `update:` / `article:` / `chore:` prefix.
- [ ] No unrelated files are modified.
