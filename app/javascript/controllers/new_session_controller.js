import { Controller } from "@hotwired/stimulus"
import * as Credential from "credential";

import { MDCTextField } from '@material/textfield';

export default class extends Controller {
  static targets = ["usernameField", "form"]

  submit(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    
    fetch(form.action, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "application/json"
      },
      credentials: "same-origin"
    })
    .then(response => {
      if (response.ok) {
        return response.json().then(data => this.handleSuccess(data));
      } else {
        return response.json().then(data => this.handleError(data));
      }
    })
    .catch(error => {
      console.error("Form submission error:", error);
    });
  }

  handleSuccess(data) {
    console.log("Session options:", data);
    Credential.get(data);
  }

  handleError(response) {
    console.log("Session error:", response);
    if (this.hasUsernameFieldTarget) {
      let usernameField = new MDCTextField(this.usernameFieldTarget);
      usernameField.valid = false;
      if (response.errors && response.errors[0]) {
        usernameField.helperTextContent = response.errors[0];
      }
    }
  }
}
