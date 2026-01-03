import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "hiddenInput"]

  compress() {
    this.element.textContent = "Hello World!"
    console.log("Image compress controller connected")
  }
}
