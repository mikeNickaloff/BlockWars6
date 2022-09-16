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
                    JS.createOneShotTimer(gameRoot, 200, function () {
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
                if (irc.currentChannel.indexOf(
                            irc.nickname) > irc.currentChannel.indexOf(
                            irc.getOpponentNickname())) {
                    //bottomArmy.locked = false
                    //topArmy.locked = true
                    ActionsController.enqueueArmyBlocksSetLocked({
                                                                     "orientation": "bottom",
                                                                     "locked": false
                                                                 })
                    ActionsController.enqueueArmyBlocksSetLocked({
                                                                     "orientation": "top",
                                                                     "locked": true
                                                                 })
                } else {
                    ActionsController.enqueueArmyBlocksSetLocked({
                                                                     "orientation": "bottom",
                                                                     "locked": true
                                                                 })
                    ActionsController.enqueueArmyBlocksSetLocked({
                                                                     "orientation": "top",
                                                                     "locked": false
                                                                 })
                    //bottomArmy.locked = true
                    //topArmy.locked = false
                }
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
                    for (var a = 0; a < 6; a++) {
                        for (var b = 0; b < 6; b++) {

                            bottomArmy.blocks.createBlock(a, b)

                            topArmy.blocks.createBlock(a, b)
                        }
                    }
                    bottomArmy.blocks.enqueueLocal(
                                bottomArmy.blocks.stepBlockRefill, [])

                    topArmy.blocks.enqueueLocal(topArmy.blocks.stepBlockRefill,
                                                [])
                })
            }


            /* if (command == "NEEDARMY") {
                if (message == irc.hash(JSON.stringify(
                                            JS.getArmyIndices(
                                                bottomArmy.blocks)))) {

                    irc.sendMessageToCurrentChannel(irc.gameCommandMessage(
                                                        "SKIPARMY", "11111"))
                } else {
                    irc.sendMessageToCurrentChannel(
                                irc.gameCommandMessage(
                                    "ARMY", JSON.stringify(
                                        bottomArmy.armyReinforcements)))
                }
            }
            if (command == "SKIPARMY") {
                if (bottomArmy.blocks.armyMoveEvents.length > 0) {

                    //                    irc.sendMessageToCurrentChannel(
                    //                                irc.gameCommandMessage(
                    //                                    "EVENTS", JSON.stringify(
                    //                                        bottomArmy.blocks.armyMoveEvents)))
                    //                    JS.createOneShotTimer(gameRoot, 250, function () {
                    //                        bottomArmy.blocks.armyMoveEvents = []
                    //                    })
                } else {
                    bottomArmy.blocks.stepBlockRefill(function () {
                        irc.sendMessageToCurrentChannel(irc.gameCommandMessage(
                                                            "READY", "1111"))
                        console.log("Move Completed")
                    })
                }
            }
            if (command == "NEEDBLOCKS") {
                JS.createOneShotTimer(gameRoot, 1000, function () {

                    irc.sendMessageToCurrentChannel(
                                irc.gameCommandMessage(
                                    "BLOCKS", JSON.stringify(
                                        JS.compressArray(
                                            bottomArmy.blocks.blocks.map(
                                                function (item) {
                                                    return item.serialize()
                                                })))))
                })
            }
            if (command == "BLOCKS") {
                var _newBlocks = irc.makeJSONDocument(message)

                if (typeof _newBlocks == "undefined") {
                    return
                }
                var newBlocks = JS.decompressArray(_newBlocks)
                for (var i = 0; i < newBlocks.length; i++) {
                    var blkList = JS.matchObjectsByProperties(
                                topArmy.blocks.blocks,
                                [JS.makePropertyObject(
                                     "row",
                                     newBlocks[i].row), JS.makePropertyObject(
                                     "col", newBlocks[i].col)])

                    if (blkList.length == 0) {
                        topArmy.blocks.createBlock(newBlocks[i].row,
                                                   newBlocks[i].col)

                        topArmy.blocks.stepBlockRefill(function () {
                            blkList = JS.matchObjectsByProperties(
                                        topArmy.blocks.blocks,
                                        [JS.makePropertyObject(
                                             "row",
                                             newBlocks[i].row), JS.makePropertyObject(
                                             "col", newBlocks[i].col)])

                            for (var u = 0; u < blkList.length; u++) {
                                blkList[u].color = newBlocks[i].color
                                blkList[u].uuid = newBlocks[i].uuid
                            }
                        })
                    }

                    //  blkList[u].uuid = newBlocks[i].uuid
                }

                topArmy.blocks.stepBlockRefill(function () {
                    JS.createOneShotTimer(gameRoot, 1000, function () {
                        irc.sendMessageToCurrentChannel(
                                    irc.gameCommandMessage("READY",
                                                           "111111111"))
                    })
                })
            }
            if (command == "NEEDEVENTS") {

                if (bottomArmy.blocks.armyMoveEvents.length > 0) {
                    irc.sendMessageToCurrentChannel(
                                irc.gameCommandMessage(
                                    "EVENTS", JSON.stringify(
                                        bottomArmy.blocks.armyMoveEvents)))
                    JS.createOneShotTimer(gameRoot, 250, function () {
                        bottomArmy.blocks.armyMoveEvents = []
                    })
                } else {
                    bottomArmy.blocks.stepBlockRefill(function () {
                        irc.sendMessageToCurrentChannel(
                                    irc.gameCommandMessage(
                                        "READY", JSON.stringify(
                                            bottomArmy.blocks.armyMoveEvents)))

                        console.log("Move Completed")
                    })
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
            if (command == "EVENTS") {
                var _evt = irc.makeJSONDocument(message)
                if (typeof _evt == "undefined") {
                    return
                }
                if (_evt.length == 0) {
                    irc.sendMessageToCurrentChannel(irc.gameCommandMessage(
                                                        "NEEDBLOCKS", "111111"))
                    return
                }
                for (var a = 0; a < _evt.length; a++) {
                    var evt = _evt[a]

                    //topArmy.blocks.addReqEvent(evt)
                    var action = evt.action

                    // topArmy.blocks.armyLocalQueue.push(evt)
                    // continue
                    if (action == "swap") {
                        var uuids = evt.uuids
                        console.log("swapping", uuids)
                        topArmy.blocks.swapBlocks(uuids, function () {
                            topArmy.blocks.stepBlockRefill(function () {

                                //                                irc.sendMessageToCurrentChannel(
                                //                                            irc.gameCommandMessage("SYNC",
                                //                                                                   "1111"))
                                console.log("Move Completed")
                            })
                        })
                    }
                    if (action == "sync") {
                        var _newblocks = irc.makeJSONDocument(evt.blocks)

                        if (typeof _newBlocks == "undefined") {
                            return
                        }
                        var newBlocks = _newBlocks
                        for (var i = 0; i < newBlocks.length; i++) {
                            var blkList = JS.matchObjectsByProperties(
                                        topArmy.blocks.blocks,
                                        [JS.makePropertyObject(
                                             "row",
                                             newBlocks[i].row), JS.makePropertyObject(
                                             "col", newBlocks[i].col)])

                            if (blkList.length == 0) {
                                topArmy.blocks.createBlock(newBlocks[i].row,
                                                           newBlocks[i].col)



                            }

                            //  blkList[u].uuid = newBlocks[i].uuid
                        }

                        topArmy.blocks.stepBlockRefill(function () {
                            JS.createOneShotTimer(gameRoot, 1000, function () {
                                irc.sendMessageToCurrentChannel(
                                            irc.gameCommandMessage("READY",
                                                                   "111111111"))
                            })
                        })
                    }

                }
            }
            */


            /*            if (command == "SYNC") {
                JS.createOneShotTimer(gameRoot, 100, function () {
                    irc.sendMessageToCurrentChannel(
                                irc.gameCommandMessage(
                                    "NEEDEVENTS",
                                    irc.hash(JSON.stringify(
                                                 JS.getArmyIndices(
                                                     bottomArmy.blocks)))))
                })
            }
            */
            if (command == "QUEUE") {
                var queue = irc.makeJSONDocument(message)
                for (var i = 0; i < queue.length; i++) {
                    var item = queue[i]
                    console.log("[TOP] Going to execute:", item.fn)

                    if (item.fn == "stepBlockRefill")
                        topArmy.blocks.enqueueLocal(
                                    topArmy.blocks.stepBlockRefill, item.args)

                    //                    if (item.fn == "removeBlockFunc")
                    //                        topArmy.blocks.enqueueLocal(
                    //                                    topArmy.blocks.removeBlockFunc, item.args)
                    //                    if (item.fn == "compactBlocks")
                    //                        topArmy.blocks.enqueueLocal(
                    //                                    topArmy.blocks.compactBlocks, item.args)
                    //                    if (item.fn == "createBlockFunc")
                    //                        topArmy.blocks.enqueueLocal(
                    //                                    topArmy.blocks.createBlockFunc, item.args)
                    //                    if (item.fn == "refillFunc")
                    //                        topArmy.blocks.enqueueLocal(topArmy.blocks.refillFunc,
                    //                                                    item.args)

                    //                    if (item.fn == "createBlock")
                    //                        topArmy.blocks.enqueueLocal(topArmy.blocks.createBlock,
                    //                                                    item.args)
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
                        var uuid1 = item.args[0][0][0]
                        var uuid2 = item.args[0][0][1]

                        ActionsController.armyBlocksSwapBlocks({
                                                                   "orientation": "top",
                                                                   "uuid1": uuid1,
                                                                   "uuid2": uuid2
                                                               })

                        topArmy.blocks.armyMovesMade += 1
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
                        }
                    }
                }
            }
        }
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
                        eventTimer.running = true
                        eventTimer.restart()
                    })
                })
            }
            if (action == "sync") {


                /*var _newblocks = irc.makeJSONDocument(evt.blocks)

                if (typeof _newBlocks == "undefined") {

                    eventTimer.running = true
                    eventTimer.restart()
                    return
                }
                var newBlocks = _newBlocks
                for (var i = 0; i < newBlocks.length; i++) {
                    var blkList = JS.matchObjectsByProperties(
                                topArmy.blocks.blocks,
                                [JS.makePropertyObject(
                                     "row",
                                     newBlocks[i].row), JS.makePropertyObject(
                                     "col", newBlocks[i].col)])

                    if (blkList.length == 0) {
                        topArmy.blocks.createBlock(newBlocks[i].row,
                                                   newBlocks[i].col)

                        topArmy.blocks.stepBlockRefill(function () {
                            blkList = JS.matchObjectsByProperties(
                                        topArmy.blocks.blocks,
                                        [JS.makePropertyObject(
                                             "row",
                                             newBlocks[i].row), JS.makePropertyObject(
                                             "col", newBlocks[i].col)])

                            for (var u = 0; u < blkList.length; u++) {
                                blkList[u].color = newBlocks[i].color
                                blkList[u].uuid = newBlocks[i].uuid
                            }
                            eventTimer.running = true
                            eventTimer.restart()
                        })
                    } else {
                        eventTimer.running = true
                        eventTimer.restart()
                    }

                    //  blkList[u].uuid = newBlocks[i].uuid
                }

*/


                /*     topArmy.blocks.stepBlockRefill(function () {
                    JS.createOneShotTimer(gameRoot, 1000, function () {
                        irc.sendMessageToCurrentChannel(
                                    irc.gameCommandMessage("READY",
                                                           "111111111"))
                    })
                }) */
                eventTimer.running = true
                eventTimer.restart()
            }
            //                    topArmy.blocks.stepBlockRefill(function () {
            //                        JS.createOneShotTimer(gameRoot, 100, function () {
            //                            irc.sendMessageToCurrentChannel(
            //                                        irc.gameCommandMessage("READY",
            //                                                               "111111111"))
            //                        })
            //                    })
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
        running: true
        onTriggered: {


            /*
            if (bottomArmy.blocks.armyMoveEvents.length > 0) {
                irc.sendMessageToCurrentChannel(
                            irc.gameCommandMessage(
                                "EVENTS", JSON.stringify(
                                    bottomArmy.blocks.armyMoveEvents)))
                bottomArmy.blocks.armyMoveEvents = []
            } else {

                //            bottomArmy.blocks.stepBlockRefill(function () {
                //                irc.sendMessageToCurrentChannel(
                //                            irc.gameCommandMessage(
                //                                "READY", JSON.stringify(
                //                                    bottomArmy.blocks.armyMoveEvents)))

                //                console.log("Move Completed")
                //            })
            }
            */
        }
    }

    //    ChannelTransport {
    //        id: transport
    //        onSocketChanged: {
    //            socket.channelMessageReceived.connect(transport.onmessage)
    //        }
    //        function send(msg) {
    //            if (transport.socket != null) {
    //                socket.sendChannelMessage(msg)
    //                console.log("Sending message", msg)
    //                //   socket.channelMessageReceived.connect(transport.onmessage)
    //            }
    //        }
    //        property var onmessage
    //    }
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
