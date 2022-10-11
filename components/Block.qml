import QtQuick 2.15
import QuickFlux 1.1
import "../flux"
import "../scripts/main.js" as JS

Item {
    id: block
    property var row: 8
    signal removed(var irow, var icol)
    signal mousePressed(var row, var col)
    signal gridPositionChanged(var sender, var irow, var icol)
    property var oldRow: -1
    property var col: 0
    property var color: "white"
    property var isMoving: false
    property alias mainItem: block
    property alias itemRoot: block
    property alias animRoot: block
    property var health: 5
    property var healModifier: 1.0
    property var attackModifier: 1.0
    property var canDrag: true
    property var dragStartX: 0
    property var dragStartY: 0
    property var itemStartX: 0
    property var itemStartY: 0
    property var orientation: "none"
    property string movementDirection
    property var selectedBlock
    property bool locked: false
    property bool shouldDeleteNow: false

    property var yInterpolateDelta: 150

    property var postLaunchY: 0
    signal blockSelected(var row, var col)
    signal movementChanged(var iuuid, var idirection, var irow, var icol)
    signal goingToMove(var row, var col, var i_direction, int dx, int dy)
    property var oldy: 0
    property var uuid: 00

    //    Behavior on health {
    //        SequentialAnimation {

    //            PauseAnimation {
    //                duration: 1000
    //            }
    //            ScriptAction {
    //                script: {
    //                    if (block.health <= 0) {
    //                        block.visible = false
    //                    }
    //                }
    //            }
    //            NumberAnimation {
    //                duration: 900
    //            }
    //            ScriptAction {
    //                script: {
    //                    if (block.health <= 0) {
    //                        block.removed(block.row, block.col)
    //                    }
    //                }
    //            }
    //        }
    //    }
    onLockedChanged: {
        updatePositions()
    }
    onRowChanged: {
        //  console.log("row changed from", oldRow, "to", row)
        oldRow = row
        //  updatePositions()
        //  block.gridPositionChanged(block, row, col)
    }

    onColChanged: {
        updatePositions()
        //     block.gridPositionChanged(block, row, col)
    }
    Behavior on y {

        SequentialAnimation {
            ScriptAction {
                script: {
                    block.isMoving = true
                    block.z = 999
                }
            }

            NumberAnimation {

                duration: yInterpolateDelta
            }
            ScriptAction {
                script: {
                    block.isMoving = false
                    block.z = 10
                }
            }
        }
    }
    Behavior on x {

        SequentialAnimation {
            ScriptAction {
                script: {
                    block.isMoving = true
                }
            }
            NumberAnimation {
                duration: 100
            }
            ScriptAction {
                script: {
                    block.isMoving = false
                }
            }
        }
    }
    width: {
        return (parent.width * 0.95) / 6
    }
    height: {
        return (parent.height * 0.95) / 6
    }
    x: col * (parent.width / 6)
    y: row * (parent.height / 6)
    function updatePositions() {
        block.x = col * (parent.width / 6)
        var newY = row * (parent.height / 6)
        if (newY < block.y) {
            yInterpolateDelta = 0
        } else {
            yInterpolateDelta = 250
        }
        block.y = row * (parent.height / 6)
    }

    Component.onCompleted: {

    }

    Component {
        id: blockIdleComponent
        Rectangle {
            color: "black"
            border.color: "black"
            anchors.fill: parent

            Image {
                source: "qrc:///images/block_" + block.color + ".png"
                height: {
                    return block.height * 0.90
                }
                width: {
                    return block.width * 0.90
                }

                id: blockImage
                asynchronous: true

                sourceSize.height: blockImage.height
                sourceSize.width: blockImage.width
                anchors.centerIn: parent
                visible: true
            }
            Text {
                id: debugPosText
                text: block.uuid
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 23
                anchors.centerIn: parent
                anchors.fill: parent

                //                transform: [
                //                    Rotation {
                //                        origin.x: {
                //                            return block.Center ? block.Center : 0
                //                        }
                //                        origin.y: {
                //                            return block.Center ? block.Center : 0
                //                        }
                //                        axis {
                //                            x: 1
                //                            y: 0
                //                            z: 0
                //                        }
                //                        angle: {
                //                            return orientation == "bottom" ? 180 : 0
                //                        }
                //                    }
                //                ]
            }
        }
    }
    Component {
        id: blockLaunchComponent

        AnimatedSprite {

            id: sprite
            anchors.centerIn: parent
            height: {
                return block.height * 0.90
            }
            width: {
                return block.width * 0.90
            }
            z: 9999
            source: "qrc:///images/block_" + block.color + "_ss.png"
            frameCount: 5
            currentFrame: 0
            reverse: false
            frameSync: false
            frameWidth: 64
            frameHeight: 64
            loops: 1
            running: true
            frameDuration: 190
            interpolate: true

            smooth: false
            property var colorName: block.color

            onColorNameChanged: {
                sprite.source = "qrc:///images/block_" + colorName + "_ss.png"
            }
            onCurrentFrameChanged: function () {
                if (currentFrame == 3) {
                    ActionsController.armyBlocksRequestLaunchTargetDataFromOpponent({
                                                                                        "orientation": block.orientation,
                                                                                        "column": block.col,
                                                                                        "health": block.health,
                                                                                        "attackModifier": block.attackModifier,
                                                                                        "healthModifier": block.healthModifier,
                                                                                        "uuid": block.uuid
                                                                                    })
                }
            }
            onFinished: {

                loader.sourceComponent = blockExplodeComponent
            }
        }
    }
    Component {
        id: blockExplodeComponent

        AnimatedSprite {
            id: sprite
            width: block.width * 2.5
            height: block.height * 2.5

            anchors.centerIn: parent
            z: 7000

            source: "qrc:///images/explosion_hi_ss.png"
            frameCount: 25
            frameWidth: 64
            frameHeight: 64


            /* source: "qrc:///images/explode_ss.png"
            frameCount: 20
            frameWidth: 64
            frameHeight: 64 */
            reverse: false
            frameSync: true

            loops: 1
            running: true
            frameDuration: 50
            interpolate: true

            smooth: false

            onFinished: {
                //console.log("Block destroyed", block.uuid)
                block.isMoving = false
                ActionsController.blockLaunchCompleted({
                                                           "uuid": block.uuid,
                                                           "row": block.row,
                                                           "column": block.col,
                                                           "obj": block,
                                                           "orientation": block.orientation
                                                       })

                block.row = -4
                // block.opacity = 0
                loader.sourceComponent = blockIdleComponent

                //block.color = armyBlocks.getNextColor(block.col)
                updatePositions()
                // updatePositions()
                //block.removed(block.row, block.col)
            }
        }
    }
    MouseArea {
        anchors.fill: parent

        enabled: true
        hoverEnabled: false
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        id: blockMouseArea
        onPressed: {

            if (!locked) {

                // console.log("Mouse pressed on " + row_index + " / " + cell_index);
                if (pressedButtons & Qt.RightButton) {

                    //    block.removed(row, col)
                } else {
                    mainItem.dragStartX = mouseX
                    mainItem.dragStartY = mouseY
                    mainItem.itemStartX = mainItem.x
                    mainItem.itemStartY = mainItem.y
                    //                xMovementInterpolator.enabled = true
                    //                yMovementInterpolator.enabled = true
                    mainItem.blockSelected(row, col)
                }
            } else {
                updatePositions()
                // block.x = col * (parent.width / 6)
                //  block.y = row * (parent.height / 6)
            }
        }
        onEntered: {

        }
        onPositionChanged: {

            //if (gameBlock.canMove()) {
            var dx = mainItem.dragStartX - mouseX
            var dy = mainItem.dragStartY - mouseY
            var edx = 0
            var edy = 0
            if (Math.abs(dx) > Math.abs(dy)) {

                //mainItem.y = itemStartY;
                if (dx > (animRoot.width / 2)) {

                    movementDirection = "right"
                    edx = Math.min(animRoot.width, dx)
                }
                if (dx < (-1 * (animRoot.width / 2))) {

                    movementDirection = "left"
                    edx = Math.max(-1 * animRoot.width, dx)
                }
                if (Math.abs(edx) > 0) {
                    mainItem.x = mainItem.itemStartX - edx
                    mainItem.goingToMove(row, col, movementDirection, edx, 0)
                }
            } else {

                if (Math.abs(dx) < Math.abs(dy)) {

                    // mainItem.x = itemStartX;
                    if (dy > animRoot.height / 2) {
                        movementDirection = "down"
                        edy = Math.min(animRoot.height, dy)
                    }
                    if (dy < -1 * animRoot.height / 2) {
                        movementDirection = "up"
                        edy = Math.max(-1 * animRoot.height, dy)
                    }
                    if (Math.abs(edy) > 0) {
                        mainItem.y = itemStartY - edy
                        mainItem.goingToMove(row, col,
                                             movementDirection, 0, edy)
                    }
                }
            }
        }

        //}
        onReleased: {

            //if (gameBlock.canMove()) {
            // mainItem.x = mainItem.itemStartX
            // mainItem.y = mainItem.itemStartY
            if (!locked) {
                ActionsController.armyBlocksRequestMovement({
                                                                "uuid": uuid,
                                                                "direction": movementDirection,
                                                                "row": row,
                                                                "column": col,
                                                                "orientation": orientation
                                                            })
            } else {

                //  block.x = col * (parent.width / 6)
                //    block.y = row * (parent.height / 6)
            }

            //}
        }
    }
    function serialize() {
        return {
            "row": row,
            "col": col,
            "color": color,
            "uuid": uuid
        }
    }
    function deserialize(i_data) {
        block.row = i_data.row
        block.col = i_data.col
        block.color = i_data.color
        block.uuid = i_data.uuid
    }
    AppListener {
        filter: ActionTypes.blockSetRow
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            var i_row = i_data.row
            if (i_blockId == block.uuid) {
                //console.log("received block event: setRow", i_blockId, i_row)
                block.row = i_row
                if (i_row <= 5) {
                    block.opacity = 1.0
                } else {
                    block.opacity = 0
                }
                //debugPosText.text = block.row + "," + block.col
                updatePositions()
            }
        }
    }
    AppListener {
        filter: ActionTypes.blockSetColumn
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            var i_col = i_data.column

            if (i_blockId == block.uuid) {
                //console.log("received block event: setColumn", i_blockId, i_col)
                block.col = i_col
                //debugPosText.text = block.row + "," + block.col + "\n" + block.uuid
                //debugPosText.centerIn = block
                updatePositions()
            }
        }
    }

    AppListener {
        filter: ActionTypes.blockSetOpacity
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            var i_opacity = i_data.opacity
            if (i_blockId == block.uuid) {
                // console.log("received block event: setColumn", i_blockId, i_col)
                block.opacity = i_opacity
            }
            //     updatePositions()
        }
    }
    AppListener {
        filter: ActionTypes.blockSetColor
        onDispatched: function (actionType, i_data) {
            var i_blockId = i_data.uuid
            if (i_blockId == block.uuid) {

                block.color = i_data.color
            }
            //     updatePositions()
        }
    }

    AppListener {
        filter: ActionTypes.armyBlocksSetLocked
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_locked = i_data.locked

            if (i_orientation == armyOrientation) {

                locked = i_locked
            }
        }
    }

    AppListener {
        filter: ActionTypes.blockFireAtTarget
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == orientation) {
                if (i_data.uuid == block.uuid) {
                    var i_health = i_data.health
                    var i_pos = block.mapFromGlobal(Qt.point(block.x,
                                                             i_data.pos)).y

                    //                  console.log("Firing block at ", i_pos)
                    block.row = 12
                    loader.sourceComponent = blockExplodeComponent
                    updatePositions()
                }
            }
        }
    }

    AppListener {
        filter: ActionTypes.armyBlocksEnableMouseArea
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_enabled = i_data.enabled

            if (i_orientation == armyOrientation) {

                blockMouseArea.enabled = i_enabled
            }
        }
    }

    AppListener {
        filter: ActionTypes.blockBeginLaunchSequence
        onDispatched: function (actionType, i_data) {

            var i_orientation = i_data.orientation
            var i_uuid = i_data.uuid

            if (i_orientation == block.orientation) {

                if (i_uuid == block.uuid) {
                    block.isMoving = true
                    block.z = 10000
                    loader.sourceComponent = blockLaunchComponent

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
        filter: ActionTypes.blockSetHealthAndPos
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_uuid = i_data.uuid

            if (i_orientation == armyOrientation) {

                if (i_uuid == block.uuid) {
                    var i_health = i_data.health
                    var i_pos = mapFromGlobal(Qt.point(block.x, i_data.pos)).y
                    //block.postLaunchY = block.height * 12
                    block.health = 0
                    block.row = 12
                    updatePositions()
                }
            }
            //   updatePositions()
        }
    }

    AppListener {
        filter: ActionTypes.signalFromGameEngineSetBlockPosition
        onDispatched: function (actionType, i_data) {
            var i_row = i_data.row
            var i_column = i_data.column
            var i_uuid = i_data.uuid
            var didChange = false
            if (i_uuid == block.uuid) {
                if (block.row != i_row) {
                    block.row = i_row
                    if (i_row <= 5) {
                        block.opacity = 1.0
                    } else {
                        block.opacity = 0
                    }
                    didChange = true
                }
                if (block.col != i_column) {
                    block.col = i_column
                    didChange = true
                }
            }
            if (didChange) {
                updatePositions()
            }
        }
    }
    AppListener {
        filter: ActionTypes.blockDeserialize
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_row = i_data.row
            var i_column = i_data.column
            var i_serial_data = i_data.data
            if (i_orientation == block.orientation) {
                if (i_row == block.row) {
                    if (i_column == block.col) {
                        block.deserialize(i_serial_data)
                        updatePositions()
                    }
                }
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksFixBlocks
        onDispatched: {

            updatePositions()
        }
    }


    /*   AppListener {
        filter: ActionTypes.queryNearbyBlockColors
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_query_row = i_data.queryRow
            var i_query_col = i_data.queryColumn
            var i_query_uuid = i_data.queryUuid
            if (i_orientation == orientation) {
                var shouldRespondAsNearby = false
                var matchingPositioner
                var shouldRespondAsSelf = false
                if (i_query_col == block.col) {
                    if (i_query_row == (block.row - 1)) {
                        shouldRespondAsNearby = true
                        matchingPositioner = "column"
                    }
                    if (i_query_row == (block.row + 1)) {
                        shouldRespondAsNearby = true
                        matchingPositioner = "column"
                    }
                }

                if (i_query_row == block.row) {
                    if (i_query_col == (block.col - 1)) {
                        shouldRespondAsNearby = true
                        matchingPositioner = "row"
                    }
                    if (i_query_col == (block.col + 1)) {
                        shouldRespondAsNearby = true
                        matchingPositioner = "row"
                    }
                }
                if ((i_query_row == block.row) && (i_query_col == block.col)) {
                    shouldRespondAsSelf = true
                }

                if (shouldRespondAsNearby) {
                    ActionsController.provideNearbyBlockColors({
                                                                   "orientation": i_orientation,
                                                                   "queryRow": i_query_row,
                                                                   "queryColumn": i_query_col,
                                                                   "queryUuid": i_query_uuid,
                                                                   "responseRow": block.row,
                                                                   "responseColumn": block.col,
                                                                   "responseColor": block.color,
                                                                   "responseUuid": block.uuid,
                                                                   "matchingPositioner": matchingPositioner
                                                               })
                }
                if (shouldRespondAsSelf) {
                    ActionsController.provideSelfBlockColors({
                                                                 "orientation": i_orientation,
                                                                 "queryRow": i_query_row,
                                                                 "queryColumn": i_query_col,
                                                                 "queryUuid": i_query_uuid,
                                                                 "responseRow": block.row,
                                                                 "responseColumn": block.col,
                                                                 "responseColor": block.color,
                                                                 "responseUuid": block.uuid
                                                             })
                }
            }
        }
    }
*/


    /*  AppListener {
        filter: ActionTypes.armyBlocksDetermineNextAction
        onDispatched: function (actionType, i_data) {//    block.updatePositions()
        }
    }

    */
    Item {
        width: block.width
        height: block.height
        Loader {
            id: loader
            width: block.width
            height: block.height
            sourceComponent: blockIdleComponent

            onLoaded: {

            }
        }
    }
}
