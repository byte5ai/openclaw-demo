# Speaker-Briefing — "Einführung in OpenClaw"

> Live-Demo, Step-by-Step. Jeder Block ist eigenständig commit-bar,
> sodass das Publikum den Fortschritt nachvollziehen kann
> (`git log --oneline`).

## Vorab — 5 Minuten vor Showtime

- [ ] Docker Desktop läuft (`docker version` prüft Daemon)
- [ ] `.env` aus `.env.example` befüllt: `ANTHROPIC_API_KEY` **oder**
      `OPENAI_API_KEY` ist gesetzt
- [ ] Discord Developer Portal in Tab 1 offen
- [ ] Telegram-App auf dem Handy + `@BotFather`-Chat offen
- [ ] Test-Discord-Server bereit, in dem du Admin bist
- [ ] Zwei Terminals nebeneinander: links Host, rechts Container-Shell
- [ ] Editor (VSCode) mit dem Demo-Repo offen — Live-Edits sichtbar
- [ ] Schriftgröße im Terminal hochgedreht (mind. 18pt)

## Roter Faden (Story für 30 min)

1. **Versprechen**: "Lokaler AI-Assistent, antwortet auf Discord und
   Telegram, alles in 25 Minuten — ohne Cloud-Vendor-Lock-in."
2. **Setup als VM**: Wir bauen uns eine saubere Ubuntu-Umgebung
   (Docker), damit das Setup auch nach der Demo reproduzierbar ist.
3. **Onboarding**: OpenClaw fragt uns durch — Modell, Channels, Skills.
4. **Channels**: Discord (Bot-Token) + Telegram (BotFather).
5. **Skill live editieren** vom Host aus → der Bot reagiert anders.
6. **Persistenz**: Container neustarten, alles ist noch da.

## Phase 0 — Repo-Tour (2 min)

```bash
git log --oneline
ls -la
cat docker-compose.yml
```

**Talking Points**

- Zwei Bind Mounts: `./openclaw` (Source) und `./workspace` (Skills).
  Beides editierbar vom Host.
- Ein Named Volume `openclaw-home` für Caches/History — bewusst
  *nicht* in Git, weil dort später Tokens und Session-Daten landen.
- `.env.example` zeigt, welche Tokens wir gleich brauchen.

## Phase 1 — Container starten (3 min)

```bash
cp .env.example .env
docker compose up -d --build
docker compose exec openclaw bash
```

Im Container:

```bash
node --version    # v24.x
pnpm --version
cat /etc/os-release | head -3
```

**Talking Points**

- "Das hier ist eine vollwertige Mini-VM — Ubuntu 24.04, Node 24,
  pnpm, bun, ffmpeg. Alles, was OpenClaw braucht."
- Persistenz erklären: `docker compose down` löscht den Container,
  Volumes bleiben.

## Phase 2 — OpenClaw klonen + onboarden (6 min)

**Auf dem Host** (damit der Editor das Repo sieht):

```bash
git clone https://github.com/openclaw/openclaw.git ./openclaw
```

**Im Container:**

```bash
cd /opt/openclaw
pnpm install            # läuft 60-90 Sek — währenddessen reden!
pnpm openclaw setup
pnpm openclaw onboard --install-daemon
```

**Was beim Onboarding geklickt wird**

| Frage              | Antwort für die Demo                          |
|--------------------|-----------------------------------------------|
| Workspace-Pfad     | `~/.openclaw/workspace` *(Default behalten!)* |
| LLM-Provider       | Anthropic                                     |
| Modell             | `anthropic/claude-opus-4-7`                   |
| API-Key            | aus `.env` per Copy-Paste                     |
| Channels jetzt?    | Nein, wir machen das gleich manuell           |
| Default-Skills     | `web-search`, `read-url`                      |

**Sanity-Check**

```bash
cat ~/.openclaw/openclaw.json
ls ~/.openclaw/workspace/
```

> Wichtiger Reveal-Moment: `ls ./workspace/` **auf dem Host** — die
> gleichen Dateien, weil Bind Mount.

## Phase 3 — Discord-Integration (5 min)

**Im Browser (Discord Developer Portal):**

1. *New Application* → Name "OpenClaw Demo"
2. Tab *Bot* → *Reset Token* → Token in Zwischenablage
3. Privileged Intents: **Message Content Intent** an
4. Tab *OAuth2 → URL Generator*: Scopes `bot`, `applications.commands`;
   Bot Permissions: *Send Messages*, *Read Message History*,
   *View Channels*. URL kopieren → im Browser öffnen → Test-Server
   wählen → *Authorize*.

