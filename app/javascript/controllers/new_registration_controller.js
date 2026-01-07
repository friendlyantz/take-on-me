import { Controller } from "@hotwired/stimulus"
import * as Credential from "credential";

import { MDCTextField } from '@material/textfield';

export default class extends Controller {
  static targets = ["usernameField", "submitButton"]

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
        return response.json().then(data => this.handleSuccess(data, form));
      } else {
        return response.json().then(data => this.handleError(data, submitButton));
      }
    })
    .catch(error => {
      console.error("Form submission error:", error);
      if (submitButton) submitButton.disabled = false;
    });
  }

  handleSuccess(data, form) {
    console.log("Registration options:", data);
    
    // Registration - check for user object in response
    if (data.user) {
      const credential_nickname = form.querySelector("input[name='registration[nickname]']").value;
      const callback_url = `/webauthn/registration/callback?credential_nickname=${encodeURIComponent(credential_nickname)}`;
      
      Credential.create(callback_url, data);
    }
  }

  handleError(response, submitButton) {
    console.log("Registration error:", response);
    
    // Re-enable submit button
    if (submitButton) submitButton.disabled = false;
    
    // Display error in helper text
    let helperText = this.element.querySelector('.mdc-text-field-helper-text');
    if (helperText && response.errors && response.errors.length > 0) {
      helperText.textContent = response.errors[0];
      helperText.classList.add('mdc-text-field-helper-text--persistent');
    }
    
    // Mark field as invalid
    if (this.hasUsernameFieldTarget) {
      let usernameField = new MDCTextField(this.usernameFieldTarget);
      usernameField.valid = false;
    }
  }
}
