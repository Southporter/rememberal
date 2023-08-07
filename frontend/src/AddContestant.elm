module AddContestant exposing (view)

import Html exposing (Html)

type Input a = Display (List a) | Add msg

view : Input -> Html msg
view = 
    div (contestantClasses contest add) [ button
    [ onClick (AddContestant contest) ]
    [text add.name ]
    ]
