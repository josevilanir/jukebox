# Relatório Técnico: Erro 150 no YouTube IFrame API (Jukebox)

## Descrição do Erro

O erro **150** (e o seu irmão gêmeo **101**) ocorre na YouTube IFrame API quando um vídeo é solicitado para reprodução em um player incorporado (embedded), mas o YouTube recusa o serviço. Na interface do Jukebox, isso se manifesta como uma tela preta com a mensagem "Vídeo Indisponível" ou o redirecionamento para o estado de erro que implementamos.

## Causa Raiz

O erro 150 é disparado quando o **proprietário do vídeo (ou a gravadora, ex: VEVO)** desativou explicitamente a opção de "Permitir incorporação" (Allow embedding) para aquele vídeo específico, ou restringiu a reprodução apenas a domínios específicos.

Diferente do erro 100 (vídeo removido ou privado), o erro 150 é uma **restrição de licenciamento/distribuição**.

## Contexto do Projeto (Jukebox)

No Jukebox, estamos usando a `youtube_iframe_api` via Stimulus.js. Quando o erro ocorre:

1. O evento `onError` captura o código `150`.
2. O controlador `yt_player_controller.js` exibe um aviso visual para o usuário.
3. O sistema pula automaticamente para a próxima música após 3 segundos.

## Tentativas de Solução Aplicadas

1. **Injeção de `origin`**: Adicionamos `origin: window.location.origin` nas `playerVars` da API, o que ajuda o YouTube a validar o domínio, mas não resolve se a gravadora bloqueou incorporação globalmente.
2. **Auto-skip**: Implementamos um _graceful fallback_ para que a fila não trave quando um vídeo desses é adicionado.

## O que pedir para outra IA

Se você for consultar outra IA, pode usar o seguinte prompt:

> "Estou desenvolvendo um Jukebox em Rails 8 com Stimulus.js e YouTube IFrame API. Alguns vídeos (especialmente clipes oficiais VEVO) retornam o Erro 150/101 ao tentar carregar no iframe, informando que o dono do vídeo bloqueou a incorporação. Como posso contornar isso ou validar se um vídeo é 'embeddable' antes de adicioná-lo à fila do usuário usando Ruby ou JavaScript, considerando que não quero usar chaves de API oficiais por enquanto?"
