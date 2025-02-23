// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"
import "@fortawesome/fontawesome-free/js/all.js"
import * as bootstrap from "bootstrap"

// Trix Editor
import "trix"
import "@rails/actiontext"
  
// Ensure Trix is reinitialized after Spark reloads
document.addEventListener("spark:reload", () => {
    window.requestAnimationFrame(() => {
        document.querySelectorAll("trix-editor").forEach(editor => {
        const event = new Event("trix-initialize")
        editor.dispatchEvent(event)
        console.log("Trix initialized")
        })
    })
})

// Handle Turbo errors and disconnections
document.addEventListener("turbo:load", () => {
    // Clear any pending requests
    if (window.Turbo) {
        window.Turbo.session.connectStreamSource = function(source) {
        if (source instanceof WebSocket) {
            source.addEventListener("message", (event) => {
            try {
                this.receiveMessageResponse(event.data)
            } catch (error) {
                console.error("Turbo stream error:", error)
            }
            })
        }
        }
    }
})

// Handle Spark reconnection
document.addEventListener("spark:disconnect", () => {
    console.log("Spark disconnected, attempting reconnect...")
    setTimeout(() => {
        window.location.reload()
    }, 1000)
})

// Handle message channel errors
document.addEventListener("turbo:before-fetch-response", (event) => {
    const response = event.detail?.fetchResponse
    if (response?.failed) {
        console.warn("Turbo fetch failed, preventing default")
        event.preventDefault()
    }
})

console.log("Application.js loaded!!!!!!!")