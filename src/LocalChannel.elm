module LocalChannel (LocalChannel, create, localize, send) where
{-| This library helps you use channels in a more modular way. It allows
you to write a bunch of small self-contained components, but instead of
sending messages to a very general channel, they can work with a local channel.
This means we can totally decouple the component from the channel it will
eventually report to.

# Local Channels
@docs create, localize, send
-}


import Signal


type LocalChannel a =
  LocalChannel (a -> Signal.Message)


{-| Say we want to model an app that has a search component and a results
component. Ideally those components can be written by different people on
different teams with minimal amounts of coordination or dependency between
their code. Local channels allow them to write self-contained modules that
expose view functions with the following types.

  * `Search.view : LocalChannel Search.Update -> Search.Model -> Html`
  * `Results.view : LocalChannel Results.Update -> Results.Model -> Html`

Both functions refer to things that are locally known. The `create` function
makes it possible to wire them together howevery we want later on. Here is an
extended example of how you might use this pattern in practice.

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

-}
create : (local -> general) -> Signal.Channel general -> LocalChannel local
create generalize channel =
  LocalChannel (\v -> Signal.send channel (generalize v))


{-| When you are embedding a component within a component, you will probably
want to make a `LocalChannel` even more local.

    type alias Model = { ... }

    type Update = FilterUpdate Filter.Update | ...

    view : LocalChannel Update -> Model -> Html
    view localChan model =
      div [] [
        Filter.view (localize FilterUpdate localChan) model.filter
      ]

This means we can nest components arbitrarily deeply and keep their
implementation details distinct.
-}
localize : (local -> general) -> LocalChannel general -> LocalChannel local
localize generalize (LocalChannel send) =
  LocalChannel (\v -> send (generalize v))


{-| Actually send a message along a `LocalChannel`. Pretty much the same as
`Signal.send` but for local channels.
-}
send : LocalChannel a -> a -> Signal.Message
send (LocalChannel localizedSend) value =
  localizedSend value