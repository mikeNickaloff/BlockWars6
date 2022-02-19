import QtQuick 2.0
import "../components"
import "../scripts/main.js" as JS

Item {
    property var gameType
    property var players
    id: gameRoot
    signal requestStackChange(var stack, var properties)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }
    Component.onCompleted: {
        JS.createOneShotTimer(gameRoot, 1000, function () {
            console.log("Loaded Game Root")

            var localPlayers = players.filter(function (item) {
                if (item.controller === "Human") {
                    return true
                } else {
                    return false
                }
            })
            var remotePlayers = players.filter(function (item) {
                if (item.controller !== "Human") {
                    return true
                } else {
                    return false
                }
            })
            console.log("local Players", JSON.stringify(localPlayers))
            console.log("remote Players", JSON.stringify(remotePlayers))
            if (localPlayers.length > 1) {
                console.log("Error two human players")
                Qt.quit()
            } else {
                bottomArmy.chosenPowerups = localPlayers[0].powerups
            }

            if (remotePlayers.length !== 1) {
                console.log("Error no other players")
                Qt.quit()
            } else {
                topArmy.chosenPowerups = remotePlayers[0].powerups
            }
        })
    }

    ArmyRoot {
        id: topArmy
        height: {
            return parent.height * 0.42
        }
        width: {
            return parent.width * 0.825
        }
        x: {
            return parent.width * 0.025
        }
        y: {
            return parent.height * 0.05
        }
        armyOrientation: "top"
    }

    ArmyRoot {
        id: bottomArmy
        height: {
            return parent.height * 0.42
        }
        width: {
            return parent.width * 0.825
        }
        x: {
            return parent.width * 0.025
        }
        y: {
            return parent.height * 0.52
        }
        armyOrientation: "bottom"
    }
}
