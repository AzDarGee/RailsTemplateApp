import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.resize()
    this.element.addEventListener("input", this.resize.bind(this))
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  resize() {
    const element = this.element
    element.style.height = "auto"
    element.style.height = (element.scrollHeight) + "px"
  }

  handleKeydown(event) {
    // Submit form on Enter (without Shift)
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.form.requestSubmit()
    }
  }

  disconnect() {
    this.element.removeEventListener("input", this.resize)
    this.element.removeEventListener("keydown", this.handleKeydown)
  }
} 