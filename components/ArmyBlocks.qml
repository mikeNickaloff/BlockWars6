import QtQuick 2.15
import "../scripts/main.js" as JS
import QuickFlux 1.0
import "../flux"

Item {
    id: armyBlocks
    width: {
        return parent.width * 0.95
    }
    height: {
        return parent.height * 0.95
    }
    anchors.centerIn: parent
    property var blocks: []
    property var armyOrientation: "bottom"
    property var armyOpponent: null
    property var armyReinforcements: []
    property var armyMoveEvents: []
    property var armyLocalQueue: []
    property var armyRemoteQueue: []
    property var irc: null
    property bool locked: false
    property int armyMovesMade: 0
    property var armyRoot: null
    property var armyIndex0: 0
    property var armyIndex1: 0
    property var armyIndex2: 0
    property var armyIndex3: 0
    property var armyIndex4: 0
    property var armyIndex5: 0
    onLockedChanged: {
        if (armyOrientation != "none") {
            var gb = JS.getGridBlocks(blocks)
            for (var i = 0; i < gb.lenth; i++) {

                gb[i].locked = locked
            }
            console.log(armyOrientation, "changed lock status: ", locked)
        }
    }
    function lock() {
        armyBlocks.locked = true
        ActionsController.armyBlocksSetLocked({
                                                  "orientation": armyBlocks.armyOrientation,
                                                  "locked": true
                                              })
    }
    function unlock() {
        armyBlocks.locked = false
        ActionsController.armyBlocksSetLocked({
                                                  "orientation": armyBlocks.armyOrientation,
                                                  "locked": false
                                              })
    }
    function startLocalEventTimer() {
        localEventTimer.running = true
    }
    Timer {
        id: localEventTimer
        interval: 100
        repeat: true
        running: false
        triggeredOnStart: false
        onTriggered: {
            if (armyLocalQueue.length > 0) {
                dequeueLocal()
            } else {

                if (armyRemoteQueue.length > 0) {
                    irc.sendMessageToCurrentChannel(irc.gameCommandMessage(
                                                        "QUEUE", JSON.stringify(
                                                            armyRemoteQueue)))
                    JS.createOneShotTimer(armyBlocks, 10, function () {
                        armyRemoteQueue = []
                    })
                }
            }
        }
    }
    function enqueueLocal(fn, args) {
        armyLocalQueue.push({
                                "fn": fn,
                                "args": args
                            })
    }
    function enqueueLocalToFront(fn, args) {
        armyLocalQueue.unshift({
                                   "fn": fn,
                                   "args": args
                               })
    }
    AppListener {
        filter: ActionTypes.armyBlocksCheckForMatches
        onDispatched: function (actionType, t_orientation) {
            console.log("Received armyBlock event for board", t_orientation,
                        "calling to checkForMatches,", actionType)
            if (t_orientation == armyBlocks.armyOrientation) {

                armyBlocks.enqueueLocalToFront(armyBlocks.removeBlockFunc, [])
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksCreateNewBlocks
        onDispatched: function (actionType, t_orientation) {
            console.log("Received armyBlock event for board", t_orientation,
                        "calling to createNewBlocks,", actionType)
            if (t_orientation == armyBlocks.armyOrientation) {

                armyBlocks.enqueueLocal(armyBlocks.createBlockFunc, [])
            }
        }
    }

    AppListener {
        filter: ActionTypes.enqueueArmyBlocksSetLocked
        onDispatched: function (actionType, i_data) {
            console.log("Received armyBlock event for board", i_data,
                        "calling to enqueue Lock event,", actionType)
            if (i_data.orientation == armyBlocks.armyOrientation) {

                if (i_data.locked == true) {
                    armyBlocks.enqueueLocal(armyBlocks.lock, [])
                } else {
                    armyBlocks.enqueueLocal(armyBlocks.unlock, [])
                }
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksRequestMovement
        onDispatched: function (actionType, i_data) {

            var iuuid = i_data.uuid
            var idirection = i_data.direction
            var irow = i_data.row
            var icol = i_data.column
            var iorientation = i_data.orientation

            if (iorientation == armyOrientation) {
                if (armyBlocks.armyMovesMade >= 3) {

                    // return 0
                }
                console.log("Movement changed for", iuuid, idirection, irow,
                            icol, iorientation)
                var rx = 0
                var cx = 0
                if (idirection == "right") {
                    cx = 1
                }
                if (idirection == "left") {
                    cx = -1
                }
                if (idirection == "down") {
                    rx = 1
                }
                if (idirection == "up") {
                    rx = -1
                }
                var newR = irow - rx
                var newC = icol - cx

                if (newR < 0) {
                    return
                }
                if (newR > 5) {
                    return
                }
                if (newC < 0) {
                    return
                }
                if (newC > 5) {
                    return
                }
                var blks = JS.getBlocksByRowAndCol(armyBlocks.blocks,
                                                   newR, newC)
                if (blks.length == 0) {
                    return
                }
                var blk2 = blks[0]
                blks = JS.getBlocksByRowAndCol(armyBlocks.blocks, irow, icol)
                if (blks.length == 0) {
                    return
                }
                var blk1 = blks[0]

                blks = JS.matchObjectsByProperties(blocks,
                                                   [JS.makePropertyObject(
                                                        "uuid", iuuid)])
                var otherblks = JS.matchObjectsByProperties(
                            blocks,
                            [JS.makePropertyObject("row",
                                                   newR), JS.makePropertyObject(
                                 "col", newC)])
                var swapList = []
                for (var u = 0; u < blks.length; u++) {
                    var swappedBlocks = []

                    blks[u].row = newR
                    blks[u].col = newC
                    swappedBlocks.push(blks[u].uuid)
                    for (var p = 0; p < otherblks.length; p++) {

                        otherblks[p].row = irow
                        otherblks[p].col = icol
                        swappedBlocks.push(otherblks[p].uuid)
                    }
                    if (swappedBlocks.length > 1) {
                        swapList.push(swappedBlocks)
                    }
                }
                if ((irow != newR) || (icol != newC)) {
                    enqueueRemote("syncGrid",
                                  [JS.compressArray(blocks.map(function (item) {
                                      return item.serialize()
                                  }))])
                    enqueueRemote("swapBlocks", [swapList, null])

                    ActionsController.blockSetRow({
                                                      "uuid": blk2.uuid,
                                                      "row": irow
                                                  })
                    ActionsController.blockSetColumn({
                                                         "uuid": blk2.uuid,
                                                         "column": icol
                                                     })
                    ActionsController.blockSetRow({
                                                      "uuid": blk1.uuid,
                                                      "row": newR
                                                  })
                    ActionsController.blockSetColumn({
                                                         "uuid": blk1.uuid,
                                                         "column": newC
                                                     })

                    enqueueLocal(stepBlockRefill, [])
                }

                //                var blks = JS.matchObjectsByProperties(blocks,
                //                                                       [JS.makePropertyObject(
                //                                                            "uuid", iuuid)])
                //                var otherblks = JS.matchObjectsByProperties(
                //                            blocks,
                //                            [JS.makePropertyObject("row",
                //                                                   newR), JS.makePropertyObject(
                //                                 "col", newC)])
                //                var swapList = []
                //                for (var u = 0; u < blks.length; u++) {
                //                    var swappedBlocks = []

                //                    blks[u].row = newR
                //                    blks[u].col = newC
                //                    swappedBlocks.push(blks[u].uuid)
                //                    for (var p = 0; p < otherblks.length; p++) {

                //                        otherblks[p].row = irow
                //                        otherblks[p].col = icol
                //                        swappedBlocks.push(otherblks[p].uuid)
                //                    }
                //                    if (swappedBlocks.length > 1) {
                //                        swapList.push(swappedBlocks)
                //                    }
                //                }
                //                if ((irow != newR) || (icol != newC)) {


                /*                    if (armyOrientation == "bottom") {

                        if ((armyRoot.movesMade < 3)
                                && (armyBlocks.locked == false)) {

                            enqueueRemote("swapBlocks", [swapList, null])

                            enqueueLocal(stepBlockRefill, [])
                        }
                    }
                } */
            }
        }
    }

    AppListener {
        filter: ActionTypes.armyBlocksSwapBlocks
        onDispatched: function (actionType, i_data) {
            console.log("Received armyBlock event for board", i_data,
                        "calling to armyBlocksSwapBlocks,", actionType)
            var t_orientation = i_data.orientation
            var t_uuid1 = i_data.uuid1
            var t_uuid2 = i_data.uuid2

            var blks = JS.matchObjectsByProperties(armyBlocks.blocks,
                                                   [JS.makePropertyObject(
                                                        "uuid", t_uuid1)])
            var blk1 = blks[0]
            blks = JS.matchObjectsByProperties(armyBlocks.blocks,
                                               [JS.makePropertyObject("uuid",
                                                                      t_uuid2)])
            var blk2 = blks[0]
            if (t_orientation == armyBlocks.armyOrientation) {
                var b1row = blk1.row
                var b1col = blk1.col
                var b2row = blk2.row
                var b2col = blk2.col
                blk1.row = b2row
                blk1.col = b2col
                blk2.row = b1row
                blk2.col = b2col
                enqueueLocal(removeBlockFunc, [])
            }

            //                armyBlocks.enqueueLocal(armyBlocks.createBlockFunc, [])
            //            }
        }
    }
    function dequeueLocal() {
        var movingBlocks = JS.filterObjectsByProperties(
                    blocks, [JS.makePropertyObject("isMoving", false)])
        if (movingBlocks.length > 0) {
            console.log("Blocks are still moving -- skipping dequeue local")
            return
        } else {
            if (armyLocalQueue.length > 0) {
                var item = armyLocalQueue.shift()

                if (item != null) {
                    if (item.fn != null) {
                        console.log("dequeueLocal: ",
                                    JSON.stringify(item.fn.name))
                        if (item.args != null) {
                            enqueueRemote(item.fn.name, item.args)
                            item.fn.apply(armyBlocks, item.args)
                        } else {
                            enqueueRemote(item.fn.name, [])
                            item.fn.apply(armyBlocks)
                        }
                    }
                }
            }
        }
    }
    function enqueueRemote(fn, args) {
        if (armyOrientation == "bottom") {
            if (fn != "createBlock")
                armyRemoteQueue.push({
                                         "fn": fn,
                                         "args": args
                                     })
        }
    }
    function dequeueRemote() {
        if (armyRemoteQueue.length > 0) {
            var item = armyRemoteQueue.shift()
            if (item) {

                //.apply(null, item.args)
            }
        }
    }
    onArmyReinforcementsChanged: {

    }
    signal blockRemoved(var row, var col)
    transform: [
        Rotation {
            origin.x: {
                return armyBlocks.Center ? armyBlocks.Center : 0
            }
            origin.y: {
                return armyBlocks.Center ? armyBlocks.Center : 0
            }
            axis {
                x: 1
                y: 0
                z: 0
            }
            angle: {
                return armyOrientation == "bottom" ? 180 : 0
            }
        },
        Translate {
            y: armyOrientation == "bottom" ? armyBlocks.height : 0
        }
    ]
    Component {
        id: blockComponent
        Block {}
    }


    /*  ActionsController {
        id: actionsController
    } */
    Component.onCompleted: {
        armyBlocks.locked = false
        localEventTimer.running = false

        JS.createOneShotTimer(armyBlocks, 200, function () {})
    }

    Rectangle {
        color: "#e2d1d1"
        border.color: "black"
        anchors.fill: parent
    }

    function stepBlockRefill(callback) {

        var movingBlocks = JS.filterObjectsByProperties(
                    blocks, [JS.makePropertyObject("isMoving", false)])
        if (movingBlocks.length > 0) {

            enqueueLocalToFront(stepBlockRefill, [])
        } else {

            var need_to_compact = false
            for (var i = 0; i < 6; i++) {
                if (need_to_compact) {
                    continue
                }
                for (var u = 0; u < 6; u++) {
                    if (need_to_compact) {
                        continue
                    }
                    var chk = JS.getBlocksByRowAndCol(armyBlocks.blocks, i, u)
                    if (chk.length == 0) {
                        need_to_compact = true
                    }
                }
            }
            if (need_to_compact) {

                enqueueLocal(compactBlocks, [])
            } else {

                enqueueLocalToFront(removeBlockFunc, [])
            }
        }
    }
    function createBlockFunc() {
        var should_check_later = false
        for (var i = 0; i < 6; i++) {

            for (var u = 0; u < 6; u++) {

                var chk = JS.getBlocksByRowAndCol(armyBlocks.blocks, i, u)
                if (chk.length == 0) {
                    enqueueLocal(createBlock, [i, u])
                    should_check_later = true
                }
            }
        }
        if (should_check_later) {
            enqueueLocal(removeBlockFunc, [])
        }
    }
    function refillFunc() {
        refillBlocks(function () {
            createBlocks(
                        function () {// enqueueLocalToFront(stepBlockRefill, [])
                        }, function () {// enqueueLocal(removeBlockFunc, [])
                        })
        }, function () {

            if (blocks.length < 36) {

                enqueueLocal(stepBlockRefill, [])
            } else {

            }
        })
    }
    function removeBlockFunc() {
        var movingBlocks = JS.filterObjectsByProperties(
                    blocks, [JS.makePropertyObject("isMoving", false)])
        if (movingBlocks.length > 0) {

            enqueueLocalToFront(stepBlockRefill, [])
        } else {
            var matchGroups = JS.getAdjacentBlocksGroups(blocks)
            var gotMatch = false
            var removeList = []
            for (var u = 0; u < matchGroups.length; u++) {
                if (matchGroups[u].length >= 3) {
                    for (var m = 0; m < matchGroups[u].length; m++) {
                        if (removeList.indexOf(matchGroups[u][m]) == -1) {

                            removeList.push(matchGroups[u][m])

                            gotMatch = true
                        }
                    }
                }
            }
            if (gotMatch) {
                removeBlocks(function () {

                    console.log("Remove Blocks matched blocks for",
                                armyOrientation)
                    enqueueLocal(compactBlocks, [])

                    ActionsController.armyBlocksCreateNewBlocks(
                                armyBlocks.armyOrientation)
                    enqueueLocal(compactBlocks, [])
                }, function () {
                    var lingering = JS.matchObjectsByProperties(
                                blocks, [JS.makePropertyObject("row", -1)])
                    if (lingering.length > 0) {
                        for (var u = 0; u < lingering; u++) {
                            lingering[u].row++
                        }
                    } else {
                        console.log("No removal needed")
                    }
                })
            } else {
                console.log("Step Block Refill finished")


                /* if (!armyBlocks.locked) {
                    if (armyBlocks.armyMovesMade >= 3) {
                        ActionsController.enqueueArmyBlocksSetLocked({
                                                                         "orientation": armyBlocks.armyOrientation,
                                                                         "locked": "true"
                                                                     })
                        ActionsController.enqueueArmyBlocksSetLocked({
                                                                         "orientation": armyBlocks.armyOrientation == "top" ? "top" : "bottom",
                                                                         "locked": "false"
                                                                     })
                    }
                } */
            }
        }
    }
    function compactBlocks() {
        refillBlocks(function () {
            console.log("Compact finished")
        }, function () {})
    }
    function getArmyCurrentIndex(col) {
        if (col == 0) {
            return armyBlocks.armyIndex0
        }
        if (col == 1) {
            return armyBlocks.armyIndex1
        }
        if (col == 2) {
            return armyBlocks.armyIndex2
        }
        if (col == 3) {
            return armyBlocks.armyIndex3
        }
        if (col == 4) {
            return armyBlocks.armyIndex4
        }
        if (col == 5) {
            return armyBlocks.armyIndex5
        }
    }
    function increaseArmyCurrentIndex(col) {
        if (col == 0) {
            armyBlocks.armyIndex0 += 1
        }
        if (col == 1) {
            armyBlocks.armyIndex1 += 1
        }
        if (col == 2) {
            armyBlocks.armyIndex2 += 1
        }
        if (col == 3) {
            armyBlocks.armyIndex3 += 1
        }
        if (col == 4) {
            armyBlocks.armyIndex4 += 1
        }
        if (col == 5) {
            armyBlocks.armyIndex5 += 1
        }
    }
    function setArmyCurrentIndex(col, val) {
        if (col == 0) {
            armyBlocks.armyIndex0 = val
        }
        if (col == 1) {
            armyBlocks.armyIndex1 = val
        }
        if (col == 2) {
            armyBlocks.armyIndex2 = val
        }
        if (col == 3) {
            armyBlocks.armyIndex3 = val
        }
        if (col == 4) {
            armyBlocks.armyIndex4 = val
        }
        if (col == 5) {
            armyBlocks.armyIndex5 = val
        }
    }
    function createBlock(row, col) {

        if (armyBlocks.armyReinforcements != null) {
            if (armyBlocks.armyReinforcements.length > 0) {
                increaseArmyCurrentIndex(col)
                if (getArmyCurrentIndex(col) >= 14) {
                    setArmyCurrentIndex(col, getArmyCurrentIndex(col) % 14)
                }
                var rez = JS.getArmyBlockDataByIndex(
                            armyBlocks.armyReinforcements, col,
                            getArmyCurrentIndex(col))
                var color = rez.color

                var uuid = rez.uuid
                var blk = blockComponent.createObject(armyBlocks, {
                                                          "row": row - 6,
                                                          "col": col,
                                                          "color": color,
                                                          "uuid": uuid,
                                                          "orientation": armyOrientation
                                                      })

                blk.row = row

                armyBlocks.blocks.push(blk)

                blk.removed.connect(function (irow, icol) {

                    var blk2 = JS.getBlocksByRowAndCol(blocks, irow, icol)[0]
                    blk2.visible = false

                    blocks = JS.removeBlocksByRowAndCol(blocks, irow, icol)
                    blk2.row = -1

                    blk2.color = JS.getRandomColor()
                    blockRemoved(irow, icol)
                })


                /*  blk.movementChanged.connect(
                            function (iuuid, idirection, irow, icol) {

                                if (armyBlocks.armyMovesMade >= 3) {

                                    // return 0
                                }
                                console.log("Movement changed for", iuuid,
                                            idirection, irow, icol)
                                var rx = 0
                                var cx = 0
                                if (idirection == "right") {
                                    cx = 1
                                }
                                if (idirection == "left") {
                                    cx = -1
                                }
                                if (idirection == "down") {
                                    rx = 1
                                }
                                if (idirection == "up") {
                                    rx = -1
                                }
                                var newR = irow - rx
                                var newC = icol - cx
                                if (newR < 0) {
                                    return
                                }
                                if (newR > 5) {
                                    return
                                }
                                if (newC < 0) {
                                    return
                                }
                                if (newC > 5) {
                                    return
                                }
                                var blks = JS.matchObjectsByProperties(
                                            blocks, [JS.makePropertyObject(
                                                         "uuid", iuuid)])
                                var otherblks = JS.matchObjectsByProperties(
                                            blocks,
                                            [JS.makePropertyObject(
                                                 "row",
                                                 newR), JS.makePropertyObject(
                                                 "col", newC)])
                                var swapList = []
                                for (var u = 0; u < blks.length; u++) {
                                    var swappedBlocks = []

                                    blks[u].row = newR
                                    blks[u].col = newC
                                    swappedBlocks.push(blks[u].uuid)
                                    for (var p = 0; p < otherblks.length; p++) {

                                        otherblks[p].row = irow
                                        otherblks[p].col = icol
                                        swappedBlocks.push(otherblks[p].uuid)
                                    }
                                    if (swappedBlocks.length > 1) {
                                        swapList.push(swappedBlocks)
                                    }
                                }
                                if ((irow != newR) || (icol != newC)) {
                                    if (armyOrientation == "bottom") {

                                        if ((armyRoot.movesMade < 3)
                                                && (armyBlocks.locked == false)) {

                                            enqueueRemote("swapBlocks",
                                                          [swapList, null])

                                            enqueueLocal(stepBlockRefill, [])
                                        }
                                    }
                                }
                            }) */
            } else {

            }
        } else {

        }
    }
    function swapBlocks(uuids, callback) {
        if (true == truee) {
            //if ((armyBlocks.locked == false) && (armyMovesMade < 3)) {
            for (var p = 0; p < uuids.length; p++) {
                if (uuids[p].length == 2) {
                    var blks = JS.matchObjectsByProperties(
                                armyBlocks.blocks,
                                [JS.makePropertyObject("uuid", uuids[p][0])])
                    var blks2 = JS.matchObjectsByProperties(
                                armyBlocks.blocks,
                                [JS.makePropertyObject("uuid", uuids[p][1])])
                    if (blks.length == 0) {
                        return
                    }
                    if (blks2.length == 0) {
                        return
                    }
                    var row1 = blks[0].row
                    var row2 = blks2[0].row
                    var col1 = blks[0].col
                    var col2 = blks2[0].col
                    //blks[0].row = row2
                    ActionsController.blockSetRow({
                                                      "blockId": blks[0].uuid,
                                                      "row": row2
                                                  })

                    ActionsController.blockSetRow({
                                                      "blockId": blks2[0].uuid,
                                                      "row": row1
                                                  })
                    ActionsController.blockSetColumn({
                                                         "blockId": blks[0].uuid,
                                                         "column": col2
                                                     })

                    ActionsController.blockSetColumn({
                                                         "blockId": blks2[0].uuid,
                                                         "column": col1
                                                     })
                }
            }
            if (callback != null) {

                //enqueueLocal(removeBlockFunc, [])
            }
        }
    }
    function refillBlocks(callbackTrue, callbackFalse) {

        var _dropped = false
        var toUpdate = []
        var res = JS.compactBlocks(blocks, armyOrientation)

        var didDrop = res[1]
        var syncList = res[2]
        for (var p = 0; p < syncList.length; p++) {
            if (toUpdate.indexOf(syncList[p]) == -1) {
                toUpdate.push(syncList[p])
            }
        }
        blocks = res[0]
        while (didDrop) {

            res = JS.compactBlocks(blocks, armyOrientation)
            blocks = res[0]
            didDrop = res[1]

            syncList = res[2]
            _dropped = true
            for (p = 0; p < syncList.length; p++) {
                if (toUpdate.indexOf(syncList[p]) == -1) {
                    toUpdate.push(syncList[p])
                }
            }
        }
        for (var q = 0; q < toUpdate.length; q++) {
            toUpdate[q].gridPositionChanged(toUpdate[q], toUpdate[q].row,
                                            toUpdate[q].col)
        }
        if (_dropped) {
            callbackTrue()
        } else {
            callbackFalse()
        }
    }
    function removeBlocks(callbackMatched, callbackNotMatched) {

        var matchGroups = JS.getAdjacentBlocksGroups(blocks)
        var gotMatch = false
        var removeList = []
        for (var u = 0; u < matchGroups.length; u++) {
            if (matchGroups[u].length >= 3) {
                for (var m = 0; m < matchGroups[u].length; m++) {
                    if (removeList.indexOf(matchGroups[u][m]) == -1) {

                        removeList.push(matchGroups[u][m])

                        gotMatch = true
                    }
                }
            }
        }

        for (var i = 0; i < removeList.length; i++) {
            removeList[i].removed(removeList[i].row, removeList[i].col)
        }
        // console.log(matchGroups)
        if (gotMatch) {

            callbackMatched()
        } else {
            callbackNotMatched()
        }
    }
    function createBlocks(callbackTrue, callbackFalse) {

        var createdBlocks = false
        for (var i = 0; i < 6; i++) {
            if (JS.getColOfBlocks(blocks, i).length < 6) {
                armyBlocks.createBlock(-1, i)
                createdBlocks = true
            }
        }
        if (createdBlocks) {
            callbackTrue()
        } else {
            callbackFalse()
        }
    }
    function addMoveEvent(action, params) {
        var moveEvt = {
            "action": action
        }

        for (var key in params) {
            moveEvt[key] = params[key]
        }
        armyBlocks.armyMoveEvents.push(moveEvt)
        // addLocalQueueEvent(action, params)
    }
    function addLocalQueueEvent(action, params) {
        var moveEvt = {
            "action": action,
            "params": params
        }

        for (var key in params) {
            moveEvt[key] = params[key]
        }
        armyBlocks.armyLocalQueue.push(moveEvt)
        console.log("Added queued event")
    }
}
