port module Main exposing (Model, Msg(..), init, main, update, view)

import Char exposing (isDigit)
import Dom
import Html exposing (Html, a, button, div, i, img, input, label, main_, nav, p, small, span, text)
import Html.Attributes exposing (checked, class, classList, disabled, href, id, placeholder, src, type_, value)
import Html.Events exposing (keyCode, on, onCheck, onClick, onInput)
import Json.Decode as Json
import Task



---- PROGRAM ----


main : Program (List Entry) Model Msg
main =
    Html.programWithFlags
        { view = view
        , init = init
        , update = updateWithStorage
        , subscriptions = always Sub.none
        }



---- MODEL ----


type alias Entry =
    { id : Int
    , description : String
    , completed : Bool
    }


newEntry : Int -> Entry
newEntry id =
    Entry id "" False


type alias Model =
    { uid : Int
    , field : String
    , entries : List Entry
    , edition : Edition
    }


type Edition
    = NewEntry
    | ExistingEntry Entry


emptyModel : Model
emptyModel =
    { uid = 1
    , field = ""
    , entries = []
    , edition = NewEntry
    }


init : List Entry -> ( Model, Cmd msg )
init savedEntries =
    let
        maximumId =
            savedEntries
                |> List.map .id
                |> List.maximum

        uid =
            case maximumId of
                Just id ->
                    id + 1

                Nothing ->
                    1
    in
    ( { emptyModel | entries = savedEntries, uid = uid }, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | UpdateField String
    | Checked Int Bool
    | EditEntry Entry
    | RemoveEntry Entry
    | CancelEdition
    | Save
    | RemoveCompleted


{-| We want to `setStorage` on every update. This function adds the setStorage
command for every step of the update function.
-}
updateWithStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithStorage msg model =
    let
        ( newModel, cmds ) =
            update msg model
    in
    ( newModel, Cmd.batch [ setStorage newModel.entries, cmds ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        focusDescription =
            Task.attempt (\_ -> NoOp) (Dom.focus "entry-description")
    in
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateField field ->
            ( { model | field = field }, Cmd.none )

        Checked id checked ->
            let
                updateEntry e =
                    if e.id == id then
                        { e | completed = checked }

                    else
                        e
            in
            ( { model | entries = List.map updateEntry model.entries }, Cmd.none )

        EditEntry entry ->
            ( { model | edition = ExistingEntry entry, field = entry.description }, focusDescription )

        RemoveEntry entry ->
            ( { model | entries = List.filter (\e -> e.id /= entry.id) model.entries }, Cmd.none )

        CancelEdition ->
            ( { model | edition = NewEntry, field = "" }, Cmd.none )

        Save ->
            case model.edition of
                NewEntry ->
                    if String.isEmpty model.field then
                        ( model, Cmd.none )

                    else
                        let
                            entry =
                                Entry model.uid model.field False
                        in
                        ( { model | uid = model.uid + 1, entries = entry :: model.entries, edition = NewEntry, field = "" }, Cmd.none )

                ExistingEntry entry ->
                    if String.isEmpty model.field then
                        ( model, Cmd.none )

                    else
                        let
                            replaceEntry e =
                                if e.id == entry.id then
                                    { entry | description = model.field }

                                else
                                    e
                        in
                        ( { model | entries = List.map replaceEntry model.entries, edition = NewEntry, field = "" }, Cmd.none )

        RemoveCompleted ->
            ( { model | entries = List.filter (\e -> not e.completed) model.entries }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    main_ []
        [ nav [ class "navbar is-primary is-fixed-top has-shadow" ]
            [ div [ class "navbar-brand" ]
                [ div [ class "navbar-item" ] [ span [ class "title is-4" ] [ text "Shopping list" ] ]
                ]
            ]
        , section
            [ container
                [ columns
                    [ column "is-12-tablet is-8-desktop is-offset-2-desktop is-6-widescreen is-offset-3-widescreen"
                        [ shoppingListView model.field model.entries ]
                    ]
                ]
            ]
        ]



---- HELPERS ----


section : List (Html msg) -> Html msg
section =
    Html.section [ class "section" ]


container : List (Html msg) -> Html msg
container =
    div [ class "container" ]


columns : List (Html msg) -> Html msg
columns =
    div [ class "columns" ]


column : String -> List (Html msg) -> Html msg
column additionalClasses =
    let
        classes =
            "column " ++ additionalClasses
    in
    div [ class classes ]


panel : String -> List (Html msg) -> Html msg
panel heading blocks =
    nav [ class "panel" ]
        (p [ class "panel-heading" ] [ text heading ] :: blocks)


smallIcon : String -> String -> Html msg
smallIcon description additionalClasses =
    let
        classes =
            "icon is-small " ++ additionalClasses
    in
    span [ class classes ] [ i [ class ("fa fa-" ++ description) ] [] ]


icon : String -> String -> List (Html.Attribute msg) -> Html msg
icon description additionalClasses attributes =
    let
        classes =
            "icon is-small " ++ additionalClasses
    in
    span (class classes :: attributes) [ i [ class ("fa fa-" ++ description) ] [] ]


shoppingListView : String -> List Entry -> Html Msg
shoppingListView field entries =
    let
        isEditing =
            not (String.isEmpty field)

        textBox =
            div [ class "panel-block" ]
                [ div [ class "field has-addons is-flex-1" ]
                    (p [ class "control has-icons-left is-flex-1" ]
                        [ input
                            [ id "entry-description"
                            , class "input is-small"
                            , type_ "text"
                            , placeholder "What needs to be bought?"
                            , value field
                            , onInput UpdateField
                            , onEnter Save
                            ]
                            []
                        , icon "edit" "is-small is-left" []
                        ]
                        :: (if isEditing then
                                [ p [ class "control" ]
                                    [ button [ class "button is-small is-success", onClick Save ] [ icon "check" "is-small" [] ]
                                    ]
                                , p [ class "control" ]
                                    [ button [ class "button is-small is-danger", onClick CancelEdition ] [ icon "ban" "is-small" [] ]
                                    ]
                                ]

                            else
                                []
                           )
                    )
                ]

        noCompletedEntries =
            not (List.any .completed entries)

        removeCompleted =
            div [ class "panel-block" ]
                [ button [ class "button is-danger is-outlined is-fullwidth", onClick RemoveCompleted, disabled noCompletedEntries ] [ text "Remove completed entries" ]
                ]
    in
    nav [ class "panel" ]
        (textBox :: entriesView entries ++ [ removeCompleted ])


entriesView : List Entry -> List (Html Msg)
entriesView entries =
    let
        entryView entry =
            div [ class "panel-block" ]
                [ label [ classList [ ( "checkbox", True ), ( "completed", entry.completed ), ( "has-text-grey", entry.completed ) ] ]
                    [ input [ type_ "checkbox", onCheck (Checked entry.id), checked entry.completed ] []
                    , span [] [ text entry.description ]
                    ]
                , icon "edit" "panel-icon is-right is-hidden-desktop has-text-grey edit" [ onClick (EditEntry entry) ]
                , icon "times" "panel-icon is-right is-hidden-desktop has-text-grey edit" [ onClick (RemoveEntry entry) ]
                ]
    in
    List.map entryView entries


onKeyDown keyCodePredicate =
    on "keydown" (Json.andThen keyCodePredicate keyCode)


isKeyCode expectedKeyCode msg code =
    if code == expectedKeyCode then
        Json.succeed msg

    else
        Json.fail ("not " ++ toString expectedKeyCode)


onEnter : Msg -> Html.Attribute Msg
onEnter msg =
    onKeyDown (isKeyCode 13 msg)


onEscape : Msg -> Html.Attribute Msg
onEscape msg =
    onKeyDown (isKeyCode 27 msg)


port setStorage : List Entry -> Cmd msg
