describe('JobShow drag-and-drop', () => {
  it('handles drag-and-drop updates correctly', () => {
    console.log(Cypress.env('API_URL'))
    cy.intercept('GET', `${Cypress.env('API_URL')}/jobs/123`, {
      statusCode: 200,
      body: { data: 
        { id: 123, name: 'Test Job' },
        
      },
    }).as('getJob')
    cy.intercept('GET', `${Cypress.env('API_URL')}/jobs/123/candidates`, {
      statusCode: 200,
      body: { data: [
        { id: 1, email: 'candidate1@job.co', status: 'new', position: 0 },
        { id: 2, email: 'candidate2@job.co', status: 'interview', position: 1 },
      ]},
    }).as('getCandidates')

    cy.intercept('PATCH', `${Cypress.env('API_URL')}/jobs/123/candidates/1`, (req) => {
      expect(req.body).to.deep.equal({
        candidate: {
        id: 1,
        status: 'interview',
        newPosition: 1,
        }
      })
    }).as('updateCandidate')
    
    cy.visit('/jobs/123')
    
    // Verify the stubbed data is rendered on the page
    cy.contains('candidate1@job.co').should('be.visible')
    cy.contains('candidate2@job.co').should('be.visible')

    
    cy.visit('/jobs/123') // Adjust to the route where JobShow is rendered

    // Assert initial state
    cy.contains('Test Job').should('be.visible')
    cy.contains('candidate1@job.co').should('be.visible')
    cy.contains('interview').should('be.visible')

    // Perform drag-and-drop
    cy.get('[data-rfd-draggable-id="1"]').drag('[data-rfd-droppable-id="interview"]', { force: true, target: { position: 'center' }})
    cy.get('[data-rfd-droppable-id="interview"]').trigger('mouseup', { force: true })
    // Verify API was called or UI updated
    cy.wait('@updateCandidate')

    // Verify the UI reflects the move
    cy.contains('[data-rfd-droppable-id="interview"]', 'candidate1@job.co').should('be.visible')
  })
})
