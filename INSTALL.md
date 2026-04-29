# OpenClaw – Installations- und Demo-Leitfaden

> Lebendes Dokument für die Präsentation "Einführung in OpenClaw".
> Wird iterativ während der Demo erweitert.

## 1. Was ist OpenClaw?

OpenClaw ist ein **lokal laufender, persönlicher AI-Assistent**. Der Kern
("Gateway") ist die Steuerebene; die eigentliche Bedienung passiert über
bestehende Messaging-Kanäle (Discord, Telegram, Slack, WhatsApp, iMessage,
Matrix, …). Skills steuern, was der Agent tun darf, und liegen als
`SKILL.md`-Verzeichnisse im Workspace.

- Repo: <https://github.com/openclaw/openclaw>
- Docs: <https://docs.openclaw.ai>
- Channel-Übersicht: <https://docs.openclaw.ai/channels>

## 2. Voraussetzungen

| Komponente   | Version                              |
|--------------|--------------------------------------|
| Docker       | 24+ mit Compose v2                   |
| Node.js      | 24 (empfohlen) — im Container fixiert |
| Paketmanager | `pnpm` (alternativ `npm` / `bun`)    |
| OS auf Host  | macOS, Linux oder Windows + WSL2     |

Der Container ist eine **vollwertige Ubuntu-24.04-"Mini-VM"**: persistente
Volumes halten `~/.openclaw` (Workspace, Skills, Sessions) und das geklonte
Repo am Leben — `docker compose down` löscht **nichts**.

## 3. Container starten

```bash
# 1. Env-Datei vorbereiten (Tokens werden später ergänzt)
cp .env.example .env

# 2. Image bauen + Container starten
docker compose up -d --build

# 3. Interaktive Shell öffnen
docker compose exec openclaw bash
```

Sanity-Check innerhalb des Containers:

```bash
node --version    # v24.x
pnpm --version
git --version
```

### Persistenz im Überblick

| Mount-Typ      | Host             | Container                     | Inhalt                                       |
|----------------|------------------|-------------------------------|----------------------------------------------|
| Named Volume   | `openclaw-home`  | `/root`                       | `~/.openclaw/openclaw.json`, History, Caches |
| **Bind Mount** | `./openclaw`     | `/opt/openclaw`               | geklontes OpenClaw-Repo                      |
| **Bind Mount** | `./workspace`    | `/root/.openclaw/workspace`   | Skills, `AGENTS.md`, `SOUL.md`               |

Beide Bind Mounts liegen **direkt im Demo-Repo** und sind aus dem
Host-Editor (VSCode, JetBrains, …) heraus editierbar — Änderungen am
Source sind im Container sofort sichtbar (`pnpm gateway:watch` reloaded
automatisch), neue/geänderte Skills greifen beim nächsten Session-Start
des Agents. Im Onboarding muss der Workspace-Pfad auf dem Default
`~/.openclaw/workspace` belassen werden, damit das Mapping greift.

Backup des Named Volume z. B. via:

```bash
docker run --rm -v openclaw-home:/data -v $PWD:/backup ubuntu \
  tar czf /backup/openclaw-home.tgz -C /data .
```

## 4. OpenClaw installieren (im Container)

Empfohlener Pfad ist das geführte Onboarding:

```bash
# Option A — direkt via npx (kein Repo-Clone nötig)
npx openclaw@latest onboard

# Option B — aus dem Quellbaum (wenn man am Code mitlesen möchte)
# WICHTIG: Clone vom Host aus (Bind Mount), damit der Host-Editor
# das Verzeichnis sieht. Im Repo-Root des Demo-Projekts ausführen:
#   git clone https://github.com/openclaw/openclaw.git ./openclaw
# Danach im Container weiterarbeiten:
cd /opt/openclaw
pnpm install
pnpm openclaw setup
pnpm ui:build
pnpm gateway:watch        # Dev-Loop mit Auto-Reload
# alternativ:
pnpm openclaw onboard --install-daemon
```

Das Onboarding fragt der Reihe nach ab:

1. Pfad für Workspace (Default: `~/.openclaw/workspace`)
2. LLM-Provider + Modell (z. B. `anthropic/claude-opus-4-7`)
3. Channels, die aktiviert werden sollen
4. Skills, die installiert werden

