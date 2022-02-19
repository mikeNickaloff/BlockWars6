import QtQuick 2.0

Item {
    id: block
    property var row: 8
    signal removed(var irow, var icol)
    onRowChanged: {
        console.log("row changed from", oldRow, "to", row)
        oldRow = row
    }
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
    property var oldRow: -1
    property var col: 0
    property var color: "white"
    property var isMoving: false
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
        onClicked: {
            block.removed(row, col)
        }
    }
}
