import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { 
    target: String
  }

  connect() {
    // Initialize the collapse state
    this.element.addEventListener('click', this.toggle.bind(this))
  }

  toggle(event) {
    event.preventDefault()
    
    let targetId = this.targetValue || this.element.getAttribute('data-collapse-target')
    let target = document.getElementById(targetId)
    
    if (target) {
      if (target.classList.contains('show')) {
        target.classList.remove('show')
      } else {
        target.classList.add('show')
      }
    }
  }
} 