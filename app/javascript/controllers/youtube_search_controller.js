import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "results"];
  static values = { url: String };

  connect() {
    this.timeout = null;
    this.canSubmitForm = false;
  }

  preventFormSubmit(event) {
    if (!this.canSubmitForm) {
      event.preventDefault();
      this.perform();
    }
  }

  allowSubmit() {
    this.canSubmitForm = true;
  }

  preventSubmit(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.perform();
    }
  }

  perform() {
    clearTimeout(this.timeout);

    const query = this.inputTarget.value.trim();

    if (query.length === 0) {
      this.resultsTarget.innerHTML = "";
      return;
    }

    this.timeout = setTimeout(() => {
      const form = this.element;
      // Build proper URL with query param
      const url = new URL(this.urlValue, window.location.origin);
      url.searchParams.set("query", query);

      fetch(url.toString(), {
        headers: {
          Accept: "text/vnd.turbo-stream.html",
        },
      })
        .then((response) => response.text())
        .then((html) => Turbo.renderStreamMessage(html));
    }, 400); // 400ms debounce
  }

  clear() {
    // Esconder resultados ao clicar para adicionar a música
    setTimeout(() => {
      this.inputTarget.value = "";
      this.resultsTarget.innerHTML = "";
    }, 100);
  }
}
