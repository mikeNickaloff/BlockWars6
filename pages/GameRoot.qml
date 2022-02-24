import QtQuick 2.0
import com.blockwars.network 1.0
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
    IRCSocket {
        id: irc

        Component.onCompleted: {

            irc.connectToServer("core.datafault.net", 6667, JS.generateUuid(12))
        }

        onHandshakeComplete: {

            if (gameType == "multi") {
                JS.createOneShotTimer(gameRoot, 1000, function () {
                    irc.joinChannel("#remote_random_" + irc.nickname())
                    console.log(JS.generateArmyRandomNumbers())
                })
            }
            if (gameType == "single") {
                JS.createOneShotTimer(gameRoot, 1000, function () {
                    irc.joinChannel("#single_normal_" + irc.nickname())
                })
            }
        }
        onUserJoin: {

            if (user == "OperServ!services@services.datafault.net") {
                if (irc.getOpponentNickname() != "") {
                    bottomArmy.armyReinforcements = JS.generateArmyRandomNumbers()
                    topArmy.armyReinforcements = JS.generateArmyRandomNumbers()

                    irc.sendMessageToCurrentChannel(
                                irc.gameCommandMessage(
                                    "ARMY", JSON.stringify(
                                        bottomArmy.armyReinforcements)))
                }
            }
            if (user == irc.nickname) {

                irc.currentChannel = channel
            }
            console.log("JOIN", user, channel)
        }
        onGameMessageReceived: {
            console.log("Received Game Message", message)
            if (command == "ARMY") {
                var newArmy = irc.makeJSONDocument(message)

                topArmy.armyReinforcements = newArmy
                console.log(JSON.stringify(bottomArmy.armyReinforcements))
            }
            if (command == "BLOCKS") {
                var newBlocks = irc.makeJSONDocument(message)
                for (var i = 0; i < newBlocks.length; i++) {
                    var blkList = JS.matchObjectsByProperties(
                                topArmy.blocks.blocks,
                                [JS.makePropertyObject(
                                     "row",
                                     newBlocks[i].row), JS.makePropertyObject(
                                     "col", newBlocks[i].col)])
                    for (var u = 0; u < blkList.length; u++) {
                        blkList[u].color = newBlocks[i].color
                    }
                }
            }
            if (command == "REMOVED") {
                var obj = irc.makeJSONDocument(message)
                var nb = JS.removeBlocksByRowAndCol(topArmy.blocks.blocks,
                                                    obj.row, obj.col)
                topArmy.blocks.blocks = nb
                JS.createOneShotTimer(topArmy.blocks, 100, function () {
                    topArmy.blocks.stepBlockRefill()
                })
            }
        }
    }
    property var lastArmy
    property var lastBlocks

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
        irc: irc
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
        irc: irc
        onBlockRemoved: {
            var obj = {
                "row": row,
                "col": col
            }
            //irc.sendMessageToCurrentChannel(irc.gameCommandMessage(
            //                                   "REMOVED", JSON.stringify(obj)))
        }
    }
}
