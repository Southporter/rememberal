module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (lazy)
import Html.Keyed as Keyed
import Http
import Dict exposing (Dict)
import Set exposing (Set)
import Maybe exposing (Maybe)
import Json.Decode exposing (Decoder, field, string, int, nullable, succeed)
import Json.Encode
import UserIcon
import Tombstone

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
  , state: Dict Int Contest
  , error: Maybe Http.Error
  }

type alias ContestantsState =
  { loadState : LoadingState (List Contestant)
  , state: List Contestant
  , error: Maybe Http.Error
  }

type Msg = GotItems (Result Http.Error (List Contest))
         | GotContestants (Result Http.Error (List Contestant))
         | Select (Contest, Contestant)
         | AddContestant Contest
         | SelectContestant String
         | SubmitContestant Contest
         | UpdatedContest (Result Http.Error Contest)
         | AddContest
         | NewContestName String
         | SubmitNewContest

type alias Model =
  { contests : ContestsState
  , contestants: ContestantsState
  , lastSelectedContestant: Maybe Contestant
  , newContest: Maybe String
  }

init : () -> (Model, Cmd Msg)
init _ =
  let
    model = { contests = { loadState = Loading, state = Dict.empty, error = Nothing }
            , contestants = { loadState = Loading, state = [], error = Nothing }
            , lastSelectedContestant = Nothing
            , newContest = Nothing
            }
  in
  ( model
  , Cmd.batch [ Http.get
                { url = "/api/contests"
                , expect = Http.expectJson GotItems (Json.Decode.list contestDecoder)
                }
              , Http.get
                { url = "/api/contestants"
                , expect = Http.expectJson GotContestants (Json.Decode.list contestantDecoder)
                }
              ]
  )

type alias Idable a = { a | id: Int}

extractId : Idable a -> (Int, Idable a)
extractId item =
  let
    idd {id} =
      id
  in
    (idd item, item)

toId : Idable a -> Int
toId { id } =
  id

listToDict : List (Idable a) -> Dict Int (Idable a)
listToDict l = 
  Dict.fromList (List.map extractId l)

updateContestSelected : Contestant -> Contest -> Contest
updateContestSelected contestant contest =
  { contest | selected = Just contestant.id}


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotItems results  ->
      case results of
        Ok items ->
          ({ model |
            contests =
            { loadState = Done
            , state = listToDict items 
            , error = Nothing
            }
          }, Cmd.none)
        Err e ->
          ({ model | contests = 
            { loadState = Failure
            , state = listToDict []
            , error = Just e
            }
          }, Cmd.none)
    GotContestants results ->
      case results of
        Ok items ->
          ({ model |
             contestants =
             { loadState = Done
             , state = items
             , error = Nothing
             }
          }, Cmd.none)
        Err e ->
          ({ model | contestants =
            { loadState = Failure
            , state = []
            , error = Just e
            }
          }, Cmd.none)
    Select (contest, contestant) ->
      let
        updatedContests =
          { loadState = model.contests.loadState
          , state = Dict.update contest.id (Maybe.map (updateContestSelected contestant)) model.contests.state
          , error = Nothing
          }
      in 
        ({ model | contests = updatedContests }
        , case  (Dict.get contest.id model.contests.state) of
            Just prevContest -> 
              Http.post
                { url = ("/api/contest/" ++ (String.fromInt contest.id))
                , body = Http.jsonBody <| encodeContest (updateContestSelected contestant prevContest)
                , expect = Http.expectJson UpdatedContest contestDecoder
                }
            Nothing ->
              Cmd.none
        )
    AddContestant contest ->
      let
        updatedContests =
          { loadState = model.contests.loadState
          , state = Dict.insert contest.id { contest | adding = True} model.contests.state
          , error = Nothing
          }
      in
        ({ model
         | contests = updatedContests
        }, Cmd.none)
    SelectContestant contestantStr ->
      let
        decoded = Result.toMaybe (Json.Decode.decodeString contestantDecoder contestantStr)
      in
        ({ model 
        | lastSelectedContestant = decoded
        }, Cmd.none)
    SubmitContestant contest ->
      let
        updatedContests =
          { loadState = model.contests.loadState
          , state = Dict.insert contest.id { contest | adding = False } model.contests.state
          , error = Nothing
          }
        closedModel = { model | contests = updatedContests }
        cleanModel = { closedModel | lastSelectedContestant = Nothing }
      in
      case model.lastSelectedContestant of
        Just contestant ->
          (cleanModel
          , Http.post 
            { url = "/api/contest/" ++ (String.fromInt contest.id) ++ "/contestants/" ++ (String.fromInt contestant.id)
            , body = Http.emptyBody
            , expect = Http.expectJson UpdatedContest contestDecoder
            }
          )
        Nothing ->
           (cleanModel, Cmd.none)
    UpdatedContest res ->
      case res of
        Ok contest ->
          let
            updatedContests =
              { loadState = model.contests.loadState
              , state = Dict.update contest.id (Maybe.map (updateContest contest)) model.contests.state
              , error = Nothing
              }
          in 
            ({ model | contests = updatedContests }
            , Cmd.none
            )
        Err _ ->
          (model, Cmd.none)
    AddContest ->
      ({ model | newContest = Just "" }, Cmd.none)
    NewContestName name ->
      ({ model | newContest = Just name }, Cmd.none)
    SubmitNewContest ->
      case model.newContest of
        Nothing -> (model, Cmd.none)
        Just name ->
          let
            newContest = Json.Encode.object
              [ ("name", Json.Encode.string name) ]
          in
            ({ model | newContest = Nothing }
            , Http.post
              { url = "/api/contest"
              , body = Http.jsonBody <| newContest
              , expect = Http.expectJson UpdatedContest contestDecoder
              }
            )



