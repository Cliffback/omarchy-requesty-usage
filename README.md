# Requesty usage for Omarchy

A **service plugin** that enriches the built-in [Omarchy](https://omarchy.org)
**Agents** panel with a **Requesty** tab. It ships no widget and no UI of its
own: it only writes the usage record where the stock panel already looks, so
your existing Agents panel grows the provider automatically — nothing is
replaced, patched, or duplicated.

The tab shows:

- **Credits left** — the organization's remaining balance, in the hero line.
- **Tokens by day** (last 7 days) and **tokens by model** (last 30 days),
  account-wide.

Data comes from the Requesty management API:

| Endpoint | What it provides |
|---|---|
| `GET https://api-v2.requesty.ai/v1/manage/org` | the organization's remaining balance |
| `GET https://api-v2.requesty.ai/v1/manage/org/usage?…&group_by=model_used` | account-wide per-day spend, tokens, and the per-model breakdown |

Both require a key with the **`manage: read`** permission. Without a resolvable
credential the tab never appears; a failed fetch keeps the previous record
visible until the next attempt succeeds.

## Requirements

- Omarchy (Hyprland + omarchy-shell)
- A Requesty API key with **`manage: read`**, reachable on this machine

## Installation

```bash
omarchy plugin add https://github.com/Cliffback/omarchy-requesty-usage.git --enable
```

Then make sure the service is enabled in `~/.config/omarchy/shell.json`
(`omarchy plugin add --enable` normally does it):

```json
{ "plugins": [ { "id": "cliffback.requesty" } ] }
```

Open your Agents bar widget: the Requesty tab is there. The service refreshes
every five minutes; force it with:

```bash
omarchy-shell cliffback.requesty refresh
```

## Credential

The plugin reads a single key from, in order:

1. **`REQUESTY_API_KEY`** environment variable.
2. **`~/.config/omarchy/api-keys.env`** — plain `KEY=value` lines, parsed
   literally (optional surrounding quotes are stripped), never sourced.

Do **not** wrap the value in quotes when it is the only line:

```bash
install -m 600 /dev/null ~/.config/omarchy/api-keys.env
printf 'REQUESTY_API_KEY=%s\n' 'rqs-...' >> ~/.config/omarchy/api-keys.env
```

The key is sent only to `api-v2.requesty.ai` and is never written anywhere else.

### Minting a read-only key

The Requesty console only offers an all-or-nothing **Admin** key
(`manage: write`), which can create and delete keys org-wide. For a bar widget
you want the least privilege that still reads the balance: **`manage: read`**.
Mint one from a one-time Admin key with the [Requesty CLI](https://requesty.ai):

```bash
# 1. Console -> API Keys -> create a temporary key with the Admin permission.
requesty login --api-key '<temp-admin>' --profile temp-admin

# 2. The temp key's id (this is 'self'; works without manage permission):
requesty --profile temp-admin api-keys show self --json        # note .id

# 3. Create the read-only key (no id needed):
requesty --profile temp-admin api-keys create \
  --name omarchy-balance-read \
  --manage-permission read --completions-permission none --json # note .api_key

# 4. Store it (no quotes, file at 0600):
printf 'REQUESTY_API_KEY=%s\n' '<read-only-key>' >> ~/.config/omarchy/api-keys.env

# 5. Verify it can read the balance before discarding the admin key:
curl -sS -H "Authorization: Bearer $(sed -n 's/^REQUESTY_API_KEY=//p' ~/.config/omarchy/api-keys.env)" \
  https://api-v2.requesty.ai/v1/manage/org                   # -> {"name":...,"balance":...}

# 6. Revoke the privileged key — this is temp-admin, NOT the read-only key:
requesty --profile temp-admin api-keys delete '<temp-admin-id>' -y
requesty profiles remove temp-admin
```

`requesty profiles remove` only forgets the profile locally; `api-keys delete`
(or the console) revokes the key itself.

## Troubleshooting

- **The tab never appears** — no credential resolved, or it lacks `manage`.
  Check both:

  ```bash
  bash ~/.config/omarchy/plugins/cliffback.requesty/scripts/update-requesty --resolve
  curl -sS -o /dev/null -w '%{http_code}\n' \
    -H "Authorization: Bearer $REQUESTY_API_KEY" \
    https://api-v2.requesty.ai/v1/manage/org   # 200 = good, 403 = no manage permission
  ```

- **Numbers look stale** — a fetch failed and the previous record is kept on
  purpose; shell errors surface in `journalctl --user | grep -i requesty`.
  Force a fresh pull with `omarchy-shell cliffback.requesty refresh`.

- **The tab is missing after adding it** — the stock panel re-lists the usage
  directory only when it runs its own updater. Open the Agents panel (or press
  `r` inside it) to force a rescan.

## Uninstall

```bash
omarchy plugin remove cliffback.requesty
```

The tab disappears from the Agents panel on the next rescan. Optional spotless
cleanup:

```bash
rm -f ~/.local/state/omarchy/agents/usage/requesty.json
rm -f ~/.cache/omarchy/requesty-org.json ~/.cache/omarchy/requesty-usage.json
```

## License

[MIT](LICENSE)
