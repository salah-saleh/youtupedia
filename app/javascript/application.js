import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Disable Turbo prefetching globally
document.documentElement.setAttribute('data-turbo-prefetch', 'false')

const application = Application.start()

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
