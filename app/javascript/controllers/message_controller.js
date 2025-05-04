import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log("Message controller connected")
  }
  
  refresh() {
    console.log("Message refreshed")
    // Force content to update if needed
    if (this.hasContentTarget) {
      // You could add additional logic here if needed
      this.contentTarget.classList.add('updated')
      setTimeout(() => {
        this.contentTarget.classList.remove('updated')
      }, 300)
    }
  }
}