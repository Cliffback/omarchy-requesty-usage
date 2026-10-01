# Requesty usage for Omarchy

A **service plugin** that enriches the built-in [Omarchy](https://omarchy.org)
**Agents** panel with a **Requesty** tab. It ships no widget and no UI of its
own: it only writes the usage record where the stock panel already looks, so
your existing Agents panel grows the provider automatically — nothing is
replaced, patched, or duplicated.

The tab shows:

- **Pay-as-you-go spend** for the current month.
- **Monthly key-cap meter** when the key carries a spending limit (with the
  reset anchored to the first of next month).
- **Tokens by day** (last 7 days) and **tokens by model** (last 30 days).

Data comes from the Requesty management API, authenticated with the same key
the router uses:

| Endpoint | What it provides |
|---|---|
| `GET https://api-v2.requesty.ai/v1/manage/apikey/self` | monthly spend and the key's monthly limit |
| `GET https://api-v2.requesty.ai/v1/manage/apikey/self/usage?…&group_by=model_used` | per-day spend, tokens, and the per-model breakdown |

Without a resolvable credential the tab never appears. A failed fetch keeps the
previous record visible until the next attempt succeeds.

## Requirements

- Omarchy (Hyprland + omarchy-shell)
- A Requesty API key reachable on this machine (an OpenAI-compatible router key
  is enough — no management permission required)

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

## Credential resolution

The key is resolved on every refresh — first hit wins:

1. **`REQUESTY_API_KEY`** environment variable.
2. **OpenCode's credential store** `~/.local/share/opencode/auth.json`, the
   `requesty` entry (read-only).
3. **Manual override file** `~/.config/omarchy/api-keys.env` — plain
   `KEY=value` lines, parsed literally and never sourced:

   ```bash
   install -m 600 /dev/null ~/.config/omarchy/api-keys.env
   printf 'REQUESTY_API_KEY=%s\n' "rq-..." >> ~/.config/omarchy/api-keys.env
   ```

Credential files are only ever read, never written, and the key is sent only to
`api-v2.requesty.ai`.

## Troubleshooting

- **The tab never appears** — no credential resolved. Check what the resolver
  finds, in the same order the service uses:

  ```bash
  bash ~/.config/omarchy/plugins/cliffback.requesty/scripts/update-requesty --resolve
  ```

  Exit code 1 with "no credential resolved" means every tier missed.

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
rm -f ~/.cache/omarchy/requesty-self.json ~/.cache/omarchy/requesty-usage.json
```

## License

[MIT](LICENSE)
