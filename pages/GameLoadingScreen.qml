import QtQuick 2.0
import "qrc:///scripts/main.js" as JS

Item {
    id: gameLoadingScreen
    property var gameType
    property var players
    signal requestStackChange(var stack, var properties)
    Component.onCompleted: {
        JS.createOneShotTimer(gameLoadingScreen, 1000, function () {
            gameLoadingScreen.requestStackChange("qrc:///pages/GameRoot.qml", {
                                                     "gameType": gameType,
                                                     "players": players
                                                 })
        })
    }
}
