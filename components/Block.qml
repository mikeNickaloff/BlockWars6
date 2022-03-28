import QtQuick 2.15
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
    property var canDrag: true
    property var dragStartX: 0
    property var dragStartY: 0
    property var itemStartX: 0
    property var itemStartY: 0

    property string movementDirection
    property var selectedBlock

    signal blockSelected(var row, var col)
    signal movementChanged(var iuuid, var idirection, var irow, var icol)
    signal goingToMove(var row, var col, var i_direction, int dx, int dy)
    property var uuid: 00
    onRowChanged: {
        //  console.log("row changed from", oldRow, "to", row)
        oldRow = row
        //  block.gridPositionChanged(block, row, col)
    }

    // onColChanged: {
    //     block.gridPositionChanged(block, row, col)
    // }
    Behavior on y {

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
    Rectangle {
        color: block.color
        border.color: "black"
        anchors.fill: parent
    }
    Component.onCompleted: {

    }

    MouseArea {
        anchors.fill: parent

        enabled: itemRoot.canDrag
        hoverEnabled: false
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: {

            // console.log("Mouse pressed on " + row_index + " / " + cell_index);
            if (pressedButtons & Qt.RightButton) {
                block.removed(row, col)
            } else {
                mainItem.dragStartX = mouseX
                mainItem.dragStartY = mouseY
                mainItem.itemStartX = mainItem.x
                mainItem.itemStartY = mainItem.y
                //                xMovementInterpolator.enabled = true
                //                yMovementInterpolator.enabled = true
                mainItem.blockSelected(row, col)
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
                if (dx > (animRoot.width / 3)) {

                    movementDirection = "right"
                    edx = Math.min(animRoot.width, dx)
                }
                if (dx < (-1 * (animRoot.width / 3))) {

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
                    if (dy > animRoot.height / 3) {
                        movementDirection = "down"
                        edy = Math.min(animRoot.height, dy)
                    }
                    if (dy < -1 * animRoot.height / 3) {
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
            mainItem.movementChanged(uuid, movementDirection, row, col)

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
}
