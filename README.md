# Jukebox 🎧

[![CI](https://github.com/josevilanir/jukebox/actions/workflows/ci.yml/badge.svg)](https://github.com/josevilanir/jukebox/actions/workflows/ci.yml)

Sala de música colaborativa em tempo real. Crie uma sala, convide amigos e
deixem a galera votar na próxima música — nada de DJ ditador.

---

## Stack

- **Ruby on Rails 8** com Hotwire (Turbo + Stimulus) — zero React, zero API separada
- **ActionCable** (solid_cable) para WebSockets
- **solid_cache** para presença em tempo real e locks distribuídos
- **PostgreSQL** como banco principal
- **YouTube IFrame API** para reprodução sincronizada
- **Tailwind CSS** para estilização

---

## Funcionalidades

### 🎵 Player sincronizado
Todos os usuários na sala ouvem a mesma música no mesmo momento. Ao entrar
numa sala com música tocando, o player faz seek automático para a posição
correta usando o `started_at` persistido no banco.

### 👥 Presença em tempo real
Contador de "N pessoas ouvindo" atualizado via ActionCable. Usa um hash de
timestamps no `solid_cache` com heartbeat a cada 30s — sem Redis, sem
tabela extra no banco.

### ⏭ Votação de skip democrática
Qualquer usuário pode votar para pular a música atual. Ao atingir 50% dos
presentes (mínimo 2 votos), a música é pulada automaticamente para todos.

### 🎛 Modo DJ
Host pode ativar o Modo DJ para permitir que qualquer usuário avance a fila.
Ativa automaticamente quando o host sai da sala (detectado via presença).

### 🔍 Busca integrada do YouTube
Busca sem API key usando scraping do `ytInitialData` com debounce no frontend.
Valida embeddability via oEmbed antes de adicionar à fila.

### 🗳 Sistema de upvotes na fila
Músicas com mais votos sobem na fila. Ordenação por score + timestamp de
adição como tiebreaker.

---

## Arquitetura e decisões técnicas

### Presença sem Redis

A maioria dos tutoriais de presença em Rails usa Redis como store. Aqui a
solução usa `solid_cache` (SQLite/PG) com um hash por sala:

```ruby
# presence:rock-room => { "42" => { name: "João", at: 1234567890 }, ... }
Rails.cache.write("presence:#{slug}", set, expires_in: 1.hour)
```

Cada conexão WebSocket renova seu timestamp a cada 30s. Entradas com mais de
40s sem heartbeat são consideradas offline. O método `PresenceChannel.user_count`
é chamado pelo `SkipVote` para calcular o threshold — presença como dado
de negócio, não só UI.

Para reduzir race conditions no read-modify-write, um lock leve por sala
usa `unless_exist: true` com TTL de 2s e 3 tentativas com backoff aleatório.

### Seek sync via started_at

O problema clássico de sincronização de vídeo: usuário B entra numa sala
onde usuário A está assistindo no segundo 1:23. Como sincronizar?

Solução: ao avançar para uma música, `Room#advance!` persiste `started_at`
no `QueueItem`. O player calcula `elapsed = now - started_at` e chama
`seekTo(elapsed)`. O host pode também ajustar a posição via controles
+15s/-15s, que fazem broadcast do novo `started_at` para todos via
Turbo Stream.

### Fila ordenada por score sem N+1

```ruby
def queue_open
  queue_items.where(played_at: nil)
             .left_joins(:votes)
             .select("queue_items.*, COALESCE(SUM(votes.value),0) AS score")
             .group("queue_items.id")
             .order("score DESC, queue_items.created_at ASC")
end
```

Uma query só — sem `counter_cache`, sem callbacks de reordenação.

### Modo DJ com memoização

`can_advance?` chama `dj_mode_active?` que chama `host_online?`, que lê
o cache. Como a view chama isso múltiplas vezes por render, `host_online?`
usa `defined?(@host_online)` para memoizar corretamente (inclusive quando
o valor é `false`).

---

## Setup local

```bash
git clone https://github.com/josevilanir/jukebox
cd jukebox
bundle install
bin/rails db:setup
bin/dev
```

Acesse `http://localhost:3000`.

---

## Testes

```bash
bin/rails test          # model + controller tests
bin/rails test:system   # system tests com headless Chrome
```

Cobertura: lógica de negócio crítica (`Room`, `SkipVote`, `User`) e
fluxos principais via Capybara (criação de sala, modal de nome, acesso
a sala fechada, votação).

---

## Estrutura de arquivos relevantes

```
app/
├── channels/
│   └── presence_channel.rb      # WebSocket de presença
├── models/
│   ├── room.rb                  # can_advance?, host_online?, advance!
│   ├── skip_vote.rb             # check_threshold com lógica de presença
│   └── queue_item.rb            # score via SQL, broadcast de updates
├── services/
│   └── youtube_search_service.rb  # scraping ytInitialData + oEmbed check
└── javascript/controllers/
    ├── yt_player_controller.js  # YouTube IFrame API + seek sync
    ├── presence_controller.js   # heartbeat a cada 30s
    └── youtube_search_controller.js  # debounce na busca
```

---

## Load Testing

O endpoint ActionCable (`PresenceChannel` + Solid Cable sobre Postgres) foi
benchmarked com [K6](https://k6.io/) simulando até 100 conexões WebSocket
simultâneas com heartbeat a cada 30 s.

Veja [`load_test/README.md`](load_test/README.md) para instruções de execução
e a tabela de resultados.

```bash
# execução rápida (servidor local rodando)
k6 run load_test/websocket_test.js

# contra produção
k6 run -e BASE_URL=wss://your-app.fly.dev load_test/websocket_test.js
```

---

## O que eu implementaria a seguir

- **Rate limiting** na busca do YouTube por IP (hoje sem proteção)
- **Histórico paginado** da sala (`/rooms/:slug/history`)
- **Testes de channel** para o `PresenceChannel`
- **Migração para Redis** se escalar (trocar lock por `SET NX EX`)
