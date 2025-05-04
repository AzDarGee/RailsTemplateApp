import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.scrollToBottom()
    
    // Create an observer to watch for new messages
    this.observer = new MutationObserver(this.handleMutation.bind(this))
    
    // Start observing the target node for configured mutations
    if (this.hasContainerTarget) {
      this.observer.observe(this.containerTarget, { 
        childList: true,  // Observe additions/removals of child elements
        subtree: true,    // Observe changes to descendants
        characterData: true, // Observe changes to text content
        attributes: true  // Observe changes to attributes
      })
    }
  }
  
  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
  
  handleMutation(mutations) {
    // When new messages are added, scroll to bottom
    this.scrollToBottom()
  }
  
  scrollToBottom() {
    if (this.hasContainerTarget) {
      this.containerTarget.scrollTop = this.containerTarget.scrollHeight
    }
  }
} 