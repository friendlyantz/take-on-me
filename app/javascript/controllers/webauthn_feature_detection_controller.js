import { Controller } from "@hotwired/stimulus";
import { supported } from "credential";

export default class extends Controller {
  static targets = ["message"]

  connect() {
    if (!supported()) {
      this.messageTarget.innerHTML = "This browser doesn't support WebAuthn API";
      this.showUnsupportedView();
    } else {
      PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then((available) => {
        if (!available) {
          this.messageTarget.innerHTML = "We couldn't detect a user-verifying platform authenticator";
          this.showUnsupportedView();
        }
      });
    }
  }

  showUnsupportedView() {
    this.element.classList.remove("hidden");
  }
}

