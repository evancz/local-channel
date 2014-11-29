# local-channel

The general recommendation for making Elm applications modular is to write as
much code as possible without signals. We should be primarily be using plain
old functions. A typical component will have rougly this API:

```haskell
-- A model of our component
type alias Model = { ... }

-- Different ways we can update our model
type Update = ...

-- A function to actually perform those updates
step : Update -> Model -> Model

-- A way to view our model on screen and to trigger updates
view : Signal.Channel Update -> Model -> Html
```

One challenge seems to be that writing a view often requires hooking up to
some signal channel. The hard question seems to be, how can we have all our
different components reporting to a signal channel in a modular way? Local
channels answer this question!

## Usage Example

Say we want to model an app that has a search component and a results
component. Ideally those components can be written by different people on
different teams with minimal amounts of coordination or dependency between
their code. Local channels allow them to write self-contained modules that
expose view functions with the following types.

  * `Search.view : LocalChannel Search.Update -> Search.Model -> Html`
  * `Results.view : LocalChannel Results.Update -> Results.Model -> Html`

Once you have those building blocks, you can wire them together in a larger
application like this:

```haskell
import Signal
import LocalChannel as LC

type alias Model =
    { search : Search.Model
    , results : Results.Model
    , ...
    }

type Update
    = NoOp
    | SearchUpdate Search.Update
    | ResultsUpdate Results.Update
    | ...

updateChannel : Signal.Channel Update
updateChannel =
    Signal.channel NoOp

view : Model -> Html
view model =
    div [] [
      Search.view (LC.create SearchUpdate updateChannel) model.search,
      Results.view (LC.create ResultsUpdate updateChannel) model.results
    ]
```

In this world, we can create the true `Signal.Channel` at the very root of our
application with all the other signals. Our components do not need to know
anything about that though, they just need to ask for a local channel to report
things to.