import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loadingIndicator", "buttonText"]

  connect() {
    // Find the form element (parent of the button)
    this.form = this.element.tagName === 'FORM' ? 
                this.element : 
                this.element.closest('form');
    
    if (this.form) {
      this.form.addEventListener("turbo:submit-start", this.showLoading.bind(this))
      this.form.addEventListener("turbo:submit-end", this.hideLoading.bind(this))
    }
  }

  disconnect() {
    // Remove event listeners
    if (this.form) {
      this.form.removeEventListener("turbo:submit-start", this.showLoading.bind(this))
      this.form.removeEventListener("turbo:submit-end", this.hideLoading.bind(this))
    }
  }

  showLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove("d-none")
    }
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.innerHTML = "Creating conversation..."
    }
  }

  hideLoading() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add("d-none")
    }
    if (this.hasButtonTextTarget) {
      this.buttonTextTarget.innerHTML = '<i class="bi bi-plus-circle me-1"></i> Start New Conversation'
    }
  }
} 