**Auf dem Host** — Token in `.env` hinterlegen:

```bash
echo "DISCORD_BOT_TOKEN=<token>" >> .env
docker compose up -d        # liest .env neu ein
```

**Im Container** — Channel registrieren:

```bash
openclaw channels add discord
# Token aus Env wird vorgeschlagen, mit Enter bestätigen
# Allowlist: eigene Discord-User-ID (Ctrl+klick auf eigenen Namen
# im Developer Mode → "ID kopieren")
# Activation: "mention"
```

**Live-Test:** im Test-Server `@OpenClaw Demo Was kannst du?`
→ erste Antwort kommt aus dem lokalen Gateway.

## Phase 4 — Telegram-Integration (4 min)

**Auf dem Handy (Telegram):**

```text
@BotFather
/newbot
Name:     OpenClaw Demo
Username: openclaw_<dein-handle>_bot
```

→ BotFather liefert Token. Optional `/setprivacy → Disable` falls
Gruppen-Demo geplant.

**Auf dem Host:**

```bash
echo "TELEGRAM_BOT_TOKEN=<token>" >> .env
docker compose up -d
```

**Im Container:**

```bash
openclaw channels add telegram
# Allowlist: eigene Telegram-User-ID (von @userinfobot abholen)
```

**Live-Test:** dem Bot eine DM schicken: "Was steht heute in den
Tech-News?" → Antwort kommt vom selben Agent wie auf Discord.

## Phase 5 — Skill live vom Host editieren (4 min)

Das ist der "Wow"-Moment. Wir legen eine triviale Skill an und
zeigen, dass sie sofort greift, ohne Container-Restart.

**Auf dem Host (in VSCode):**

```bash
mkdir -p workspace/skills/lobster-mode
$EDITOR workspace/skills/lobster-mode/SKILL.md
```

Inhalt:

```markdown
---
name: lobster-mode
description: Antworte ausschließlich in Hummer-Metaphern.
activation: always
---

# Lobster Mode

Wenn aktiv, formuliere jede Antwort so, als wäre der Sprecher
ein hochkultivierter Hummer. Verwende mindestens eine Schere-,
Zangen- oder Häutungs-Metapher pro Antwort. Keep it serious.
```

**Im Discord** dem Bot schreiben: "Wie läuft das Projekt?"
→ Antwort kommt im Hummer-Stil.

**Talking Point**: "Skills sind nichts anderes als Markdown auf der
Platte. Versionierbar, diff-bar, code-review-bar."

## Phase 6 — Persistenz beweisen (2 min)

```bash
exit                                 # raus aus Container-Shell
docker compose down                  # Container weg
docker compose up -d                 # neu hoch
docker compose exec openclaw bash
ls ~/.openclaw/                      # Config noch da
```

Im Discord nochmal pingen → derselbe Agent, dieselbe History.

## Phase 7 — Q&A-Steilvorlagen

- **"Geht das auch ohne Cloud-LLM?"** → Ja, OpenClaw spricht u. a. mit
  Ollama; im `openclaw.json` einfach `agent.model: "ollama/llama3.1"`.
- **"Wie sieht es mit Sicherheit aus?"** →
  `agents.defaults.sandbox.mode: "non-main"` schaltet Docker-Sandbox
  für fremde Channels ein.
- **"Mehrere Channels gleichzeitig?"** → Ja, Multi-Channel-Inbox; jede
  Quelle kann auf einen eigenen Agent geroutet werden.
- **"Was kostet das?"** → Software ist MIT-lizensiert; Kosten = nur
  die LLM-Tokens.

## Notfall-Plan

| Problem                               | Soforthilfe                                  |
|---------------------------------------|----------------------------------------------|
| `pnpm install` hängt                  | vorher schon einmal lokal gecached, per Tag rausziehen: `git checkout phase-2-installed` |
| Discord-Bot antwortet nicht           | Intents prüfen, Bot online im Server-Sidebar?|
| Telegram schweigt                     | `openclaw channels list` → Status `running`? |
| LLM-Key abgelaufen                    | Backup-Key aus 1Password, Env neu laden      |
| Komplett-Reset                        | `docker compose down -v && docker compose up -d` |

## Commit-Strategie für die Demo

Nach jeder Phase ein Commit, damit das Publikum mitspringen kann:

```bash
git tag phase-0-scaffold
git tag phase-1-container
git tag phase-2-onboarded
git tag phase-3-discord
git tag phase-4-telegram
git tag phase-5-skills
```

So kann jeder Zuschauer hinterher `git checkout phase-3-discord`
machen und an genau der Stelle einsteigen.
