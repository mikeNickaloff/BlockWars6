import QtQuick 2.15
import com.blockwars.network 1.0
import QtQuick.Particles 2.0
import QuickFlux 1.0
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
                })
            }
        }
        onUserJoin: {

            if (user == "OperServ!services@services.datafault.net") {
                if (irc.getOpponentNickname() != "") {
                    bottomArmy.armyReinforcements = JS.generateArmyRandomNumbers()

                    //bottomArmy.blocks.addMoveEvent("stepBlockRefill", {})
                    JS.createOneShotTimer(gameRoot, 00, function () {
                        irc.sendMessageToCurrentChannel(
                                    irc.gameCommandMessage(
                                        "ARMY", JSON.stringify(
                                            JS.compressArray(
                                                bottomArmy.armyReinforcements))))
                    })
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
            console.log("Received Game Message", command, message)
            if (command == "ARMY") {
                var newArmy = irc.makeJSONDocument(message)
                if (typeof newArmy == "undefined") {
                    return
                }
                topArmy.armyReinforcements = JS.decompressArray(newArmy)
                JS.createOneShotTimer(gameRoot, 1000, function () {
                    topArmy.blocks.startLocalEventTimer()
                    bottomArmy.blocks.startLocalEventTimer()
                    for (var a = 0; a < 12; a++) {
                        for (var b = 0; b < 6; b++) {

                            bottomArmy.blocks.createBlock(a, b)

                            topArmy.blocks.createBlock(a, b)
                        }
                    }
                    var checkStr = "game_" + irc.nickname()
                    if (irc.currentChannel.indexOf(checkStr) > -1) {
                        topArmy.blocks.armyNextAction = ActionTypes.stateArmyBlocksArmyReadyDefense
                        bottomArmy.blocks.armyNextAction
                                = ActionTypes.stateArmyBlocksArmyReadyOffense
                    } else {
                        bottomArmy.blocks.armyNextAction
                                = ActionTypes.stateArmyBlocksArmyReadyDefense
                        topArmy.blocks.armyNextAction = ActionTypes.stateArmyBlocksArmyReadyOffense
                    }


                    /* bottomArmy.blocks.enqueueLocal(
                                bottomArmy.blocks.stepBlockRefill, [])

                    topArmy.blocks.enqueueLocal(topArmy.blocks.stepBlockRefill,
                                                []) */
                })
            }
            if (command == "REQUEST_QUEUE") {
                if (bottomArmy.blocks.armyRemoteQueue.length > 0) {
                    irc.sendMessageToCurrentChannel(
                                irc.gameCommandMessage(
                                    "QUEUE", JSON.stringify(
                                        JS.compressArray(
                                            bottomArmy.blocks.armyRemoteQueue))))
                    bottomArmy.blocks.armyRemoteQueue = []
                }
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
                        if (topArmy.blocks.armyNextAction == ActionTypes.stateArmyBlocksMoveStart) {
                            ActionsController.armyBlocksSwapBlocks({
                                                                       "orientation": "top",
                                                                       "uuid1": item.args[0],
                                                                       "uuid2": item.args[1]
                                                                   })
                        } else {
                            ActionsController.armyBlocksEnqueueConditional(
                                        "SWAP", {
                                            "orientation": "top",
                                            "uuid1": item.args[0],
                                            "uuid2": item.args[1]
                                        }, ActionTypes.stateArmyBlocksMoveStart)
                        }
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


                        /*topArmy.blocks.enqueueLocal(topArmy.blocks.swapBlocks,
                                                    item.args); */


                        /* var i_args = [
                                    [
                                        [
                                            "IREuR",
                                            "F</,x"
                                        ]
                                    ],
                                    null
                                ]; */


                        /* var uuid1 = item.args[0][0][0]
                        var uuid2 = item.args[0][0][1]

                        ActionsController.armyBlocksSwapBlocks({
                                                                   "orientation": "top",
                                                                   "uuid1": uuid1,
                                                                   "uuid2": uuid2
                                                               }) */


                        /*                        topArmy.blocks.armyMovesMade += 1
                        if (topArmy.blocks.armyMovesMade >= 3) {

                            //topArmy.locked = true
                            //bottomArmy.locked = false
                            ActionsController.enqueueArmyBlocksSetLocked({
                                                                             "orientation": "bottom",
                                                                             "locked": false
                                                                         })
                            ActionsController.enqueueArmyBlocksSetLocked({
                                                                             "orientation": "top",
                                                                             "locked": true
                                                                         })
                            bottomArmy.blocks.armyMovesMade = 0
                        } */
                    }
                }
            }
        }
    }

    function generateArmyRandomNumbers() {
        var rv = []

        for (var i = 0; i < 6; i++) {
            var index_obj = {}
            index_obj.col = i
            index_obj.index = 6

            index_obj.data = []
            var new_data = []
            for (var e = 0; e < 14; e++) {
                var obj = {}
                obj.index = e
                obj.uuid = JS.generateUuid(5, false)
                obj.color = JS.getRandomColor()
                new_data.push(obj)

                ActionsController.signalBlockCreated({
                                                         "orientation": "bottom",
                                                         "uuid": obj.uuid,
                                                         "column": i,
                                                         "row": e,
                                                         "color": obj.color,
                                                         "health": 5,
                                                         "opacity": 0
                                                     })
            }
            index_obj.data = new_data
            rv.push(index_obj)
        }
        return rv
        //console.log(JSON.stringify(rv))
    }
    function nextEvent() {
        var _evt = topArmy.blocks.armyMoveEvents
        if (_evt.length > 0) {
            var evt = _evt[0]
            topArmy.blocks.armyMoveEvents.shift()

            var action = evt.action
            if (action == "stepBlockRefill") {
                JS.createOneShotTimer(GameRoot, 100, function () {
                    topArmy.blocks.stepBlockRefill(function () {
                        eventTimer.running = true
                        eventTimer.restart()
                    })
                })
            }
            if (action == "swap") {
                var uuids = evt.uuids
                console.log("swapping", uuids)
                topArmy.blocks.armyMovesMade += 1

                if (topArmy.blocks.armyMovesMade >= 3) {
                    //  topArmy.locked = true
                    // bottomArmy.locked = false
                    ActionsController.enqueueArmyBlocksSetLocked({
                                                                     "orientation": "bottom",
                                                                     "locked": false
                                                                 })
                    ActionsController.enqueueArmyBlocksSetLocked({
                                                                     "orientation": "top",
                                                                     "locked": true
                                                                 })
                    bottomArmy.blocks.armyMovesMade = 0
                }
                topArmy.blocks.swapBlocks(uuids, function () {
                    topArmy.blocks.stepBlockRefill(function () {

                        //                                irc.sendMessageToCurrentChannel(
                        //                                            irc.gameCommandMessage("SYNC",
                        //                                                                   "1111"))
                        console.log("Move Completed")
                        eventTimer.running = false
                        eventTimer.restart()
                    })
                })
            }
            if (action == "sync") {

                eventTimer.running = true
                eventTimer.restart()
            }
        }
    }
    Timer {
        id: eventTimer
        repeat: false
        interval: 100
        running: false
        onTriggered: {
            if (topArmy.blocks.armyMoveEvents.length > 0) {

                // nextEvent()
            }
        }
    }
    Timer {
        id: sendEventTimer
        repeat: true
        interval: 500
        running: false
        onTriggered: {

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
