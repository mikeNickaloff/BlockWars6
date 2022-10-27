import QtQuick 2.15
import "../scripts/main.js" as JS
import QuickFlux 1.1
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
    property var blocks: ({})
    property var armyOrientation: "bottom"
    property var armyOpponent: null
    property var armyReinforcements: []
    property var armyMoveEvents: []
    property var armyLocalQueue: []
    property var armyRemoteQueue: []
    property var armyLaunchQueue: []
    property var armyPostLaunchQueue: []
    property var armyActionLogger: []
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
    property var armyActiveLaunchCount: 0
    property var armyGameEngine
    // list of Actions:
    property var armyLastAction: null
    property var armyNextAction: ActionTypes.armyBlocksInit
    property var armyPostSyncState: null
    property var armyConditionalQueue: []
    property var armyBoneYard: []
    property double armyShakeOffset: 0
    property var armyBlockQueues: {
        "0": [],
        "1": [],
        "2": [],
        "3": [],
        "4": [],
        "5": []
    }
    property var armyBlockStacks: {
        "0": [],
        "1": [],
        "2": [],
        "3": [],
        "4": [],
        "5": []
    }
    property var armyBlockMatchData: {

    }

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
    function startLocalEventTimer() {//localEventTimer.running = true
    }

    function shakeScreen() {

        if (animationShake.running === false) {
            console.log("shaking screen")
            animationShake.running = true
        }
    }

    SequentialAnimation {
        id: animationShake
        running: false

        ScriptAction {

            script: {

                //gameGrid.playExplodeSound()
            }
        }
        SequentialAnimation {
            loops: 3

            PropertyAnimation {
                target: armyBlocks.parent
                property: "armyShakeOffset"
                from: 0
                to: 10

                duration: 20
            }
            PropertyAnimation {
                target: armyBlocks.parent
                property: "armyShakeOffset"
                from: 10
                to: 0

                duration: 20
            }
        }
    }


    /*   Timer {
        id: nextActionDeterminatorTimer
        interval: 750
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {



            gameEngine.checkMissionStatus()
        }
    } */
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
                            //enqueueRemote(item.fn.name, item.args)
                            item.fn.apply(armyBlocks, item.args)
                        } else {
                            //enqueueRemote(item.fn.name, [])
                            item.fn.apply(armyBlocks)
                        }
                    }
                }
            }
        }
    }
    function enqueueRemote(fn, args) {
        if (armyOrientation === "bottom") {
            if (fn != "createBlock")
                armyRemoteQueue.push({
                                         "fn": fn,
                                         "args": args
                                     })
            console.log(JSON.stringify(armyRemoteQueue))
            irc.sendMessageToCurrentChannel(
                        irc.gameCommandMessage("QUEUE",
                                               JSON.stringify(armyRemoteQueue)))
            JS.createOneShotTimer(armyBlocks, 10, function () {
                armyRemoteQueue = []
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
                return armyOrientation === "bottom" ? 180 : 0
            }
        },
        Translate {
            y: armyOrientation === "bottom" ? armyBlocks.height : 0
            x: armyShakeOffset
        },
        Translate {
            y: armyShakeOffset
        }
    ]
    Component {
        id: blockComponent
        Block {}
    }

    Component.onCompleted: {
        armyBlocks.locked = false

        //JS.createOneShotTimer(armyBlocks, 200, function () {})
    }

    Rectangle {
        color: "#e2d1d1"
        border.color: "black"
        anchors.fill: parent
    }

    property var actionQueue: []

    function compactBlocks() {

        refillBlocks(function () {
            console.log("Compact finished")
            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreCompactBlocks) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreCreateBlocks
            }
            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksCompactBlocks) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksCreateBlocks
            }
        }, function () {
            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreCompactBlocks) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreCreateBlocks
            }
            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksCompactBlocks) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksCreateBlocks
            }
        })
    }
    function getArmyCurrentIndex(col) {
        if (col === 0) {
            return armyBlocks.armyIndex0
        }
        if (col === 1) {
            return armyBlocks.armyIndex1
        }
        if (col === 2) {
            return armyBlocks.armyIndex2
        }
        if (col === 3) {
            return armyBlocks.armyIndex3
        }
        if (col === 4) {
            return armyBlocks.armyIndex4
        }
        if (col === 5) {
            return armyBlocks.armyIndex5
        }
    }
    function increaseArmyCurrentIndex(col) {
        if (col === 0) {
            armyBlocks.armyIndex0 += 1
        }
        if (col === 1) {
            armyBlocks.armyIndex1 += 1
        }
        if (col === 2) {
            armyBlocks.armyIndex2 += 1
        }
        if (col === 3) {
            armyBlocks.armyIndex3 += 1
        }
        if (col === 4) {
            armyBlocks.armyIndex4 += 1
        }
        if (col === 5) {
            armyBlocks.armyIndex5 += 1
        }
    }
    function setArmyCurrentIndex(col, val) {
        if (col === 0) {
            armyBlocks.armyIndex0 = val
        }
        if (col === 1) {
            armyBlocks.armyIndex1 = val
        }
        if (col === 2) {
            armyBlocks.armyIndex2 = val
        }
        if (col === 3) {
            armyBlocks.armyIndex3 = val
        }
        if (col === 4) {
            armyBlocks.armyIndex4 = val
        }
        if (col === 5) {
            armyBlocks.armyIndex5 = val
        }
    }

    function getNextColor(col) {

        if (armyBlocks.armyReinforcements != null) {
            if (armyBlocks.armyReinforcements.length > 0) {
                increaseArmyCurrentIndex(col)
                if (getArmyCurrentIndex(col) >= 14) {
                    setArmyCurrentIndex(col, getArmyCurrentIndex(col) % 14)
                }
                var rez = JS.getArmyBlockDataByIndex(
                            armyBlocks.armyReinforcements, col,
                            getArmyCurrentIndex(col))
                return rez.color
            }
        }
    }
    function createBlock(row, col, uuid = "", color) {

        var blk = blockComponent.createObject(armyBlocks, {
                                                  "row": row,
                                                  "col": col,
                                                  "color": color,
                                                  "uuid": uuid,
                                                  "orientation": armyOrientation,
                                                  "health": 5,
                                                  "opacity": 1.0
                                              })

        blk.row = row
        blk.col = col

        armyBlocks.blocks[blk.uuid] = blk
        //    console.log("----")
        //  console.log("Block created", JSON.stringify(blk.serialize()))


        /*ActionsController.signalBlockCreated({
                                                         "orientation": armyOrientation,
                                                         "uuid": uuid,
                                                         "row": row,
                                                         "column": col,
                                                         "health": 5,
                                                         "color": color
                                                     })
                                                     */


        /*  blk.removed.connect(function (irow, icol) {

                    var blk2 = JS.getBlocksByRowAndCol(
                                blocks, armyBlocks.armyBlockStacks,
                                irow, icol)[0]
                    blk2.visible = false

                    blocks = JS.removeBlocksByRowAndCol(blocks, irow, icol)
                    blk2.row = -1

                    blk2.color = JS.getRandomColor()

                    blockRemoved(irow, icol)
                }) */
    }


    /* AppListener {
        filter: ActionTypes.armyBlocksCheckForMatches
        onDispatched: function (actionType, t_orientation) {
            //        console.log("Received armyBlock event for board", t_orientation,
            //                  "calling to checkForMatches,", actionType)
            if (t_orientation === armyBlocks.armyOrientation) {
                ActionsController.armyBlocksEnableMouseArea({
                                                                "orientation": armyOrientation,
                                                                "enabled": false
                                                            })
                armyBlocks.enqueueLocalToFront(armyBlocks.checkMatches, [])
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksCreateNewBlocks
        onDispatched: function (actionType, t_orientation) {
            ///      console.log("Received armyBlock event for board", t_orientation,
            //                "calling to createNewBlocks,", actionType)
            if (t_orientation === armyBlocks.armyOrientation) {

                armyBlocks.enqueueLocal(armyBlocks.createBlockFunc, [])
            }
        }
    }

    AppListener {
        filter: ActionTypes.enqueueArmyBlocksSetLocked
        onDispatched: function (actionType, i_data) {
            //       console.log("Received armyBlock event for board", i_data,
            //                   "calling to enqueue Lock event,", actionType)
            if (i_data.orientation === armyBlocks.armyOrientation) {

                if (i_data.locked === true) {
                    armyBlocks.enqueueLocal(armyBlocks.lock, [])
                } else {
                    armyBlocks.enqueueLocal(armyBlocks.unlock, [])
                }
            }
        }
    }
*/
    AppListener {
        filter: ActionTypes.blockLaunchCompleted
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == armyBlocks.armyOrientation) {
                if (blocks[i_data.uuid] != null) {
                    var block = blocks[i_data.uuid]
                    if (i_data.uuid == block.attackingUuid) {
                        block.explode()
                        block.attackingUuid = ""

                        // }
                    }
                }
            } else {
                shakeScreen()
            }
        }
    }
    AppListener {
        filter: ActionTypes.blockSetRow
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            var i_row = i_data.row
            if (blocks[i_blockId] != null) {
                var block = blocks[i_blockId]
                block.reportBackAfterMovement = true
                //console.log("received block event: setRow", i_blockId, i_row)
                block.row = i_row
                if (i_row <= 5) {
                    block.opacity = 1.0
                } else {
                    block.opacity = 0
                }
                //debugPosText.text = block.row + "," + block.col
                block.updatePositions()
            }
        }
    }
    AppListener {
        filter: ActionTypes.blockSetColumn
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            var i_col = i_data.column
            if (blocks[i_blockId] != null) {
                var block = blocks[i_blockId]

                //console.log("received block event: setColumn", i_blockId, i_col)
                block.col = i_col
                //debugPosText.text = block.row + "," + block.col + "\n" + block.uuid
                //debugPosText.centerIn = block
                block.updatePositions()
            }
        }
    }

    AppListener {
        filter: ActionTypes.blockSetOpacity
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            var i_opacity = i_data.opacity

            if (blocks[i_blockId] != null) {
                var block = blocks[i_blockId]
                var i_row = block.row
                var i_col = block.col
                var i_color = block.color
                if (i_opacity == 0) {
                    block.destroy()
                    createBlock(-30, i_col, i_blockId, i_color)
                } else {

                    // console.log("received block event: setColumn", i_blockId, i_col)
                    block.opacity = i_opacity
                }
            }
            //     updatePositions()
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksEnableMouseArea
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_enabled = i_data.enabled

            if (i_orientation == armyOrientation) {
                for (var i = 0; i < blocks.length; i++) {
                    if (blocks[i] != null) {
                        blocks[i].enableMouseArea()
                    }
                }
            }
        }
    }
    AppListener {
        filter: ActionTypes.blockSetColor
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            if (blocks[i_blockId] != null) {
                var block = blocks[i_blockId]

                block.color = i_data.color
            }
            //     updatePositions()
        }
    }

    AppListener {
        filter: ActionTypes.blockBeginLaunchSequence
        onDispatched: function (actionType, i_data) {

            var i_orientation = i_data.orientation
            var i_uuid = i_data.uuid

            if (i_orientation == armyOrientation) {
                var block = blocks[i_uuid]
                if (block == null) {
                    return
                }

                if (i_uuid == block.uuid) {
                    block.beginLaunchSequence()

                    //                    ActionsController.armyBlocksRequestLaunchTargetDataFromOpponent({
                    //                                                                                        "orientation": block.orientation,
                    //                                                                                        "column": block.col,
                    //                                                                                        "health": block.health,
                    //                                                                                        "attackModifier": block.attackModifier,
                    //                                                                                        "healthModifier": block.healthModifier,
                    //                                                                                        "uuid": block.uuid
                    //                                                                                    })
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

            if (iorientation === armyOrientation) {

                console.log("Movement changed for", iuuid, idirection, irow,
                            icol, iorientation)
                var rx = 0
                var cx = 0
                if (idirection === "right") {
                    cx = 1
                }
                if (idirection === "left") {
                    cx = -1
                }
                if (idirection === "down") {
                    rx = 1
                }
                if (idirection === "up") {
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
                var blk1_uuid = iuuid

                var blk2_uuid = gameEngine.getUuidFromUuidAndDirection(
                            iuuid, idirection)

                if (blk1_uuid === null) {
                    return
                }
                if (blk2_uuid === "") {
                    return
                }

                var swapList = []

                var swappedBlocks = []

                //  gameEngine.swapBlocks(blk1_uuid, blk2_uuid)
                //                ActionsController.blockSetRow({
                //                                                  "orientation": armyBlocks.armyOrientation,
                //                                                  "uuid": blk1_uuid,
                //                                                  "row": irow
                //                                              })
                //                ActionsController.blockSetColumn({
                //                                                     "orientation": armyBlocks.armyOrientation,
                //                                                     "uuid": blk1_uuid,
                //                                                     "column": icol
                //                                                 })
                //                ActionsController.blockSetRow({
                //                                                  "orientation": armyBlocks.armyOrientation,
                //                                                  "uuid": blk2_uuid,
                //                                                  "row": newR
                //                                              })
                //                ActionsController.blockSetColumn({
                //                                                     "orientation": armyBlocks.armyOrientation,
                //                                                     "uuid": blk2_uuid,
                //                                                     "column": newC
                //                                                 })
                ActionsController.signalBlocksSwapped({
                                                          "orientation": armyBlocks.armyOrientation,
                                                          "uuid1": iuuid,
                                                          "uuid2": blk2_uuid
                                                      })
                swappedBlocks.push(blk1_uuid)

                swappedBlocks.push(blk2_uuid)

                if (swappedBlocks.length > 1) {
                    swapList.push(swappedBlocks)
                }

                if ((irow != newR) || (icol != newC)) {

                    enqueueRemote("SWAP", [blk1_uuid, blk2_uuid])

                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveMade
                }
            }
        }
    }

    AppListener {
        filter: ActionTypes.armyBlocksSwapBlocks
        onDispatched: function (actionType, i_data) {

            var t_orientation = i_data.orientation
            if (t_orientation == armyBlocks.armyOrientation) {
                armyGameEngine.swapBlocks(i_data.uuid1, i_data.uuid2)
            }
        }
    }


    /*AppListener {
        filter: ActionTypes.armyBlocksCheckFinishedWithNoMatches
        onDispatched: function (actionType, i_data) {

            var t_orientation = i_data.orientation

            //     console.log("Received armyBlock event for board", t_orientation,
            //                        "calling,", actionType)
            if (t_orientation === armyBlocks.armyOrientation) {

                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreCheckMatches) {
                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreNoMatches
                } else {
                    if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksCheckMatches) {
                        armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksNoMatches
                    }
                }
            }
        }
    }
    AppListener {
        filter: ActionTypes.gameRootRequestQueue
        onDispatched: function (actionType, i_data) {
            var t_orientation = i_data.orientation

            //      console.log("Received armyBlock event for board", t_orientation,
            //                  "calling,", actionType)
            if (t_orientation === armyBlocks.armyOrientation) {
                if (t_orientation === "bottom") {

                }
            }
        }
    }

    AppListener {
        filter: ActionTypes.armyBlocksBeginTurn
        onDispatched: function (actionType, i_data) {
            var t_orientation = i_data.orientation

            if (t_orientation === armyBlocks.armyOrientation) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksTurnStart
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksEndTurn
        onDispatched: function (actionType, i_data) {
            var t_orientation = i_data.orientation
            console.log("Received armyBlock event for board", t_orientation,
                        "calling,", actionType)
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksBatchLaunch
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_uuids = i_data.uuids

            if (i_orientation === armyOrientation) {

                console.log("Launching blocks", i_uuids)
                armyLaunchQueue = armyLaunchQueue.concat(i_uuids)
                localLaunchTimer.interval = 25
                // localEventTimer.running = true
                //  dispatcher.dispatch(actionType, i_data)
                //   enqueueLocal("stepBlockRefill", [])
                //removeBlockFunc()
            }
        }
    } */
    AppListener {

        filter: ActionTypes.armyBlocksEnableMouseArea
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == armyOrientation) {
                for (var uuid in blocks) {
                    var blk = blocks[uuid]
                    if (blk != null) {
                        blk.enableMouseArea(i_data.enabled)
                    }
                }
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksRequestLaunchTargetDataFromOpponent
        onDispatched: function (actionType, i_data) {
            var t_orientation = i_data.orientation

            var t_column = i_data.column
            var t_health = i_data.health
            var t_attackModifier = i_data.attackModifier
            var t_healthModifier = i_data.healthModifier
            var t_uuid = i_data.uuid
            if (t_orientation != armyBlocks.armyOrientation) {
                var rvUuids = armyGameEngine.computeBlocksToDestroy(t_health,
                                                                    t_column)
                var rvPositions = []
                for (var u = 0; u < rvUuids.length; u++) {
                    var blk = blocks[rvUuids[u]]
                    if (blk != null) {

                        var globPos = blk.mapToGlobal(0, 0)
                        rvPositions.push(globPos)
                    }
                }
                ActionsController.armyBlocksProvideLaunchTargetDataToOpponent({
                                                                                  "orientation": t_orientation,
                                                                                  "uuid": t_uuid,
                                                                                  "uuids": rvUuids,
                                                                                  "positions": rvPositions
                                                                              })
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksProvideLaunchTargetDataToOpponent
        onDispatched: function (actionType, i_data) {
            var t_orientation = i_data.orientation
            var t_uuid = i_data.uuid
            var t_damagePoints = i_data.damagePoints
            var t_damageAmounts = i_data.damageAmounts
            var t_health = i_data.health
            var t_column = i_data.column

            if (t_orientation == armyBlocks.armyOrientation) {

                var blks = i_data.uuids
                for (var u = 0; u < blks.length; u++) {
                    var blk = blocks[blks[u]]
                    if (blk != null) {
                        blk.isBeingAttacked = true
                        blk.attackingUuid = t_uuid
                    }
                }
                var max_y
                if (armyOrientation == "top") {
                    max_y = 999999
                } else {
                    max_y = -1
                }
                for (var p = 0; p < i_data.positions.length; p++) {
                    if (armyOrientation == "top") {
                        var cur_y = i_data.positions[p].y
                        if (cur_y < max_y) {
                            max_y = cur_y
                        }
                    } else {
                        var cur_y = i_data.positions[p].y
                        if (cur_y > max_y) {
                            max_y = cur_y
                        }
                    }
                }
                var blk = blocks[t_uuid]
                if (blk != null) {
                    blk.targetY = max_y
                }


                /*ActionsController.blockSetHealthAndPos({
                                                           "orientation": armyBlocks.armyOrientation,
                                                           "uuid": t_uuid,
                                                           "health": 0,
                                                           "pos": 0
                                                       }) */
            }
        }
    }


    /*     AppListener {
        filter: ActionTypes.blockLaunchCompleted
        onDispatched: function (actionType, i_data) {
            var i_uuid = i_data.uuid
            var i_row = i_data.row
            var i_column = i_data.column
            var i_obj = i_data.obj
            var i_orientation = i_data.orientation
            if (i_orientation === armyBlocks.armyOrientation) {
    //            if (typeof i_obj != 'undefined') {
  //                  armyBlocks.armyPostLaunchQueue.push(i_uuid)
  //                  armyActiveLaunchCount--
//                    localLaunchTimer.interval = 100
//                    localLaunchTimer.running = true

                    //  ActionsController.signalLauchComplete(i_data)
                    // stepBlockRefill(function () {})

                    // enqueueLocalToFront(armyBlocks.removeBlockFunc, [])
                }
            }
        }
    } */


    /*AppListener {
        filter: ActionTypes.armyBlocksRequestQueue
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            if (i_orientation === armyBlocks.armyOrientation) {
                armyBlocks.irc.sendMessageToCurrentChannel(
                            irc.gameCommandMessage("REQUEST_QUEUE", "null"))
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksWaitForQueue
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksProcessSync
        onDispatched: function (actionType, i_data) {

            var i_orientation = i_data.orientation
            var i_indices = i_data.armyIndices

            var i_blocks = JS.decompressArray(i_data.armyBlocks)
            if (i_orientation === armyBlocks.armyOrientation) {
                for (var u = 0; u < i_blocks.length; u++) {
                    var block_data = i_blocks[u]

                    var dispatchData = {
                        "row": block_data.row,
                        "column": block_data.col,
                        "data": block_data,
                        "orientation": armyBlocks.armyOrientation
                    }
                    var blks = JS.getBlocksByRowAndCol(armyBlocks,
                                                       armyBlockStacks,
                                                       block_data.row,
                                                       block_data.col)
                    if (blks.length > 0) {
                        ActionsController.blockDeserialize(dispatchData)
                    } else {
                        createBlock(block_data.row, block_data.col)
                        ActionsController.blockDeserialize(dispatchData)
                    }
                }

                armyBlocks.armyIndex0 = i_indices[0]
                armyBlocks.armyIndex1 = i_indices[1]
                armyBlocks.armyIndex2 = i_indices[2]
                armyBlocks.armyIndex3 = i_indices[3]
                armyBlocks.armyIndex4 = i_indices[4]
                armyBlocks.armyIndex5 = i_indices[5]
            }

            ActionsController.armyBlocksPostSyncFixUp({
                                                          "orientation": "top"
                                                      })
            // armyBlocks.armyNextAction = armyBlocks.armyPostSyncState
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksPostSyncFixUp
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation === armyBlocks.armyOrientation) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveStart
            }
        }
    }
    AppListener {

        filter: ActionTypes.armyBlocksEnqueueConditional
        onDispatched: function (actionType, i_data) {
            var t_command = i_data.command
            var t_data = i_data.data
            var t_action = i_data.action
            var t_orientation = i_data.orientation
            if (t_orientation === armyBlocks.armyOrientation) {
                if (t_command === "SWAP") {
                    var t_eventObj = {
                        "action": ActionTypes.stateArmyBlocksMoveStart,
                        "command": t_command,
                        "data": t_data
                    }
                    armyBlocks.armyConditionalQueue.push(t_eventObj)
                }
                if (t_command === "SYNC") {
                    var t_eventObj = {
                        "action": ActionTypes.stateArmyBlocksMoveStart,
                        "command": t_command,
                        "data": t_data
                    }
                    armyBlocks.armyConditionalQueue.push(t_eventObj)
                }
            }
        }
    }
    AppListener {
        filter: ActionTypes.crossArmySignalTurnEnded
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            if (i_orientation === armyBlocks.armyOrientation) {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksArmyReadyDefense
            } else {
                armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksArmyReadyOffense
            }
        }
    }
    */
    //    AppListener {
    //        filter: ActionTypes.armyBlocksDetermineNextAction
    //        onDispatched: function (actionType, i_data) {
    //            var i_orientation = i_data.orientation
    //            if (i_orientation === armyBlocks.armyOrientation) {
    //                if (armyBlocks.armyLastAction === armyBlocks.armyNextAction) {
    //                    return
    //                } else {
    //                    armyBlocks.armyLastAction = armyBlocks.armyNextAction
    //                }
    //                console.log("+-----", armyBlocks.armyOrientation,
    //                            " DETERMINATOR RAN WITH STATE", armyNextAction)

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksArmyReadyOffense) {

    //                    ActionsController.armyBlocksSetLocked({
    //                                                              "orientation": armyOrientation,
    //                                                              "locked": false
    //                                                          })
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksTurnStart
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksArmyReadyDefense) {

    //                    ActionsController.armyBlocksSetLocked({
    //                                                              "orientation": armyOrientation,
    //                                                              "locked": true
    //                                                          })
    //                    ActionsController.({
    //                                                                    "orientation": armyOrientation,
    //                                                                    "enabled": false
    //                                                                })
    //                    //armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksTurnComplete
    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksTurnStart) {

    //                    //                    ActionsController.armyBlocksBeginTurn({
    //                    //                                                              "orientation": armyBlocks.armyOrientation
    //                    //                                                          })
    //                    armyBlocks.armyMovesMade = 0
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreCheckMatches
    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksMoveStart) {
    //                    ActionsController.armyBlocksEnableMouseArea({
    //                                                                    "orientation": armyOrientation,
    //                                                                    "enabled": true
    //                                                                })

    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreCheckMatches) {

    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreWaitForMatcher
    //                    //gameEngine.checkMatches()
    //                    //  armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreCompactBlocks
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreNoMatches) {

    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveStart
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreLaunchMatches) {
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreWaitForLaunch

    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksLaunchMatches) {
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksWaitForLaunch

    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreWaitForMatcher) {
    //                    armyBlocks.armyLastAction = null

    //                    //    armyBlocks.checkMatches()
    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksWaitForMatcher) {
    //                    armyBlocks.armyLastAction = null

    //                    // armyBlocks.checkMatches()
    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyPreWaitForLaunch) {
    //                    armyBlocks.armyLastAction = null
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksWaitForLaunch) {
    //                    armyBlocks.armyLastAction = null
    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreNoMatches) {
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveStart
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksNoMatches) {
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveComplete
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreCompactBlocks) {
    //                    armyBlocks.compactBlocks()
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreCreateBlocks
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksCompactBlocks) {
    //                    //armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksCreateBlocks
    //                    armyBlocks.compactBlocks()
    //                    return
    //                }

    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksPreCreateBlocks) {
    //                    for (var c = 0; c < 6; c++) {
    //                        for (var r = 0; r < 6; r++) {
    //                            var stack = armyBlockStacks[c]
    //                            if (stack.length < 6) {
    //                                var queue = armyBlockQueues[c]

    //                                if ((queue.length + stack.length) < 6) {
    //                                    console.log("queue error -- nothing queued and stack is missing blocks")
    //                                } else {

    //                                    // stack is full.
    //                                }
    //                            }
    //                        }
    //                    }
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksPreCheckMatches
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksCreateBlocks) {
    //                    for (var c = 0; c < 6; c++) {
    //                        for (var r = 0; r < 6; r++) {
    //                            var stack = armyBlockStacks[c]
    //                            if (stack.length < 6) {
    //                                var queue = armyBlockQueues[c]

    //                                if ((queue.length + stack.length) < 6) {
    //                                    console.log("queue error -- nothing queued and stack is missing blocks")
    //                                    //  createBlock(5 - r, c)
    //                                } else {

    //                                    // stack is full.
    //                                }
    //                            }
    //                        }
    //                    }
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksCheckMatches
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksMoveMade) {
    //                    ActionsController.armyBlocksEnableMouseArea({
    //                                                                    "orientation": armyOrientation,
    //                                                                    "enabled": false
    //                                                                })

    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksCheckMatches
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksCheckMatches) {
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksWaitForMatcher
    //                    gameEngine.checkMatches()
    //                    //armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksCompactBlocks
    //                    return
    //                }
    //                if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksMoveStart) {

    //                    if (armyBlocks.armyOrientation === "bottom") {

    //                        //arnyRemoteQueue = []
    //                    } else {

    //                    }

    //                    ActionsController.armyBlocksEnableMouseArea({
    //                                                                    "orientation": armyOrientation,
    //                                                                    "enabled": true
    //                                                                })
    //                }
    //                return
    //            }
    //            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksMoveComplete) {
    //                armyBlocks.armyMovesMade += 1

    //                if (armyBlocks.armyMovesMade >= 3) {
    //                    armyBlocks.armyPostSyncState = ActionTypes.stateArmyBlocksTurnComplete
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksTurnComplete
    //                } else {
    //                    armyBlocks.armyPostSyncState = ActionTypes.stateArmyBlocksMoveStart
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveStart
    //                }

    //                return
    //            }
    //            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksWaitForSync) {
    //                if (armyBlocks.armyOrientation === "bottom") {
    //                    enqueueRemote(
    //                                "SYNC",
    //                                [[armyBlocks.armyIndex0, armyBlocks.armyIndex1, armyBlocks.armyIndex2, armyBlocks.armyIndex3, armyBlocks.armyIndex4, armyBlocks.armyIndex5], JS.compressArray(
    //                                     blocks.map(function (item) {
    //                                         return item.serialize()
    //                                     }))])

    //                    armyBlocks.armyNextAction = armyBlocks.armyPostSyncState
    //                } else {
    //                    armyBlocks.armyNextAction = ActionTypes.stateArmyBlocksMoveStart
    //                    // armyBlocks.armyNextAction = armyBlocks.armyPostSyncState
    //                }
    //                return
    //            }
    //            if (armyBlocks.armyNextAction === ActionTypes.stateArmyBlocksTurnComplete) {
    //                ActionsController.crossArmySignalTurnEnded({
    //                                                               "orientation": armyOrientation
    //                                                           })
    //            }
    //        }
    //    }
    //    AppListener {
    //        filter: ActionTypes.armyBlocksProvideLaunchTargetDataToOpponent

    //        onDispatched: function (actionType, i_data) {
    //            if (i_data.orientation != armyBlocks.armyOrientation) {

    //                var uuids = i_data.uuids
    //                for (var i = 0; i < uuids.length; i++) {
    //                    var block = blocks[uuids[i]]
    //                    if (block != null) {
    //                        block.attackingUuid = i_data.uuid
    //                        block.isBeingAttacked = true
    //                    }
    //                }
    //            }
    //        }
    //    }
    AppListener {
        filter: ActionTypes.blockSetHealthAndPos
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_uuid = i_data.uuid

            if (i_orientation == armyOrientation) {
                var block = blocks[i_uuid]
                if (block != null) {
                    block.setHealthAndPos(i_data)
                }
            }
            //   updatePositions()
        }
    }
    AppListener {
        filter: ActionTypes.blockFireAtTarget
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == armyOrientation) {
                var block = blocks[i_data.uuid]
                if (block != null) {
                    block.fireAtTarget(i_data)
                }
            }
        }
    }

    //    AppListener {
    //        filter: ActionTypes.blockDeserialize
    //        onDispatched: function (actionType, i_data) {
    //            var i_orientation = i_data.orientation
    //            var i_row = i_data.row
    //            var i_column = i_data.column
    //            var i_serial_data = i_data.data
    //            if (i_orientation == block.orientation) {

    //                if (i_row == block.row) {
    //                    if (i_column == block.col) {
    //                        block.deserialize(i_serial_data)
    //                        updatePositions()
    //                    }
    //                }
    //            }
    //        }
    //    }
}