updateContest : Contest -> Contest -> Contest
updateContest contest _ =
  contest
  
  


subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none

dictToList : (Dict k v) -> List v
dictToList d =
  List.map (\(_,c) -> c) (Dict.toList(d))


errToStr : Http.Error -> String
errToStr error =
  case error of
    Http.BadUrl url ->
      "Bad url: " ++ url
    Http.Timeout ->
      "Connection timed out"
    Http.NetworkError ->
      "Connection problem"
    Http.BadStatus status ->
      "Unexpected status: " ++ String.fromInt status
    Http.BadBody body ->
      "Bad body: " ++ body

view : Model -> Html Msg
view model =
  let
    -- _ = Debug.log "model" model
    inner = case model.contests.loadState of
      Done ->
        viewContests model
      Success items ->
        viewContests model
      Loading ->
        div [] [ text "Loading..."]
      Failure ->
        case model.contests.error of
          Just e ->
            div [] [ text "Error fetching list"
                   -- , text (errToStr (Debug.log "error" e))]
                   , text (errToStr e)]
          Nothing ->
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
  { id : Int
  , name : String
  , img : String
  , color : String
  }

type alias Contest =
  { id : Int 
  , name : String
  , contestants : List Contestant
  , selected : Maybe Int
  , adding: Bool
  }


encodeContest : Contest -> Json.Encode.Value
encodeContest contest =
  Json.Encode.object
    [ ("id", Json.Encode.int contest.id)
    , ("name", Json.Encode.string contest.name)
    , ("selected", getSelectedValue contest.selected)
    ]

encodeContestant : Contestant -> Json.Encode.Value
encodeContestant contestant =
  Json.Encode.object
    [ ("id", Json.Encode.int contestant.id)
    , ("name", Json.Encode.string contestant.name)
    , ("color", Json.Encode.string contestant.color)
    , ("img", Json.Encode.string contestant.img)
    ]

getSelectedValue : Maybe Int -> Json.Encode.Value
getSelectedValue selected =
  case selected of
    Just sel ->
      Json.Encode.int sel
    Nothing ->
      Json.Encode.null

getSelected : Maybe Int -> Int 
getSelected selected =
  case selected of
    Just sel ->
      sel
    Nothing ->
      -1

contestDecoder : Decoder Contest
contestDecoder =
  Json.Decode.map5 Contest
    (field "id" int)
    (field "name" string)
    (field "contestants" (Json.Decode.list contestantDecoder))
    (field "selected" (nullable int))
    (succeed False)

contestantDecoder : Decoder Contestant
contestantDecoder =
  Json.Decode.map4 Contestant
    (field "id" int)
    (field "name" string)
    (field "img" string)
    (field "color" string)

tombstoneContest =
  { id = -1
  , name = "Add Contest"
  , contestants = []
  , selected = Nothing
  , adding = False
  }

viewContests : Model -> Html Msg
viewContests model =
  let
    contestList = dictToList model.contests.state
    items = List.map (viewKeyedContest model) contestList
    empty = viewContest model tombstoneContest
    tombstone = case model.newContest of
      Nothing -> Tombstone.view (Tombstone.onTombstoneClick AddContest) (viewContest model tombstoneContest)
      Just s -> Tombstone.view (Tombstone.onTombstoneEdit (\v -> NewContestName v) SubmitNewContest) (viewContest model { tombstoneContest | name = ""})
    all = items ++ [("add", tombstone)]
  in
    Keyed.node "ul" [] all

viewKeyedContest : Model -> Contest -> (String, Html Msg)
viewKeyedContest model item =
  ( item.name, lazy (viewContest model) item )

viewContest : Model -> Contest -> Html Msg
viewContest model c =
  let
    contestants = div [] [ viewContestants model c]
    contents = if c.name == "" then
                 [contestants]
              else
                 [ div [] [ text c.name ], contestants]
               
  in
  li [] contents

filterExistingContestants : Set Int-> Contestant -> Bool
filterExistingContestants existing suspect =
  not (Set.member suspect.id existing)

contestantOption : Contestant -> Html Msg
contestantOption contestant =
  option [ value (Json.Encode.encode 0 (encodeContestant contestant)) ] [text contestant.name]

addContestant =
  { id = 999999999
  , name = "+"
  , img = ""
  , color = "gray"
  }

viewContestants : Model -> Contest -> Html Msg
viewContestants model contest =
  let
    partial = viewKeyedContestant contest 
    add = { id = 99999999, name = "+", img = "", color = "gray" }
    currentContestants = Set.fromList (List.map toId contest.contestants)
    filteredContestants = List.filter (filterExistingContestants currentContestants) model.contestants.state
    display =
      if contest.adding then
        Html.form [onSubmit (SubmitContestant contest)] [
          select [ onInput SelectContestant ] 
          (List.map contestantOption filteredContestants)
          , button [ type_ "submit" ] [ text "Add" ]
        ]
      else if contest.id >= 0 then
        div (contestantClasses contest add)
          [ button
            [ onClick (AddContestant contest) ]
            [text add.name ]
          ]
      else
        div (contestantClasses contest add)
          [ text "" ]
  in
    Keyed.node "ul" [ class "flex"
      , class "flex-row"
      , class "gap-4"
      ]
      ((List.map partial contest.contestants) ++ [
        ("add", li [] [
          display
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
      , class ("bg-[" ++ c.color ++ "]")
      , class "gap-4"
      ]
    selected = (getSelected contest.selected) == c.id
  in
    if selected then
      base ++ [ class "ring"
        , class ("ring-[" ++ c.color ++ "]")
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
