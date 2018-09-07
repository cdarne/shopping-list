port module Main exposing (Model, Msg(..), init, main, update, view)

import Dom
import Html exposing (Html, a, article, button, div, footer, h1, header, i, img, input, label, main_, nav, p, small, span, text)
import Html.Attributes exposing (autofocus, checked, class, classList, disabled, href, id, placeholder, src, type_, value)
import Html.Events exposing (keyCode, on, onCheck, onClick, onInput, onMouseEnter)
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
    , entries : List Entry
    , filter : String
    , edition : Edition
    }


type Edition
    = None
    | NewEntry Entry
    | ExistingEntry Entry


emptyModel : Model
emptyModel =
    { uid = 1
    , entries = []
    , filter = ""
    , edition = None
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
    | Checked Int Bool
    | UpdateFilter String
    | AddEntry
    | EditEntry Entry
    | RemoveEntry Entry
    | CancelEdition
    | UpdateDescription String
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

        Checked id checked ->
            let
                updateEntry e =
                    if e.id == id then
                        { e | completed = checked }

                    else
                        e
            in
            ( { model | entries = List.map updateEntry model.entries }, Cmd.none )

        UpdateFilter value ->
            ( { model | filter = value }, Cmd.none )

        AddEntry ->
            ( { model | edition = NewEntry (newEntry model.uid) }, focusDescription )

        EditEntry entry ->
            ( { model | edition = ExistingEntry entry }, focusDescription )

        RemoveEntry entry ->
            ( { model | entries = List.filter (\e -> e.id /= entry.id) model.entries }, focusDescription )

        UpdateDescription description ->
            case model.edition of
                None ->
                    ( model, Cmd.none )

                NewEntry entry ->
                    ( { model | edition = NewEntry { entry | description = description } }, Cmd.none )

                ExistingEntry entry ->
                    ( { model | edition = ExistingEntry { entry | description = description } }, Cmd.none )

        CancelEdition ->
            ( { model | edition = None }, Cmd.none )

        Save ->
            case model.edition of
                None ->
                    ( model, Cmd.none )

                NewEntry entry ->
                    if String.isEmpty entry.description then
                        ( model, Cmd.none )

                    else
                        ( { model | uid = model.uid + 1, entries = entry :: model.entries, edition = None }, Cmd.none )

                ExistingEntry entry ->
                    if String.isEmpty entry.description then
                        ( model, Cmd.none )

                    else
                        let
                            replaceEntry e =
                                if e.id == entry.id then
                                    entry

                                else
                                    e
                        in
                        ( { model | entries = List.map replaceEntry model.entries, edition = None }, Cmd.none )

        RemoveCompleted ->
            ( { model | entries = List.filter (\e -> not e.completed) model.entries }, focusDescription )



---- VIEW ----


view : Model -> Html Msg
view model =
    let
        filteredEntries =
            List.filter (\e -> String.contains (String.toLower model.filter) (String.toLower e.description)) model.entries
    in
    main_ []
        [ nav [ class "navbar has-shadow" ]
            [ div [ class "navbar-brand" ]
                [ div [ class "navbar-item" ] [ span [ class "title is-4" ] [ text "Shopping list" ] ]
                ]
            , div [ class "navbar-menu" ]
                [ div [ class "navbar-end" ]
                    [ div [ class "navbar-item control has-icons-left" ]
                        [ div [ class "field" ]
                            [ div [ class "control" ]
                                [ input [ class "input is-small", placeholder "search", type_ "text", onInput UpdateFilter ] []
                                , smallIcon "search" "is-left"
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        , section
            [ container
                [ columns
                    [ column "is-12-tablet is-8-desktop is-offset-2-desktop is-6-widescreen is-offset-3-widescreen"
                        [ shoppingListView filteredEntries ]
                    ]
                ]
            ]
        , modal model.edition
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


shoppingListView : List Entry -> Html Msg
shoppingListView entries =
    let
        noCompletedEntries =
            not (List.any .completed entries)

        addButton =
            div [ class "panel-block" ]
                [ div [ class "buttons" ]
                    [ button [ class "button is-link is-outlined", onClick AddEntry ] [ text "Add a new entry" ]
                    , button [ class "button is-danger is-outlined", onClick RemoveCompleted, disabled noCompletedEntries ] [ text "Remove completed entries" ]
                    ]
                ]
    in
    nav [ class "panel" ]
        (entriesView entries ++ [ addButton ])


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


modal : Edition -> Html Msg
modal edition =
    let
        isActive =
            case edition of
                None ->
                    False

                NewEntry _ ->
                    True

                ExistingEntry _ ->
                    True

        entry =
            case edition of
                None ->
                    Nothing

                NewEntry entry ->
                    Just entry

                ExistingEntry entry ->
                    Just entry
    in
    div [ classList [ ( "modal", True ), ( "is-active", isActive ) ], onEscape CancelEdition ]
        [ div [ class "modal-background" ]
            []
        , div [ class "modal-card" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ]
                    [ text "Add an Entry" ]
                , button [ class "delete close-modal-button", onClick CancelEdition ]
                    []
                ]
            , Html.section [ class "modal-card-body" ]
                [ input
                    (case entry of
                        Nothing ->
                            [ id "entry-description", class "input", placeholder "Type the new Entry.", onInput UpdateDescription, onEnter Save ]

                        Just entry ->
                            [ id "entry-description", class "input", placeholder "Type the new Entry.", onInput UpdateDescription, onEnter Save, value entry.description ]
                    )
                    []
                ]
            , footer [ class "modal-card-foot" ]
                [ button [ class "button is-success", onClick Save ]
                    [ text "Save" ]
                , button [ class "button", onClick CancelEdition ]
                    [ text "Close" ]
                ]
            ]
        ]


onKeyDown keyCodePredicate =
    on "keydown" (Json.andThen keyCodePredicate keyCode)


isKeyCode expectedKeyCode msg code =
    if code == expectedKeyCode then
        Json.succeed msg

    else
        Json.fail "not ENTER"


onEnter : Msg -> Html.Attribute Msg
onEnter msg =
    onKeyDown (isKeyCode 13 msg)


onEscape : Msg -> Html.Attribute Msg
onEscape msg =
    onKeyDown (isKeyCode 27 msg)


port setStorage : List Entry -> Cmd msg
