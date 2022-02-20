import QtQuick 2.0
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
    transform: [
        Rotation {
            origin.x: {
                return armyBlocks.Center
            }
            origin.y: {
                return armyBlocks.Center
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
        for (var a = 0; a < 6; a++) {
            for (var b = 0; b < 6; b++) {
                createBlock(a, b)
            }
        }
        console.log(JS.matchObjectsByProperties(blocks,
                                                [JS.makePropertyObject("row",
                                                                       3)]))
        JS.createOneShotTimer(armyBlocks, 5000, function () {

            /*  var newBlocks = JS.filterObjectsByProperties(
                        blocks,
                        [JS.makePropertyObject("row",
                                               3), JS.makePropertyObject("col",
                                                                         3)])
          */


            /*  for (var i = 0; i < blocks.length; i++) {
                if (i % 5 == 0) {
                    blocks[i].visible = false
                    blocks[i].destroy()
                    blocks.slice(i, 1)
                }
            }
*/
        })
        JS.createOneShotTimer(armyBlocks, 600, function () {
            //   blocks = newBlocks
            var newBlocks = blocks
            console.log(newBlocks.length)
            stepBlockRefill(function () {
                console.log("refill completed")
            })
        })
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
          //  console.log("some blocks are still moving")
            JS.createOneShotTimer(armyBlocks, 80, function () {
                stepBlockRefill()
            })
        } else {
            if (blocks.length >= 36) {
                JS.compactBlocks(blocks, armyOrientation)
                removeBlocks(function () {
                    JS.createOneShotTimer(armyBlocks, 100, stepBlockRefill)
                }, function () {
                    var lingering = JS.matchObjectsByProperties(
                                blocks, [JS.makePropertyObject("row", -1)])
                    if (lingering.length > 0) {
                        for (var u = 0; u < lingering; u++) {
                            lingering[u].row++
                        }
                        JS.createOneShotTimer(armyBlocks, 100, stepBlockRefill)
                    } else {

                        // console.log("Refill 100% Complete")
                        if (callback != null) {
                            callback()
                        }
                    }
                })
            } else {
                refillBlocks(function () {
                    createBlocks(function () {
                        JS.createOneShotTimer(armyBlocks, 100, stepBlockRefill)
                    }, function () {
                        removeBlocks(function () {
                            JS.createOneShotTimer(armyBlocks, 100,
                                                  stepBlockRefill)
                        }, function () {
                  //          console.log("No blocks Removed")
                            if (blocks.length != 36) {
                                JS.createOneShotTimer(armyBlocks, 100,
                                                      stepBlockRefill)
                            }
                        })
                    })
                }, function () {

                    createBlocks(function () {
                        JS.createOneShotTimer(armyBlocks, 100, stepBlockRefill)
                    }, function () {// console.log("Refill Complete")
                    })
                })
            }
        }
    }
    function createBlock(row, col) {
        var blk = blockComponent.createObject(armyBlocks, {
                                                  "row": row,
                                                  "col": col,
                                                  "color": JS.getRandomColor()
                                              })
        armyBlocks.blocks.push(blk)
        blk.removed.connect(function (irow, icol) {
            var blk2 = JS.getBlocksByRowAndCol(blocks, irow, icol)[0]
            blk2.visible = false
            blocks = JS.removeBlocksByRowAndCol(blocks, irow, icol)

            JS.createOneShotTimer(armyBlocks, 100, stepBlockRefill)


            /*   JS.createOneShotTimer(armyBlocks, 800, function () {
                createBlock(-1, icol)
            }) */
        })
    }

    function refillBlocks(callbackTrue, callbackFalse) {
        var _dropped = false
        var res = JS.compactBlocks(blocks, armyOrientation)
        var didDrop = res[1]
        blocks = res[0]
        while (didDrop) {
            res = JS.compactBlocks(blocks, armyOrientation)
            blocks = res[0]
            didDrop = res[1]
            _dropped = true
        }
        if (_dropped) {
            callbackTrue()
        } else {
            callbackFalse()
        }
    }
    function removeBlocks(callbackMatched, callbackNotMatched) {

        JS.createOneShotTimer(armyBlocks, 800, function () {
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
        })
    }
    function createBlocks(callbackTrue, callbackFalse) {
        var createdBlocks = false
        for (var i = 0; i < 6; i++) {
            if (JS.getColOfBlocks(blocks, i).length < 6) {
                createBlock(-1, i)
                createdBlocks = true
            }
        }
        if (createdBlocks) {
            callbackTrue()
        } else {
            callbackFalse()
        }
    }
}
