# Lessons Learned

This file contains the history of patterns, corrected mistakes, and rules to prevent recurrence, as per GEMINI.MD.

## Rules & Patterns

### Never call `.count` on a relation with a custom SELECT aggregate

`queue_open` uses `select("queue_items.*, COALESCE(SUM(votes.value),0) AS score")`.
Calling `.count` on it generates `COUNT(queue_items.*, COALESCE(...) AS score)` which is invalid PostgreSQL.
Use `.length` (loads records, counts in Ruby) or `.any?` / `.none?` instead.

### Windows Rails Server Startup and Stale PIDs

When working with Rails on Windows using a custom `bin\dev.cmd` wrapper (bypassing Foreman due to signal handling issues), closing the terminal window forcefully kills the processes but leaves behind the `tmp/pids/server.pid` file.
Before starting the Puma server in `dev.cmd` or manually, always ensure the stale `server.pid` file is removed, otherwise it will throw an `A server is already running` error. `dev.cmd` was updated to automate this cleanup.

### Prevent Enter Key Submission on Search Inputs inside Forms

When placing a search input field (`<input type="text">`) inside a main `<form>` (like the "Adicionar Música" form onde preencher a URL é uma opção), pressionar `Enter` nativamente dispara o submit (ou o primeiro botão submit disponível). Em vez de tentar interceptar `keydown` (que as vezes o browser/Turbo atropela), a forma mais robusta em Stimulus é:

1. Escute o evento `submit` do form: `data-action="submit->seu-controller#preventFormSubmit"`.
2. Adicione uma action no botão de submit real: `data-action="click->seu-controller#allowSubmit"`.
3. No controller, crie uma flag `this.canSubmitForm = false;` no `connect()`.
4. Em `allowSubmit()`, vire a flag pra `true`.
5. Em `preventFormSubmit(event)`, se `!this.canSubmitForm`, dê `event.preventDefault()` e execute a busca manual (`this.perform()`).

### Never run `bin/rails stimulus:manifest:update` on Importmap projects

In projects using `importmap-rails`, the file `app/javascript/controllers/index.js` uses `@hotwired/stimulus-loading` with `eagerLoadControllersFrom("controllers", application)`.
Running the command `bin/rails stimulus:manifest:update` destroys this file and rewrites it in the ESBuild/Webpack style (`import X from "./x_controller"`). Since browsers do not magically resolve `.js` extensions or asset digests natively, this completely breaks all Stimulus controllers on the site, throwing multiple 404 errors in the browser console.
If you create a controller, it is automatically pinned by the `pin_all_from` directive in `importmap.rb`. You don't need to run any update commands in Importmap projects.
