[Русский](README.md) · English

# The agent signs you up on a web service: its own alias, the password in 1Password, the confirmation mail

The `/signup` skill for Claude Code creates an account on a new service. First it asks which data
to enter and confirms them with you once. Then it creates a separate Proton Pass alias for the
service and generates the password right inside 1Password. The browser-operator agent fills the
form, and the skill catches the confirmation mail itself. The password never enters the model's
context.

```
claude plugin marketplace add https://github.com/beCyborg/jadlis-hub.git
claude plugin install jadlis-signup@jadlis
```

## Why

Signing up for a new service eats attention: pick an address, invent a password, store it, fill
the form, wait for the mail, click the link. The skill does it and keeps things in order:

| Problem | What the skill does |
|---|---|
| One address everywhere, spam and leaks | A separate alias `<prefix>-<service>` in Proton Pass per service |
| A password to invent and not lose | 1Password generates a 20-character password and stores the login at once |
| The password shows up in chat or the clipboard | The browser fetches it from a one-shot local address; the model never sees it |
| The form sent twice, two accounts | The form goes out once; when in doubt the skill checks the mail and the site first |
| The confirmation mail gets lost | The skill waits for the mail, takes the link or code and finishes the sign-up |

## What it looks like

You write: "sign me up on example.com, free plan". Then:

1. The skill asks one question: sign-up page URL, name for the form, plan, login method. You
   confirm the summary.
2. The skill checks that no account exists yet and creates the alias `agent-example`.
3. 1Password creates an item with a 20-character password. The skill keeps its id.
4. The browser-operator agent fills the form in its own Chrome profile and submits it once.
5. The skill waits for the mail to the alias and opens the confirmation link or enters the code.
6. The skill checks that the account works, marks the 1Password item `verified` with the date and
   sends a report: service, alias, item id. The report holds no password.

Payment, card binding, SMS, a CAPTCHA the agent cannot pass, and sign-in with Google or GitHub are
yours. The skill leaves the right page open and waits.

## Installing

You need Claude Code on macOS and three dependency plugins. Claude Code installs them together
with the skill:

| Plugin | What it gives |
|---|---|
| `jadlis-secrets` | `op-agent.sh`, `secret-relay.py`, `proton-alias.sh` and the `agent.conf.example` template |
| `jadlis-mail` | `mail-wait.sh` and `jm` on top of himalaya: wait for a mail and read it |
| `jadlis-browser` | the `browser-operator` agent template and `agent-chrome.sh` for its own Chrome profile |

You also need your own accounts and tools:

- a Proton Pass account and `pass-cli`;
- a 1Password service account with write access to a dedicated vault, and `op`;
- the mailbox that receives alias mail, connected to `jm` (for Proton — through Proton Mail Bridge);
- `jq` and `python3`.

Install steps:

1. Install the plugin with the commands above. If the dependencies did not come along, install
   them the same way: `claude plugin install jadlis-secrets@jadlis` and so on.
2. Run each dependency's install step from its README: the scripts go to `~/.claude/scripts/`,
   the `browser-operator` agent goes to `~/.claude/agents/`.
3. Copy `agent.conf.example` from jadlis-secrets to `~/.config/jadlis/agent.conf` and fill it in.
4. Check readiness:

```
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/jadlis/jadlis-signup/*/scripts/preflight.sh
```

Or ask Claude: "/jadlis-signup:signup check readiness". The script makes no network calls and
reads no secrets. It prints a checklist and marks what is missing. Exit code 1 means something is
not ready.

The skill reads these keys from `agent.conf`:

| Key | Purpose | If empty |
|---|---|---|
| `OP_VAULT` | 1Password vault for new logins | required |
| `ALIAS_PREFIX` | alias `<ALIAS_PREFIX>-<service>` | required |
| `BROWSER_PROFILE` | Chrome profile for browser-operator | required |
| `MAIL_ACCOUNT` | `jm` account that receives alias mail | the default `jm` account |
| `MAIL_FOLDER` | folder to wait in | `All Mail` |
| `SIGNUP_NAME` | name for the form | the skill asks |
| `ALLOW_OAUTH` | `yes` lets the agent sign in with Google or GitHub | OAuth sign-in is yours |

Remove: `claude plugin uninstall jadlis-signup@jadlis`.

## Using it

Type in Claude Code:

```
/jadlis-signup:signup sign me up on example.com
```

Or say it in your own words: "create an account on …", "I need an account at …", "register on …".
The skill asks one question and confirms the summary. After that it works on its own and stops
only at your steps.

If 1Password already holds an account for this service or the alias already exists, the skill
says so and reuses them. It never creates a second account.

## Limits and cost

**What it does not do.** It does not pay, enter a card, pass SMS verification or sign in with
OAuth without permission in `agent.conf`. It never submits the form a second time: after a
failure it checks the mail and the site first. It does not sort mail — that is jadlis-mail. It
does not look up existing passwords — that is jadlis-secrets.

**What it costs.** One sign-up is a few Bash calls and one browser-operator agent. The agent uses
most of the tokens from your Claude Code quota. The skill needs no money beyond your Claude Code,
1Password and Proton subscriptions.

**Tested:** `preflight.sh` syntax in bash and zsh, a preflight run on a Mac, `claude plugin
validate --strict`. No live sign-up has run on this version yet: the flow is ported from a working
skill that signed accounts up on services. Not tested on other machines — if it does not install,
open an issue.
