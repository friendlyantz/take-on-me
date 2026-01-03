# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@7.1.2/app/assets/javascripts/rails-ujs.esm.js"
pin "credential"
pin "messenger"

pin "@material/list", to: "https://ga.jspm.io/npm:@material/list@4.0.0/dist/mdc.list.js"
pin "@material/menu", to: "https://ga.jspm.io/npm:@material/menu@4.0.0/dist/mdc.menu.js"
pin "@material/snackbar", to: "https://ga.jspm.io/npm:@material/snackbar@4.0.0/dist/mdc.snackbar.js"
pin "@material/textfield", to: "https://ga.jspm.io/npm:@material/textfield@4.0.0/dist/mdc.textfield.js"
pin "@material/top-app-bar", to: "https://ga.jspm.io/npm:@material/top-app-bar@4.0.0/dist/mdc.topAppBar.js"
pin "@github/webauthn-json", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.js"

pin "diff" # @8.0.2
pin "isarray" # @2.0.5
pin "just-extend" # @6.2.0
pin "lodash.get", to: "https://ga.jspm.io/npm:lodash.get@4.4.2/index.js"
pin "nise" # @6.1.1
pin "path-to-regexp" # @8.3.0
pin "process" # @2.1.0
pin "supports-color" # @10.2.2
pin "type-detect" # @4.1.0
pin "util", to: "https://ga.jspm.io/npm:@jspm/core@2.0.1/nodelibs/browser/util.js"

pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"
