import { Controller } from "@hotwired/stimulus"
import * as Credential from "credential";

import { MDCTextField } from '@material/textfield';

export default class extends Controller {
  static targets = ["usernameField"]

  submit(event) {
    event.preventDefault();
    
    const form = event.target;
    const formData = new FormData(form);
    const submitButton = form.querySelector('[type="submit"]');
    
    // Disable button during submission
    if (submitButton) submitButton.disabled = true;
    
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
        return response.json().then(data => this.handleError(data, submitButton));
      }
    })
    .catch(error => {
      console.error("Form submission error:", error);
      if (submitButton) submitButton.disabled = false;
    });
  }

  handleSuccess(data) {
    console.log("Session options:", data);
    Credential.get(data);
  }

  handleError(response, submitButton) {
    console.log("Session error:", response);
    
    // Re-enable submit button
    if (submitButton) submitButton.disabled = false;
    
    if (this.hasUsernameFieldTarget) {
      let usernameField = new MDCTextField(this.usernameFieldTarget);
      usernameField.valid = false;
      if (response.errors && response.errors[0]) {
        usernameField.helperTextContent = response.errors[0];
      }
    }
  }
}
