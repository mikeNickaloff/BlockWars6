import QtQuick 2.15
import "../scripts/main.js" as JS

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
    property var armyReinforcements: []
    property var armyMoveEvents: []
    property var armyLocalQueue: []
    property var armyRemoteQueue: []
    property var irc: null
    property bool locked: false
    property var armyIndex0: 0
    property var armyIndex1: 0
    property var armyIndex2: 0
    property var armyIndex3: 0
    property var armyIndex4: 0
    property var armyIndex5: 0
    onLockedChanged: {
        console.log(armyOrientation, "changed lock status: ", locked)
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

    Component.onCompleted: {
        armyBlocks.locked = false
        localEventTimer.running = false
        //        for (var a = 0; a < 6; a++) {
        //            for (var b = 0; b < 6; b++) {
        //                enqueueLocal(createBlock, [a, b])
        //            }
        //        }
        //        //  console.log(JS.matchObjectsByProperties(blocks,
        //        //                                         [JS.makePropertyObject("row",
        //        //                                                              3)]))
        //        JS.createOneShotTimer(armyBlocks, 5000, function () {})
        JS.createOneShotTimer(armyBlocks, 200,
                              function () {//   var newBlocks = blocks
                                  // stepBlockRefill()
                                  //localEventTimer.running = true
                              })

        //  stepBlockRefill(function () {
        //  console.log(JSON.stringify(armyBlocks.armyMoveEvents))
        //    addMoveEvent("stepBlockRefill", {})
        // })
    }

    Rectangle {
        color: "#e2d1d1"
        border.color: "black"
        anchors.fill: parent
    }
    function stepBlockRefill(callback) {

        //        if (armyBlocks.locked) {
        //            JS.createOneShotTimer(armyBlocks, 80, function () {
        //                stepBlockRefill(callback)
        //            })
        //            return
        //        }
        var movingBlocks = JS.filterObjectsByProperties(
                    blocks, [JS.makePropertyObject("isMoving", false)])
        if (movingBlocks.length > 0) {

            enqueueLocalToFront(stepBlockRefill, [])
        } else {
            // localEventTimer.running = true
            //            if (blocks.length >= 36) {

            //                //localEventTimer.running = true
            //                // enqueueLocalToFront(stepBlockRefill, [])
            //                enqueueLocalToFront(removeBlockFunc, [])

            //                enqueueLocalToFront(compactBlocks, [])
            //            } else {

            //                //  enqueueLocal(refillFunc, [])
            //            }
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
        for (var i = 0; i < 6; i++) {

            for (var u = 0; u < 6; u++) {

                var chk = JS.getBlocksByRowAndCol(armyBlocks.blocks, i, u)
                if (chk.length == 0) {
                    enqueueLocal(createBlock, [i, u])
                }
            }
        }
        // enqueueLocal(stepBlockRefill, [])
        //createBlocks(function () {}, function () {})
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
                // createBlocks(function () {}, function () {})
            } else {

                // addMoveEvent("stepBlockRefill", {})
            }
        })
    }
    function removeBlockFunc() {
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

                console.log("Remove Blocks matched blocks for", armyOrientation)
                enqueueLocal(compactBlocks, [])
                enqueueLocal(createBlockFunc, [])
                enqueueLocal(compactBlocks, [])

                // enqueueLocal(stepBlockRefill, [])
            }, function () {
                var lingering = JS.matchObjectsByProperties(
                            blocks, [JS.makePropertyObject("row", -1)])
                if (lingering.length > 0) {
                    for (var u = 0; u < lingering; u++) {
                        lingering[u].row++
                    }
                } else {
                    console.log("No removal needed")

                    //enqueueLocal(compactBlocks, [])
                    //old callback position
                    //                enqueueLocalToFront(stepBlockRefill, [])
                    //                enqueueLocalToFront(compactBlocks, [])
                    //                enqueueLocalToFront(createBlockFunc, [])
                    //                enqueueLocalToFront(compactBlocks, [])
                }
            })
        } else {
            console.log("Step Block Refill finished")
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
                                                          "uuid": uuid
                                                      })
                blk.row = row
                if (armyOrientation == "bottom") {

                    //enqueueLocalToFront(createBlock, [row, col])

                    //                    addMoveEvent("createBlock", {
                    //                                     "row": row,
                    //                                     "col": col,
                    //                                     "color": color,
                    //                                     "uuid": uuid
                    //                                 })
                }
                armyBlocks.blocks.push(blk)

                blk.removed.connect(function (irow, icol) {
                    //                    if (armyBlocks.armyOrientation != "bottom") {
                    //                        return
                    //                    }
                    var blk2 = JS.getBlocksByRowAndCol(blocks, irow, icol)[0]
                    blk2.visible = false
                    //                    addMoveEvent("removed", {
                    //                                     "row": irow,
                    //                                     "col": icol,
                    //                                     "uuid": blk2.uuid
                    //                                 })
                    blocks = JS.removeBlocksByRowAndCol(blocks, irow, icol)
                    blk2.row = -1
                    blk2.color = JS.getRandomColor()
                    blockRemoved(irow, icol)
                    //                    addMoveEvent("removed", {
                    //                                     "row": irow,
                    //                                     "col": icol,
                    //                                     "uuid": blk2.uuid
                    //                                 })

                    //                                            var moveEvt = {
                    //                                                "action": "stepBlockRefill()"
                    //                                            }
                    //                                            armyBlocks.armyMoveEvents.push(moveEvt)
                    //enqueueLocal(stepBlockRefill, [])
                })
                blk.gridPositionChanged.connect(function (iblock, irow, icol) {
                    if (armyOrientation == armyOrientation) {
                        var at_bottom = true
                        for (var a = iblock.row; a < 6; a++) {
                            if (JS.getBlocksByRowAndCol(armyBlocks.blocks, a,
                                                        icol).length > 0) {
                                continue
                            } else {
                                at_bottom = false
                            }
                        }
                        if (at_bottom) {
                            if (irow == 5) {
                                //                                addMoveEvent("gridPositionChange", {
                                //                                                 "row": irow,
                                //                                                 "col": icol,
                                //                                                 "uuid": iblock.uuid
                                //                                             })
                                var moveEvt = {
                                    "uuid": iblock.uuid,
                                    "action": "props",
                                    "properties": ["row", "col"],
                                    "values": [irow, icol]
                                }
                                //                                JS.createOneShotTimer(armyBlocks, 1000,
                                //                                                      function () {

                                //                                                          irc.sendMessageToCurrentChannel(
                                //                                                                      irc.gameCommandMessage(
                                //                                                                          "BLOCKS",
                                //                                                                          JSON.stringify(JS.compressArray(armyBlocks.blocks.map(function (item) {
                                //                                                                              return item.serialize(
                                //                                                                                          )
                                //                                                                          })))))
                                //                                                      })
                                //   armyBlocks.armyMoveEvents.push(moveEvt)
                            }
                        }


                        /*if (armyOrientation == "bottom") {

                        irc.sendMessageToCurrentChannel(
                                    irc.gameCommandMessage(
                                        "EVENTS", irc.compress(
                                            JSON.stringify(
                                                armyBlocks.armyMoveEvents))))
                        armyMoveEvents = []
                    } */
                    }
                })
                //  signal movementChanged(var uuid, var direction, var row, var col)
                blk.movementChanged.connect(
                            function (iuuid, idirection, irow, icol) {
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
                                        //                                        addMoveEvent("sync", {
                                        //                                                         "blocks": JSON.stringify(
                                        //                                                                       armyBlocks.blocks.map(
                                        //                                                                           function (item) {
                                        //                                                                               return item.serialize()
                                        //                                                                           }))
                                        //                                                     })
                                        enqueueRemote("swapBlocks",
                                                      [swapList, null])
                                        for (var pi = 0; pi < swapList.length; pi++) {

                                            //                                            addMoveEvent("swap", {
                                            //                                                             "uuids": swapList[pi]
                                            //                                                         })
                                            //                                            var moveEvt = {
                                            //                                                "action": "swap",
                                            //                                                "uuids": swapList[pi]
                                            //                                            }
                                            //                                            armyBlocks.armyMoveEvents.push(
                                            //                                                        moveEvt)
                                        }

                                        enqueueLocal(stepBlockRefill, [])


                                        /* stepBlockRefill(function () {

                                            JS.createOneShotTimer(armyBlocks,
                                                                  100,
                                                                  function () {

                                                                  })
                                        }) */
                                    }
                                }
                            })
            } else {

            }
        } else {

            //            JS.createOneShotTimer(armyBlocks, 200, function () {
            //                createBlock(row, col)
            //            })
        }
    }
    function swapBlocks(uuids, callback) {
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
                blks[0].row = row2
                blks2[0].row = row1
                blks[0].col = col2
                blks2[0].col = col1
            }
        }
        if (callback != null) {

            //enqueueLocal(removeBlockFunc, [])
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
            //  removeList[i].row = -1
            //  removeList[i].color = JS.getRandomColor()
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
