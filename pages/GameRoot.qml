import QtQuick 2.15
import com.blockwars.network 1.0
import QtQuick.Particles 2.0
import QuickFlux 1.1
import "../flux"

import "../components"
import "../scripts/main.js" as JS
import "../scripts/qwebchannel.js" as QWebChannel

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


    /*
            irc.sendMessageToCurrentChannel(irc.gameCommandMessage(
                                                "ARMY", JSON.stringify(
                                                    armyReinforcements)))

                                               */
    property var webChannel
    IRCSocket {
        id: irc

        Component.onCompleted: {

            irc.connectToServer("core.datafault.net", 6667, JS.generateUuid(12))
            //   webChannel.registerObject("armyBlocks", bottomArmy.blocks)
        }

        onHandshakeComplete: {

            if (gameType == "multi") {
                JS.createOneShotTimer(gameRoot, 1000, function () {
                    irc.joinChannel("#remote_random_" + irc.nickname())
                    // console.log(JS.generateArmyRandomNumbers())
                })
            }
            if (gameType == "single") {
                JS.createOneShotTimer(gameRoot, 1000, function () {
                    irc.joinChannel("#single_normal_" + irc.nickname())
                    //irc.handleJoin(irc.nickname())
                    irc.sendLocalGameMessage("bottom", "ARMY",
                                             bottomArmy.engine.serializePools())
                    irc.sendLocalGameMessage("top", "ARMY",
                                             topArmy.engine.serializePools())
                })
            }
        }
        onUserJoin: {

            if (user == "OperServ!services@services.datafault.net") {
                if (irc.getOpponentNickname() != "") {

                    /*bottomArmy.armyReinforcements = JS.generateArmyRandomNumbers() */
                    //     bottomArmy.engine.generateTest()
                    //   topArmy.engine.generateTest()

                    //bottomArmy.blocks.addMoveEvent("stepBlockRefill", {})


                    /* JS.createOneShotTimer(gameRoot, 00, function () {
                        irc.sendMessageToCurrentChannel(
                                    irc.gameCommandMessage(
                                        "ARMY", JSON.stringify(
                                            JS.compressArray(
                                                bottomArmy.armyReinforcements))))
                    }) */
                    if (gameType == "multi") {
                        JS.createOneShotTimer(gameRoot, 1000, function () {
                            irc.sendMessageToCurrentChannel(
                                        irc.gameCommandMessage(
                                            "ARMY",
                                            bottomArmy.engine.serializePools()))

                            bottomArmy.engine.deserializePools(
                                        bottomArmy.engine.serializePools())
                        })
                    }
                }
            }

            if (user == irc.nickname) {

                irc.currentChannel = channel
            }
            console.log("JOIN", user, channel)
        }
        property var send: function (arg) {
            sendChannelMessage(arg)
        }
        property var webchannel

        //        onChannelMessageReceived: {
        //            transport.messageReceived(message, transport)
        //        }
        onGameMessageReceived: {
            //console.log("Received Game Message", command, message)
            if (command == "ARMY") {


                /* var newArmy = irc.makeJSONDocument(message)
                if (typeof newArmy == "undefined") {
                    return
                } */
                topArmy.engine.deserializePools(message)
                //topArmy.armyReinforcements = JS.decompressArray(newArmy)
                JS.createOneShotTimer(gameRoot, 1000, function () {

                    var checkStr = "game_" + irc.nickname()
                    if (irc.currentChannel.indexOf(checkStr) > -1) {
                        topArmy.blocks.armyNextAction = ActionTypes.stateArmyBlocksArmyReadyDefense
                        bottomArmy.blocks.armyNextAction
                                = ActionTypes.stateArmyBlocksArmyReadyOffense
                        //bottomArmy.engine.startOffense()
                        //topArmy.engine.startDefense()
                    } else {
                        // bottomArmy.engine.startDefense()
                        bottomArmy.blocks.armyNextAction
                                = ActionTypes.stateArmyBlocksArmyReadyDefense
                        //  topArmy.engine.startOffense()
                        topArmy.blocks.armyNextAction = ActionTypes.stateArmyBlocksArmyReadyOffense
                    }
                })
            }

            if (command == "QUEUE") {
                var gotSwap = false
                var queue = irc.makeJSONDocument(message)
                for (var i = 0; i < queue.length; i++) {
                    var item = queue[i]
                    console.log("[TOP] Going to execute:", item.fn)

                    if (item.fn == "SWAP") {
                        if (gotSwap) {
                            continue
                        }
                        gotSwap = true
                        /*if (topArmy.blocks.armyNextAction == ActionTypes.stateArmyBlocksMoveStart) { */
                        ActionsController.armyBlocksSwapBlocks({
                                                                   "orientation": "top",
                                                                   "uuid1": item.args[0],
                                                                   "uuid2": item.args[1]
                                                               })
                    }
                    if (item.fn == "SYNC") {

                        ActionsController.armyBlocksProcessSync({
                                                                    "orientation": "top",
                                                                    "armyIndices": item.args[0],
                                                                    "armyBlocks": item.args[1]
                                                                })

                        //                        bottomArmy.blocks.armyPostSyncState = bottomArmy.blocks.armyNextAction;
                    }

                    if (item.fn == "swapBlocks") {

                    }
                }
            }
        }
        onLocalGameMessageReceived: function (sender, command, message) {
            if (command == "ARMY") {


                /* var newArmy = irc.makeJSONDocument(message)
                if (typeof newArmy == "undefined") {
                    return
                } */
                if (sender == "top") {
                    topArmy.engine.deserializePools(message)
                    topArmy.engine.startDefense()
                } else {
                    bottomArmy.engine.deserializePools(message)
                    topArmy.engine.startOffense()
                }

                //    topArmy.startDefense()
                //    bottomArmy.startOffense()
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

        Component.onCompleted: {
            topArmy.startOffense()
        }

        armyOpponent: bottomArmy
        armyOrientation: "top"
        irc: irc
        locked: true
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
        locked: false
        Component.onCompleted: {

            //  bottomArmy.startDefense()
        }

        armyOpponent: topArmy
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

    ParticleSystem {}
}
