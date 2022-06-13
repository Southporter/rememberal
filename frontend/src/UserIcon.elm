module UserIcon exposing (viewIcon)

import Html exposing (Html)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (..)

viewIcon : Html msg
viewIcon =
  svg 
    [ class "h-8"
    , class "w-8"
    , viewBox "0 0 20 20"
    , fill "currentColor"
    ]
    [ Svg.path 
        [ fillRule "evenodd"
        , d "M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z"
        , clipRule "evenodd"
        ] [] 
    ]
