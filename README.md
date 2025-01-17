# Readme

## Getting started

# [view the live project here!](https://wttj-kanban.gigalixirapp.com/)

# Or to run locally please follow the details below

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- install assets and start front

```bash
cd assets
yarn
yarn dev
```

### tests

- backend: `mix test`
- front: `cd assets & yarn test`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).


## Starting points and Development approach
I started by first familiarising myself with Elixir codebases and the generated code provided. Having not used Elixir/Phoenix before I studied the documentation to get a better grasp of how much the framework provides and the approaches to building on this.

Running the project locally was very straight forward and so it was easy to make a start.

I seperated the requirements into sections:

### Epic: Draggable cards
- Back end changes to reorder candidates on change of position/status
- Front end implementation of drag and drop using a helper library

### Epic: Live updates
- Back end addition of websocket
- Front end listener to websocket and live updates accordingly
- Backend handling concurrent events

- Any extras I had time to finish


I aimed to keep my code updates to match either front-end or back-end updates and specific to the section requirements, creating a feature branch that was pointed to an epic for the full achievable functionality.


## Requirement 1 - Draggable cards

### Frontend
I opted to use the `@hellopangea-dnd` package after seeing examples online. It has a nice developer experience and feels easy to get started with. As the project progressed I did realise it had its shortcomings and looking back I should perhaps have used a different package.

There are issues mentioned in the github repo that people had issues with flickering when dragging cards around and rerendering. Implementing the drag to perform the database operation was very straightforward but there was a clear visual issue between the initial card movement and the asynchronous database update.

To handle this I implemented a hook to handle the `onDragUpdate` which resorted the data and updated the local queryClient response in anticipation for the asynchronous database operation. On a larger dataset this could be a potentially costly addition and is another reason that this package may not have been the best choice.

I believe this workaround hampered testing the drag and drop which I will talk more on later.

I tried to follow the "smart"/"dumb" component approach and refactored components accordingly. I also added type assertions as the `draggableId`/`droppableId` i.e. the new/previous status was provided as a string and I wanted to ensure it was a recognised kanban type before performing the database operation.

### Backend
The main body of the backend work was to expand the update_candidate function to as well provide updates to candidates affected by the status/position change of a desired candidate.

To do this I approached it by fetching the current_status_cards and new_status_cards depending on the movement of the candidate. I added private functions that handled the update of these positions and then performed bulk inserts of these updates.

I added a new migration that changed a unique index that caused the bulk inserting was throwing errors. I realised later when implementing concurrency this was a bad idea and I will talk more on that later.


## Requirement 2 - Live updates

### Technical considerations
The brief asked for justification of a choice between Websockets and Server-Sent Events. I have used Websockets before but had to research SSE. Due to my unfamiliarity of SSE I opted to leverage Phoenixs native implentation of websockets, and ease to set up by simply running the `mix phx.gen.socket` command. Whether or not SSE would be a more suitable technical requirement, the ease of creating the Websocket and subscribing to it on the front end seemed like it outweighed the potential benefits of SSE. That coupled with the benefits of Phoenix's generated test suite and thorough browser support confirmed this decision.

### Backend
I ran the `mix phx.gen.socket` command which created the desired websocket and test suite. Once this was in place adding custom broadcast messages to candidate actions was simple to implement and write further tests for.

I then ensured the correct fields on `candidate` were serialised for transfer using `Jason.Encoder`.

To introduce concurrency I more thoroughly implemented transactional based updates and added pessemistic locking to the fetched candidates requiring update. I also refetched the original candidate with a `FOR UPDATE` to lock this but I think perhaps this could be amended earlier in the chain of functions to reduce the extra query. I also added a case to retry the update when it failed on deadlocks, a maximum of five times before throwing an error.

I did struggle to know where to start with testing concurrent updates and had to rely on others code examples and guides. Once I had set up the tests for this it highlighted a few issues with my implementation of the `update_candidate` function.

The unique index I had edited meant that on concurrent updates candidates could be stored with the same position and this was the opposite of my intended functionality. I added a new migration reverting this index and then went about solving the original issue that ran into this unique index issue.

It highlighted that the inserts had to happen in a particular order where there was essentially a "free" position. I had initially considered this and was updating the candidate to position: -1, but removed it once the changes to the unique index had been changed.

I readded this move to -1 and realised the updating candidates needed to be sorted by existing positions in a specific direction depending on the positional movement. Once this was updated my concurrent tests ran successfully.

### Frontend
Using the phoenix package it was easy to add a new Context and Provider to the application. 

I then added a new hook to subscribe to the correct channel, relevant to the `id` of the job page a user is visiting. A useEffect hook then will invalidate the correct query when a candidate for that job is updated on the database.


## Extras
I added a CI github action on pull request into and pushes to main. I wanted to also add a deployment step but this proved more complicated than intended.

I finally managed to deploy the project to gigalixir [here](https://wttj-kanban.gigalixirapp.com/). I was very much rushing around doing this and did a lot of commits on main which is not ideal at all, but I was running out of time and I wanted to get something live for people to see.

Releasing it has highlighted it doesn't quite work as smooth as I'd hoped with the delayed asynchronous operations. It works quite well but sometimes does lag.

## Shortcomings

The lack of testing of the drag and drop is not ideal. I tried in vain to really get this package to work but I think testing drag and drop is not straightforward in the JS dom. I then tried to add some e2e tests with cypress and got somewhere but still couldn't quite get it to work particularly well. I've left a pull request with those extra tests if thats helpful to see. I probably wasted too much time on this as I'd liked to have got more of the nice to haves done.

I think it is my elixir/phoenix naivity but as I'm not sure how to fix it but if you visit a job page and hit refresh, it breaks and you have to start from the route again. This is probably a straightforward change but it eluded me as I was rushing to deploy.

There is not a great deal of error handling and playing with the live released version does seem like it needs to be more robust handling the asynchronous updates. Developing locally did lead me to a false sense of security in how quick these might be to complete.


## Next steps
I would have liked to have added GraphQL, but this was definitely not achievable in the timeframe. I think the cascades of rest queries
- Get the jobs on the home page
- Get the job information from the jobId on the job page for just the name
- Get the candidates using the jobId

This would be so much nicer to return at the top level with a nested structure e.g.:

```
type Candidate {
  id: Int!
  email: String!
  status: String! (or bespoke KanbanStatus!)
  position: Int!
}

type Job {
  id: Int!
  name: String!
  candidates: [Candidate!]!
}

query jobs {
  jobs: [Job!]!
}

query job(filter: { $jobId: Int! }) {
  id: Int!
  candidates: [Candidate!]!
}
```

With dataloaders and then careful invalidation of specific candidates this could be a much more efficient way of fetching the data. That said the rest approach is simple and I imagine is a fastmoving way of working with phoenix.

There is no real security for access currently. It looks like Phoenix has some out the box auth you can apply but there wasn't really time to implement anything like this.

I would have liked to provide an easier way to amend data online, I didn't manage to add the seeds to the gigalixir deployment but managed to connect directly and update the database via tableplus.

The candidate view would have also been nice to have a list of jobs that they are included in. This would potentially have required a restructure or join table for candidate_id -> job_id perhaps with status and position information there. It would remove duplicate candidates with the same email/id but different job information.

The candidate position is normalised however on creation there isn't a normalisation of position. I think this would be a product decision as to whether it goes to the "top" of the list or the "bottom" of the list of current candidates per status.