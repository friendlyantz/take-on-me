import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  nativeShare() {
    if (navigator.share) {
      navigator.share({ title: "Join My Challenge", url: this.urlValue })
    }
  }

}