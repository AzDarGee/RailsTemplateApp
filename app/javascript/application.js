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
