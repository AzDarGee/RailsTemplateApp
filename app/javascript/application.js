// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"
import "@fortawesome/fontawesome-free/js/all.js"
import * as bootstrap from "bootstrap"

// Trix Editor
import "trix"
import "@rails/actiontext"

console.log("Application.js loaded!!!!!!!")

// Debug Turbo Streams
document.addEventListener("turbo:before-stream-render", function(event) {
  console.log("Turbo stream render:", event.target);
})