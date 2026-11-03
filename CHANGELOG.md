# Changelog — jadlis-signup

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии — [SemVer](https://semver.org/lang/ru/).

## [Unreleased]

## [1.0.0] — 2026-11-03 — Первый выпуск / First release

### Для человека

- Скилл `/jadlis-signup:signup` заводит аккаунт на веб-сервисе: спрашивает данные, один раз подтверждает сводку, создаёт алиас Proton Pass, генерирует пароль в 1Password, заполняет форму через browser-operator и ловит письмо подтверждения.
- Пароль не попадает в контекст модели: браузер берёт его через одноразовый локальный адрес.
- Форма уходит один раз. При сбое скилл сначала смотрит почту и сайт, потом спрашивает тебя.
- Оплату, карту, SMS, непроходимую CAPTCHA и вход через OAuth делаешь ты; OAuth можно разрешить агенту ключом `ALLOW_OAUTH=yes`.
- Скрипт `preflight.sh` проверяет готовность без сети и без секретов.

### For agents

- Added: `skills/signup/SKILL.md` — interview with one confirmation, existing-account check, alias via `proton-alias.sh create`, 1Password item via `op-agent.sh item create --generate-password` (20 chars, id only on stdout), browser-operator with `secret-relay.py serve`, `mail-wait.sh <alias> --folder`, finish with `verified[text]=<date>` on the item.
- Added: `scripts/preflight.sh` — checks `~/.config/jadlis/agent.conf` keys (required `OP_VAULT`, `ALIAS_PREFIX`, `BROWSER_PROFILE`), the five scripts in `~/.claude/scripts/`, `op`/`pass-cli`/`himalaya`/`jq`/`python3` on PATH and the `browser-operator` agent file; exit 1 when anything is missing. Overrides `JADLIS_AGENT_CONF`, `JADLIS_SCRIPTS_DIR` for tests.
- Added: `dependencies` on `jadlis-secrets ^1`, `jadlis-mail ^0.2` (caret on 0.x pins the minor: `>=0.2.0 <0.3.0`), `jadlis-browser ^3`; constraints resolve against `<name>--v<version>` tags.
- Config: reads the shared `agent.conf` contract; no `userConfig`.
