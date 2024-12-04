# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.12
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.12
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @7.2.200
pin "marked", to: "https://ga.jspm.io/npm:marked@11.1.0/lib/marked.esm.js"
pin_all_from "app/javascript/controllers", under: "controllers"