Minimale Konfigurationsdatei `~/.openclaw/openclaw.json`:

```json5
{
  agent: {
    model: "anthropic/claude-opus-4-7",
  },
}
```

## 5. Discord-Integration

> Referenz: <https://docs.openclaw.ai/channels/discord>

1. **Bot anlegen** im
   [Discord Developer Portal](https://discord.com/developers/applications)
   → *New Application* → Tab *Bot* → *Reset Token* → Token kopieren.
2. **Privileged Gateway Intents** aktivieren (mindestens *Message Content
   Intent*).
3. **Bot einladen**: Tab *OAuth2 → URL Generator*, Scopes `bot` +
   `applications.commands`, Bot-Permissions mind. *Send Messages*,
   *Read Message History*. Generierte URL im Browser öffnen, Server wählen.
4. **Token im Container hinterlegen** (`.env` auf dem Host, dann
   `docker compose up -d` damit es injiziert wird):

   ```env
   DISCORD_BOT_TOKEN=MTE...deintoken...
   ```

5. **Channel im Onboarding aktivieren**: `openclaw onboard` neu starten
   oder direkt:

   ```bash
   openclaw channels add discord
   ```

   Dabei werden Bot-Token, erlaubte Server-IDs und Aktivierungsmodus
   (`mention` vs. `always`) abgefragt.
6. **Test**: Bot in einem Server erwähnen — `@OpenClaw status` sollte
   eine Antwort des Gateways zurückspielen.

## 6. Telegram-Integration

> Referenz: <https://docs.openclaw.ai/channels/telegram>

1. **Bot bei @BotFather erstellen**:

   ```text
   /newbot
   Name:     OpenClaw Demo
   Username: openclaw_demo_bot
   ```

   BotFather liefert den HTTP-API-Token.
2. **Privacy-Mode** ggf. abschalten (`/setprivacy → Disable`), falls der
   Bot in Gruppen alle Nachrichten lesen können soll.
3. **Token in `.env` setzen**:

   ```env
   TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
   ```

4. **Channel registrieren**:

   ```bash
   openclaw channels add telegram
   ```

   Allowlist: eigene Telegram-User-ID eintragen
   (zu finden via `@userinfobot`), damit Fremde den Assistenten nicht
   ansprechen können.
5. **Test**: dem Bot eine DM schicken — der Assistent antwortet über das
   Gateway.

## 7. Sicherheits-Notizen für die Demo

- Standardmäßig läuft die `main`-Session **mit Hostzugriff**. Für die Demo
  ok, in Produktion: `agents.defaults.sandbox.mode: "non-main"` setzen,
  damit fremde Channels in Docker-/SSH-Sandboxen laufen.
- Allowlist auf eigene User-IDs / Server-IDs einschränken — sonst kann
  jeder, der den Bot findet, Befehle senden.
- Tokens **nie** ins Git-Repo committen; `.env` steht in `.gitignore`.

## 8. Updates

```bash
docker compose exec openclaw bash -lc "openclaw update --channel stable"
# oder bei Quellbaum-Installation:
docker compose exec openclaw bash -lc "cd /opt/openclaw && git pull && pnpm install && pnpm build"
```

Container-Stack updaten:

```bash
docker compose pull
docker compose up -d --build
```

## 9. Troubleshooting (wird im Live-Test gefüllt)

- [ ] Onboarding-Output dokumentieren
- [ ] Tatsächlichen Gateway-Port eintragen und in `docker-compose.yml`
      freischalten
- [ ] Discord-Channel: Webhook- vs. Bot-Modus klarziehen
- [ ] Telegram-Channel: Long-Polling vs. Webhook im Container

## 10. Roadmap für die Präsentation heute Abend

1. Live `docker compose up` zeigen
2. `openclaw onboard` im Container durchklicken
3. Discord-Bot in Test-Server einladen, Mention demonstrieren
4. Telegram-Bot DM live beantworten lassen
5. Eine Skill (`SKILL.md`) im Workspace zeigen — z. B. eine simple
   "summarise URL"-Skill
6. Persistenz beweisen: `docker compose down && up -d`, Session ist
   weiterhin da
