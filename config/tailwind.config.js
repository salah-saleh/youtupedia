/**
 * Tailwind CSS Configuration
 *
 * This configuration file controls how Tailwind processes and generates CSS.
 * It's automatically loaded by the tailwindcss-rails gem.
 *
 * Development:
 * - Run with: bin/dev (starts both Rails and Tailwind processes)
 * - Changes are watched and CSS is recompiled automatically
 *
 * Production:
 * - CSS is compiled during asset precompilation
 * - Only used classes are included in the final bundle
 * - Requires config.assets.css_compressor = nil in config/application.rb
 */

// Import default theme settings from Tailwind
const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  // Enable dark mode using class strategy instead of media queries
  // This allows for manual dark mode toggle
  darkMode: 'class',

  // Define which files Tailwind should scan for class usage
  // Only classes used in these files will be included in the final CSS
  content: [
    './public/*.html',          // Static HTML files
    './app/helpers/**/*.rb',    // Ruby helper methods
    './app/javascript/**/*.js', // JavaScript files
    './app/views/**/*.{erb,haml,html,slim}', // All view templates
    './app/components/**/*.{erb,rb}',        // View components
  ],

  // Theme customization and extension
  theme: {
    extend: {
      fontFamily: {
        // Set Inter var as the primary sans-serif font
        // Falls back to default Tailwind sans fonts
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],

        // Add Pacifico font for the logo
        // Requires the font to be imported in app/views/shared/_head.html.erb
        pacifico: ['Pacifico', 'cursive'],
      },
    },
  },

  // Official Tailwind plugins for extended functionality
  plugins: [
    require('@tailwindcss/forms'),        // Enhanced form styles
    require('@tailwindcss/aspect-ratio'), // Aspect ratio utilities
    require('@tailwindcss/typography'),   // Prose and typography utilities
  ],
}
