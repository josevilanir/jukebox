# =============================================================================
# Script de Deploy — Jukebox → Fly.io + Neon  (PowerShell / Windows)
# Execute no PowerShell dentro da pasta C:\Users\vilan\jukebox
# =============================================================================
$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando deploy do Jukebox..." -ForegroundColor Cyan

# --- PASSO 1: Verificar fly CLI ---
$flyPath = Get-Command fly -ErrorAction SilentlyContinue
if (-not $flyPath) {
    Write-Host "❌ fly CLI não encontrado. Instalando via PowerShell..." -ForegroundColor Yellow
    powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
    # Recarregar PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
}
Write-Host "✅ fly CLI encontrado." -ForegroundColor Green
fly version

# --- PASSO 2: Verificar autenticação ---
$whoami = fly auth whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "🔑 Fazendo login no Fly.io (vai abrir o browser)..." -ForegroundColor Yellow
    fly auth login
}
Write-Host "✅ Autenticado: $whoami" -ForegroundColor Green

# --- PASSO 3: Criar o app ---
$apps = fly apps list 2>&1
$appName = "jukebox"
if ($apps -match "jukebox\s") {
    Write-Host "✅ App '$appName' já existe." -ForegroundColor Green
} else {
    Write-Host "📦 Criando app '$appName' na região GRU (São Paulo)..." -ForegroundColor Cyan
    fly apps create $appName --org personal
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Nome 'jukebox' indisponível. Usando 'jukebox-app'..." -ForegroundColor Yellow
        $appName = "jukebox-app"
        fly apps create $appName --org personal
        (Get-Content fly.toml) -replace 'app = "jukebox"', "app = `"$appName`"" | Set-Content fly.toml
        Write-Host "✅ fly.toml atualizado para '$appName'" -ForegroundColor Green
    }
}

# --- PASSO 4: Configurar secrets ---
Write-Host "🔐 Configurando secrets no Fly.io..." -ForegroundColor Cyan
fly secrets set `
    DATABASE_URL="postgresql://neondb_owner:npg_aKl1usAzvew7@ep-long-wind-aciz2s9q.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require" `
    RAILS_MASTER_KEY="124a9382c24724d4564bf1bbd82185b7bd4c4862293611091538dd5eae304cb1" `
    SECRET_KEY_BASE="865ef170888187402be244541696bfd47104e0db2a428f13a40dcecf71de44f23aaa254c71aa016b0dddebd8c46f7a16cf62a838b5d34c84fcebd5701cf5542c"

Write-Host "✅ Secrets configurados." -ForegroundColor Green

# --- PASSO 5: Deploy ---
Write-Host "🏗️  Iniciando build e deploy (pode demorar 3-5 min)..." -ForegroundColor Cyan
fly deploy

# --- PASSO 6: Verificar ---
Write-Host ""
Write-Host "✅ Deploy concluído!" -ForegroundColor Green
fly status
Write-Host ""
Write-Host "🌐 Abrindo o app..." -ForegroundColor Cyan
fly open
