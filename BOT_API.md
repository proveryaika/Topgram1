# TopGram Bot API

The Bot API is a TopGram-native HTTP API. It is not compatible with Telegram's servers or Telegram bot tokens.

## Endpoint

`POST https://wcaribszxpmiqwbzgtke.supabase.co/functions/v1/topgram-bot-api`

Headers:

- `apikey: sb_publishable_Huac5EmoI5XUzA-xi3Tw2A_TQpfBGXT`
- `Authorization: Bearer YOUR_TOPGRAM_BOT_TOKEN`
- `Content-Type: application/json`

The publishable key identifies the TopGram project and is safe to include in client examples. The bot token is a secret: keep it on a server or private machine and never commit it to a public repository or put it in browser code.

## Supported methods

### getMe

```json
{ "method": "getMe" }
```

### getUpdates

```json
{ "method": "getUpdates", "limit": 100 }
```

Returns queued messages. After processing an update, send the next request with `offset` set to `update_id + 1` to acknowledge it.

### sendMessage

```json
{
  "method": "sendMessage",
  "chat_id": "CONVERSATION_UUID_FROM_UPDATE",
  "text": "Hello from my TopGram bot!"
}
```

The `chat_id` is the TopGram conversation UUID from `message.chat.id` in an update.

### getWebhookInfo / deleteWebhook

Webhook status is currently empty; `getUpdates` polling is the supported delivery mode.

## Minimal JavaScript polling example

Run this in a private Node.js process or other trusted backend. Replace the token with the token BotFather showed once when creating your bot.

```js
const API = "https://wcaribszxpmiqwbzgtke.supabase.co/functions/v1/topgram-bot-api";
const PROJECT_KEY = "sb_publishable_Huac5EmoI5XUzA-xi3Tw2A_TQpfBGXT";
const BOT_TOKEN = process.env.TOPGRAM_BOT_TOKEN;

async function call(method, extra = {}) {
  const response = await fetch(API, {
    method: "POST",
    headers: {
      apikey: PROJECT_KEY,
      Authorization: `Bearer ${BOT_TOKEN}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ method, ...extra })
  });
  const result = await response.json();
  if (!result.ok) throw new Error(result.description || "TopGram Bot API error");
  return result.result;
}

let offset = 0;

while (true) {
  const updates = await call("getUpdates", { offset, limit: 100 });
  for (const update of updates) {
    offset = update.update_id + 1;
    const message = update.message;
    if (!message?.text) continue;

    await call("sendMessage", {
      chat_id: message.chat.id,
      text: `You wrote: ${message.text}`
    });
  }

  // Short pause between polling requests.
  await new Promise(resolve => setTimeout(resolve, 1000));
}
```

## Current limitations

- Long polling via `getUpdates` is supported; webhooks are not enabled.
- Private chats and group chats can generate updates when the bot is a member.
- In groups, privacy mode is on by default and only slash commands are delivered unless the owner turns it off.
- Inline mode, location requests, Web Apps, Games, file uploads, and Telegram network compatibility are not implemented yet.

## No-code replies in BotFather

You can add simple automatic replies without running a separate bot process. Open the in-app **@BotFather** chat:

- `/setreply @MyBot hello => Hi! I can help you here.` — reply when a message contains `hello`.
- `/setreply @MyBot =hello => Hello!` — exact message match.
- `/setreply @MyBot ^/start => Welcome!` — message starts with `/start`.
- `/myreplies @MyBot` — list saved rules.
- `/delreply @MyBot hello` — delete a rule by its trigger text.

Rules are checked in priority order when a user sends a message in a direct chat or group. In groups, the bot's privacy mode still applies: by default it only receives slash-command messages. Use `/setprivacy @MyBot off` if you want it to process ordinary group messages too.

This is a lightweight rules-based responder, not a general-purpose code runtime. Webhooks, Web Apps, Games, and arbitrary code execution are not supported.
