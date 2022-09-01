module Tombstone exposing (view, onTombstoneClick, onTombstoneEdit)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit, onInput)

onTombstoneClick : msg -> State msg
onTombstoneClick msg = Click msg

onTombstoneEdit : (String -> msg) -> msg -> State msg
onTombstoneEdit mapper msg = Editing mapper msg

type State m = Click m | Editing (String -> m) m

containerStyles = [ style "height" "100%"
                  , style "width" "100%"
                  , style "flex-direction" "column"
                  ]

view : State msg -> Html msg -> Html msg
view state child =
  case state of
    Click m ->
      div containerStyles [
        button [ style "flex" "1"
               , style "background-color" "lightgray"
               , onClick m
               ] [
          child
        ]
      ]
    Editing onInsert m ->
      div containerStyles
        [ div [ style "background-color" "lightgray"]
          [ Html.form [ onSubmit m ] 
            [ input [ type_ "text", onInput onInsert, placeholder "New Contest" ] []
            , button [ type_ "submit"] [ text "Create" ]
            ]
          , child
          ]

        ]
