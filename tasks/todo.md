# TODO: Feature — Busca Integrada do YouTube (MVP)

## Planejamento

- [x] Criar VPM/Plano de implementação
- [x] Revisar plano com o usuário

## Backend (Acesso à API & Controller)

- [x] Adicionar serviço Keyless usando `ytInitialData`.
- [x] Criar `YoutubeSearchService` para abstrair a busca `YoutubeSearchService.search("query")`.
- [x] Criar `Room::SearchesController#index/show` para responder com Turbo Stream os resultados.

## Frontend (UI & Turbo Streams)

- [x] Atualizar o formulário em `_form.html.erb` para ter uma barra de busca interativa (usando Hotwire/Stimulus + Turbo).
- [x] Criar turbo stream view para exibir vídeos, thumbnails e durações.
- [x] Criar stimulus controller `youtube_search_controller.js` com _debounce_ para ir digitando e buscando auto.

## Criação do Item e Refinamento

- [x] Ajustar `QueueItemsController#create` para poder receber `youtube_id`, `title` e `thumbnail_url` direto dos resultados.
- [x] Implementar fallback "Estou com Sorte" (pesquisa por texto se não for URL).
- [x] Corrigir infraestrutura do ActionCable (módulos de Connection e Channel).
- [x] Implementar tratamento visual de erros de Embed (Erro 150) com auto-skip.
- [x] Corrigir carregamento de controllers Stimulus (reverter quebra do Importmap).

---

# TODO: Feature — Rate Limiting Defensivo (rack-attack)

## Plano

- [x] Adicionar gem `rack-attack` ao Gemfile e rodar `bundle install`
- [x] Criar `config/initializers/rack_attack.rb` com throttles para search e criação de salas
- [x] Configurar cache store do rack-attack para usar Rails.cache (solid_cache em prod)
- [x] Tratar resposta 429 com mensagem amigável + header Retry-After
- [x] Rodar testes — 25/25 passando, 0 falhas
