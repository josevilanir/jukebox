#!/bin/bash
# =============================================================================
# Script de Deploy — Jukebox → Fly.io + Neon
# Execute este script na pasta ~/Projetos/jukebox no SEU TERMINAL
# =============================================================================
set -e

echo "🚀 Iniciando deploy do Jukebox..."

# --- PASSO 1: Verificar fly CLI ---
if ! command -v fly &>/dev/null; then
  echo "❌ fly CLI não encontrado. Instalando..."
  curl -L https://fly.io/install.sh | sh
  export PATH="$HOME/.fly/bin:$PATH"
fi
echo "✅ fly CLI: $(fly version)"

# --- PASSO 2: Verificar autenticação ---
if ! fly auth whoami &>/dev/null; then
  echo "🔑 Fazendo login no Fly.io (vai abrir o browser)..."
  fly auth login
fi
echo "✅ Autenticado como: $(fly auth whoami)"

# --- PASSO 3: Criar o app (se não existir) ---
if fly apps list | grep -q "^jukebox "; then
  echo "✅ App 'jukebox' já existe."
else
  echo "📦 Criando app 'jukebox' na região GRU (São Paulo)..."
  fly apps create jukebox --org personal 2>/dev/null || {
    echo "⚠️  Nome 'jukebox' indisponível. Tentando 'jukebox-app'..."
    fly apps create jukebox-app --org personal
    # Atualiza o nome no fly.toml
    sed -i 's/^app = "jukebox"/app = "jukebox-app"/' fly.toml
    echo "✅ Nome atualizado para 'jukebox-app' no fly.toml"
  }
fi

# --- PASSO 4: Configurar secrets ---
echo "🔐 Configurando secrets no Fly.io..."
fly secrets set \
  DATABASE_URL="postgresql://neondb_owner:npg_aKl1usAzvew7@ep-long-wind-aciz2s9q.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require" \
  RAILS_MASTER_KEY="124a9382c24724d4564bf1bbd82185b7bd4c4862293611091538dd5eae304cb1" \
  SECRET_KEY_BASE="865ef170888187402be244541696bfd47104e0db2a428f13a40dcecf71de44f23aaa254c71aa016b0dddebd8c46f7a16cf62a838b5d34c84fcebd5701cf5542c"

echo "✅ Secrets configurados."

# --- PASSO 5: Deploy ---
echo "🏗️  Iniciando build e deploy (pode demorar 3-5 min)..."
fly deploy

# --- PASSO 6: Verificar ---
echo ""
echo "✅ Deploy concluído!"
fly status
echo ""
echo "🌐 Abrindo o app..."
fly open
