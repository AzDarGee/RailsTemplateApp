import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    
    // Create a MutationObserver instead of using DOMNodeInserted
    this.observer = new MutationObserver(this.scrollToBottom)
    
    // Start observing the target node for configured mutations
    this.observer.observe(this.element, {
      childList: true,  // observe direct children
      subtree: true,    // and lower descendants too
    })
  }
  
  disconnect() {
    // Clean up the observer when the controller is disconnected
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  scrollToBottom = () => {
    this.element.scrollTop = this.element.scrollHeight
  }
}