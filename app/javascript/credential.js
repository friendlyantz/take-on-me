import { showMessage } from "messenger";

function getCSRFToken() {
  var CSRFSelector = document.querySelector('meta[name="csrf-token"]')
  if (CSRFSelector) {
    return CSRFSelector.getAttribute("content")
  } else {
    return null
  }
}

function callback(url, body) {
  fetch(url, {
    method: "POST",
    body: JSON.stringify(body),
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": getCSRFToken()
    },
    credentials: 'same-origin'
  }).then(function(response) {
    if (response.ok) {
      window.location.replace("/")
    } else if (response.status < 500) {
      response.text().then(showMessage);
    } else {
      showMessage("Sorry, something wrong happened.");
    }
  });
}

async function create(callbackUrl, credentialOptions) {
  console.log("Creating new public key credential...");
  
  try {
    // Use native browser API to parse JSON options
    const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(credentialOptions);
    const credential = await navigator.credentials.create({ publicKey });
    
    // Use native toJSON() to serialize the credential
    callback(callbackUrl, credential.toJSON());
  } catch (error) {
    console.error("WebAuthn create error:", error);
    showMessage(`${error.name}: ${error.message}`);
  }
}

async function get(credentialOptions) {
  console.log("Getting public key credential...");
  
  try {
    // Use native browser API to parse JSON options
    const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(credentialOptions);
    const credential = await navigator.credentials.get({ publicKey });
    
    // Use native toJSON() to serialize the credential
    callback("/webauthn/session/callback", credential.toJSON());
  } catch (error) {
    console.error("WebAuthn get error:", error);
    showMessage(`${error.name}: ${error.message}`);
  }
}

// Check if native WebAuthn JSON methods are supported
function supported() {
  return !!window.PublicKeyCredential?.parseCreationOptionsFromJSON;
}

export { create, get, supported }
