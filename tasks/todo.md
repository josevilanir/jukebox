# TODO: Jukebox MVP Portfolio Polish

This document outlines the step-by-step plan to transform the current Jukebox project into a visually stunning and robust portfolio piece, emphasizing modern UI/UX, real-time feedback, and clear setup instructions for Linux.

## Phase 1: Environment Setup (Linux / WSL2)

To run this application locally on a fresh Linux installation, follow these steps:

- [ ] **1. Install Prerequisites & Dependencies**
  - Install standard build tools and Libs: `sudo apt-get update && sudo apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev`
  - Install PostgreSQL (Database): `sudo apt-get install -y postgresql postgresql-contrib libpq-dev`
  - Install Node.js & Yarn (for asset compilation if needed):
    - `curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -`
    - `sudo apt-get install -y nodejs`
    - `sudo npm install --global yarn`

- [ ] **2. Install Ruby Environment (via rbenv - Recommended)**
  - Install rbenv: `curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash`
  - Add to shell (e.g., `~/.bashrc` or `~/.zshrc`):
    - `echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc`
    - `echo 'eval "$(rbenv init -)"' >> ~/.bashrc`
    - `source ~/.bashrc`
  - Install ruby: `rbenv install 3.3.0` (adjust version to match `.ruby-version` if it exists, though current default is usually 3.x)
  - Set global ruby: `rbenv global 3.3.0`
  - Install bundler: `gem install bundler`

- [ ] **3. Clone & Bootstrap Project**
  - Clone repository: `git clone <YOUR_REPO_URL> jukebox && cd jukebox`
  - Install Ruby dependencies: `bundle install`
  - Setup database: `bin/rails db:create db:migrate db:seed`
  - Start the dev server: `bin/dev` or `bin/rails s`

## Phase 2: Design System & Core Layout Refactoring (UI/UX Polish)

_Goal: Elevate the app from a basic Rails scaffold to a premium, "Spotify-like" real-time collaborative experience using Tailwind CSS._

- [ ] **1. Global Aesthetics & Layout**
  - Implement a sleek Dark Mode palette as default (deep dark grays/blues, neon accents like hot pink or electric blue for interactions).
  - Update `application.html.erb` layout to use a modern, full-height Flexbox/CSS Grid structure.
  - Implement a persistent, sticky bottom or side navigation/player bar for the "Now Playing" track.

- [ ] **2. Room View Transformation (`rooms/show.html.erb`)**
  - Redesign the Room Header (Dynamic status, clear room code/slug sharing button).
  - Create a prominent "Now Playing" hero section with album art/thumbnail integration (glassmorphism effects).
  - Enhance the "Queue" list: make it scrollable, stylized list items, clear visual hierarchy for tracks.
  - Revamp the Chat: floating side panel or collapsible drawer with distinct user bubbles and timestamp styling.

- [ ] **3. Search & Add Flow (`queue_items/_form.html.erb`)**
  - Build a beautiful, prominent search bar for finding tracks.
  - Design an elegant search results dropdown/modal with thumbnail, title, and an additive "+" button with a micro-animation upon click.

- [ ] **4. Empty States & Onboarding**
  - Design a welcoming Empty State for newly created rooms ("A pista de dança está vazia! Adicione a primeira música").
  - Splash screen or engaging landing page for the root `rooms#index`.

## Phase 3: Real-Time Interactions (Stimulus & Turbo)

_Goal: Make the application feel instantly responsive and alive without page reloads._

- [ ] **1. Micro-animations with Stimulus/Tailwind**
  - Add fade-in/slide-up animations when a new `QueueItem` appears in a room (via Turbo Streams).
  - Implement a satisfying scale/color pop animation on the "Vote/Like" button when clicked.

- [ ] **2. Turbo Stream Optimization**
  - Ensure the Chat appends smoothly at the bottom, automatically scrolling down using a tiny Stimulus controller.
  - Verify that when the Host clicks `play_next`, the UI naturally transitions the top queued track into the "Now Playing" hero spot for all users concurrently.

## Phase 4: Quality & Portfolio Readiness

- [ ] **1. Responsiveness Check**
  - Ensure absolute layout perfection on mobile view (bottom navbar, hidden chat drawer, touch-friendly vote/add buttons).
- [ ] **2. Final Review**
  - Refactor redundant CSS classes into Tailwind components (`@apply`) if necessary for cleanliness.
  - Ensure no logic leakage in views (extracting complex view logic to Helpers or Presenters).
  - Update `README.md` with glowing screenshots, GIFs of real-time interactions, and the setup guide from Phase 1.
