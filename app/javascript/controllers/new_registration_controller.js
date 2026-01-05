import { Controller } from "@hotwired/stimulus"
import * as Credential from "credential";

import { MDCTextField } from '@material/textfield';

export default class extends Controller {
  static targets = ["usernameField"]

  create(event) {
    var [data, status, xhr] = event.detail;
    console.log(data);
    var credentialOptions = data;

    // Registration
    if (credentialOptions["user"]) {
      var credential_nickname = event.target.querySelector("input[name='registration[nickname]']").value;
      var callback_url = `/webauthn/registration/callback?credential_nickname=${credential_nickname}`

      Credential.create(encodeURI(callback_url), credentialOptions);
    }
  }

  error(event) {
    let response = event.detail[0];
    console.log("Registration error:", response);
    
    // Display error in helper text
    let helperText = this.element.querySelector('.mdc-text-field-helper-text');
    if (helperText && response["errors"] && response["errors"].length > 0) {
      helperText.textContent = response["errors"][0];
      helperText.classList.add('mdc-text-field-helper-text--persistent');
    }
    
    // Mark field as invalid
    let usernameField = new MDCTextField(this.usernameFieldTarget);
    usernameField.valid = false;
  }
}
