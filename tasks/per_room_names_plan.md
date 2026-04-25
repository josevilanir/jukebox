# Plano de Implementação: Nomes Específicos por Sala (RoomMemberships)

Este documento detalha as mudanças necessárias para permitir que os usuários escolham nomes (apelidos) diferentes para cada sala que entrarem, substituindo a obrigatoriedade de definir um nome global ao acessar o site.

Este arquivo complementa o checklist em `tasks/todo.md`.

## 1. Visão Geral da Arquitetura

Atualmente, o modelo `User` possui um atributo `name` e um booleano `name_set`. Quando o usuário entra no site, o `ApplicationController` o obriga a definir esse nome global.
Com a nova arquitetura:
- O usuário ainda será criado como um visitante anônimo (`Guest-xxx`).
- O nome global deixará de ser obrigatório para a navegação básica.
- Ao entrar em uma sala (`RoomsController#show`), checaremos se ele possui um `RoomMembership` para aquela sala.
- Se não possuir, o modal de definir nome será exibido *especificamente para aquela sala*.
- Todos os locais que exibem o nome do usuário dentro do contexto da sala buscarão o nome a partir do `RoomMembership`.

---

## 2. Passo a Passo Técnico

### Etapa 1: Banco de Dados e Modelagem
Precisamos da entidade que ligará o Usuário à Sala, armazenando o nome escolhido.

1. **Migration**: 
   `bin/rails g model RoomMembership room:references user:references name:string`
   Editar a migration para adicionar um índice único: `add_index :room_memberships, [:room_id, :user_id], unique: true`.
2. **Model User**: 
   Adicionar `has_many :room_memberships, dependent: :destroy`.
   Adicionar um método helper para buscar o nome facilmente:
   ```ruby
   def name_in(room)
     room_memberships.find_by(room: room)&.name || "Visitante"
   end
   ```
3. **Model Room**: 
   Adicionar `has_many :memberships, class_name: "RoomMembership", dependent: :destroy`.
4. **Model RoomMembership**:
   Adicionar validação: `validates :name, presence: true, length: { maximum: 30 }`.

### Etapa 2: Remoção do Fluxo Antigo (Nome Global)
1. **ApplicationController**:
   Remover o `helper_method :show_name_modal?` e a definição dele.
   Em `ensure_current_user`, podemos simplificar: `User.create!(name: "Guest-#{SecureRandom.hex(3)}")` sem nos importar com `name_set`.
2. **Layout/Views Globais**:
   Remover as chamadas ao modal de nome antigo (que devia estar no `application.html.erb` ou na home).

### Etapa 3: Novo Fluxo de Entrada na Sala
1. **RoomsController#show**:
   Identificar se o usuário já escolheu um nome para a sala.
   ```ruby
   @membership = current_user.room_memberships.find_by(room: @room)
   ```
   Se `@membership` for `nil`, a view `show.html.erb` deve bloquear a interação (chat/player) e exibir um formulário para criar o `RoomMembership`.
2. **RoomMembershipsController (NOVO)**:
   Criar um controller para processar o formulário.
   ```ruby
   def create
     @room = Room.find_by!(slug: params[:room_id])
     membership = current_user.room_memberships.build(room: @room, name: params[:name])
     if membership.save
       redirect_to room_path(@room)
     else
       redirect_to room_path(@room), alert: "Nome inválido."
     end
   end
   ```
   Adicionar a rota no `config/routes.rb`:
   ```ruby
   resources :rooms do
     resources :room_memberships, only: [:create]
   end
   ```

### Etapa 4: Adequação das Views da Sala
Substituir todas as ocorrências de `.name` no contexto da sala para `.name_in(@room)`:
- Em `app/views/messages/_message.html.erb`: `m.user.name_in(@room)`
- Em `app/views/queue_items/_queue_item.html.erb`: `qi.added_by.name_in(@room)`
- Em `app/views/rooms/_player.html.erb`: `current.added_by.name_in(@room)`
- Em `app/views/rooms/_history.html.erb`: `qi.added_by.name_in(@room)`

### Etapa 5: Ajuste dos Canais e Lógica Background
- **PresenceChannel**:
  Quando um usuário se inscreve, salvamos no Redis o seu nome. Esse nome precisa vir de `current_user.name_in(room)` (é preciso passar ou extrair o `room` da conexão).
- **MessagesController**:
  As mensagens de sistema (ex: votação para pular música) devem registrar o nome usando `current_user.name_in(@room)`.

---

## 3. Impacto e Riscos
- **Usuários antigos**: Usuários que já definiram o nome globalmente terão que definir novamente na primeira vez que entrarem em qualquer sala. É um trade-off aceitável para o estágio do projeto.
- **Cache de Presença**: O `PresenceChannel` precisa garantir que o nome seja armazenado corretamente no Redis, o que exigirá instanciar a sala correta no channel.

*Este documento deve ser lido juntamente com `tasks/todo.md`. Uma vez aprovado, cada item do checklist no `todo.md` deve ser marcado conforme a execução deste plano.*
