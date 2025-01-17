import { defineConfig } from 'cypress'

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
      baseUrl: 'http://localhost:5173', // Replace with your dev server's URL
      env: {
        API_URL: 'http://localhost:5173/api', // Override API URL
      },
  },
})
