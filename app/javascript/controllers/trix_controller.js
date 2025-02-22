import { Controller } from "@hotwired/stimulus"
import Trix from "trix"

export default class extends Controller {
    connect() {
      // Initial connection
      this.setupEditor()
      
      // Listen for Spark reloads
      document.addEventListener("spark:reload", this.setupEditor.bind(this))
    }
  
    disconnect() {
      document.removeEventListener("spark:reload", this.setupEditor.bind(this))
    }
  
    setupEditor() {
      const editor = this.element.querySelector("trix-editor")
      if (!editor) return
  
      // Store current state
      const input = document.getElementById(editor.input)
      const content = input ? input.value : ''
      
      // Force editor reconnection
      if (editor.editor) {
        requestAnimationFrame(() => {
          editor.editor.loadHTML(content)
        })
      }
    }
  }