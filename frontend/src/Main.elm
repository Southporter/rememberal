module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Html.Keyed as Keyed
import Http
import Dict exposing (Dict)
import Maybe exposing (Maybe)
import Json.Decode exposing (Decoder, map4, field, string)
import UserIcon

main : Program () Model Msg
main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

type LoadingState a = Failure | Loading | Success a | Done

type alias ContestsState =
  { loadState : LoadingState (List Contest)
  , state: Dict String Contest
  }

type Msg = GotItems (Result Http.Error (List Contest)) | Select (Contest, Contestant)
type alias Model =
  { contests : ContestsState
  }

init : () -> (Model, Cmd Msg)
init _ =
  let
    model = { contests = { loadState = Loading, state = Dict.empty } }
  in
  ( model
  , Http.get
    { url = "/items"
    , expect = Http.expectJson GotItems (Json.Decode.list contestDecoder)
    }
  )

type alias Idable a = { a | id: String }

extractId : Idable a -> (String, Idable a)
extractId item =
  let
    idd {id} =
      id
  in
    (idd item, item)

listToDict : List (Idable a) -> Dict String (Idable a)
listToDict l = 
  Dict.fromList (List.map extractId l)

defaultContestants : List Contestant
defaultContestants = [ { id = "1111", name = "Hyrum" ,  img = "", color = "red" }
  , { id = "2222", name = "Emma", img = "", color = "pink" }
  ]

defaultContests : List Contest
defaultContests =
  [
    { id = "xxxx", name = "Sour Cream Spoon", contestants = defaultContestants, selected = "1111"}
    , { id = "yyyy", name = "Bathtime Cup", contestants = defaultContestants, selected = "2222"}
  ]

updateContestSelected : Contestant -> Contest -> Contest
updateContestSelected contestant contest =
  { contest | selected = contestant.id}


update : Msg -> Model -> (Model, Cmd msg)
update msg model =
  case msg of
    GotItems results  ->
      case results of
        Ok items ->
          let
            contestsDict = listToDict items
          in 
            ({ model |
              contests =
              { loadState = Done
              , state = contestsDict 
              }
            }, Cmd.none)
        Err _ ->
          ({ model | contests = 
            { loadState = Done
            , state = listToDict defaultContests
            }
          }, Cmd.none)
    Select (contest, contestant) ->
      let
        updatedContests =
          { loadState = model.contests.loadState
          , state = Dict.update contest.id (Maybe.map (updateContestSelected contestant)) model.contests.state
          }
      in 
        ({ model | contests = updatedContests }
        , Cmd.none
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

dictToList : (Dict k v) -> List v
dictToList d =
  List.map (\(_,c) -> c) (Dict.toList(d))

view : Model -> Html Msg
view model =
  let
    inner = case model.contests.loadState of
      Done ->
        viewContests (dictToList model.contests.state)
      Success items ->
        viewContests items
      Loading ->
        div [] [ text "Loading..."]
      Failure ->
        div [] [ text "Error fetching list" ]
  in
    div []
      [ viewHeader
      , div [ class "m-4"] [inner]
      ]


viewIcon : Html msg
viewIcon =
  div
    [ class "w-10 h-10"
    , class "ring ring-amber-500"
    , class "rounded-full"
    , class "text-color-amber-700"
    , class "flex justify-center items-center"
    ]
    [ div [ class "font-cursive text-xl"]
       [ text "R"
          , div [ class "absolute top-0 left-0 w-10 h-10 m-2 rounded-full"
            -- , class "bg-gradient-to-tr from-red-600 via-transparent to-red-500"
            , class "swirl blur-sm"
            , style "background-size" "300% 300%"
            , style "background-position" "20% 35%"
            ]
            []
        ]
    ]


viewHeader : Html Msg
viewHeader = 
  div
    [ class "w-full"
    , class "p-2"
    , class "flex"
    , class "justify-between"
    , class "items-center"
    , class "bg-amber-300"
    ]
    [ viewIcon
    , div [ class "font-cursive text-4xl" ] [ text "Rememberal" ]
    , div [] 
      [ UserIcon.viewIcon ]
    ]

type alias Contestant =
  { id : String
  , name : String
  , img : String
  , color : String
  }

type alias Contest =
  { id : String
  , name : String
  , contestants : List Contestant
  , selected : String
  }


contestDecoder : Decoder Contest
contestDecoder =
  map4 Contest
    (field "id" string)
    (field "name" string)
    (field "contestants" (Json.Decode.list contestantDecoder))
    (field "selected" string)

contestantDecoder : Decoder Contestant
contestantDecoder =
  map4 Contestant
    (field "id" string)
    (field "name" string)
    (field "img" string)
    (field "color" string)

viewContests : List Contest -> Html Msg
viewContests contests =
  Keyed.node "ul" [] (List.map viewKeyedContest contests)

viewKeyedContest : Contest -> (String, Html Msg)
viewKeyedContest item =
  ( item.name, lazy viewContest item )

viewContest : Contest -> Html Msg
viewContest c =
  li []
    [ div [] [ text c.name ]
    , div [] [ viewContestants c ]
    ]

viewContestants : Contest -> Html Msg
viewContestants contest =
  let
    partial = viewKeyedContestant contest 
    add = { id = "++++", name = "+", img = "", color = "gray" }
  in
    Keyed.node "ul" [ class "flex"
      , class "flex-row"
      , class "gap-4"
      ]
      ((List.map partial contest.contestants) ++ [
        ("add", li [] [
          div (contestantClasses contest add) [ text add.name ]
        ])
      ])

viewKeyedContestant : Contest -> Contestant -> (String, Html Msg)
viewKeyedContestant contest c =
  let
    partial = viewContestant contest 
  in
    (c.name, lazy partial c)

contestantClasses : Contest -> Contestant -> List (Html.Attribute Msg)
contestantClasses contest c =
  let
    base = [ class "flex"
      , class "rounded-full"
      , class "w-16"
      , class "h-16"
      , class "justify-center"
      , class "items-center"
      , class ("bg-" ++ c.color ++ "-300")
      , class "gap-4"
      ]
    selected = contest.selected == c.id
  in
    if selected then
      base ++ [ class "ring"
        , class ("ring-" ++ c.color ++ "-400")
        , class "ring-offset-2"
        ]
    else
      base

viewContestant : Contest -> Contestant -> Html Msg
viewContestant contest c=
  li [ class "flex-initial"
    ]
    [ div (contestantClasses contest c)  [ button
        [ onClick (Select (contest, c))]
        [ text c.name ]
      ]
    ]
