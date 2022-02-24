/* add the given component to the given stack view */
function pushComponentToStack(item, stack) {
    stack.push(item)
}


/* queue of animations to run.   When the timeout value becomes less or equal to 0, the callback is run using <elem>
   as the parameter
  [{ element: <elem>, timeout: <#>, callback: <function(elem){}> }, ...]
*/
var animationQueue = []

/* create an object for the animation queue */
function makeAnimationObject(element, timeout, callback) {
    var obj = {}
    obj.element = element
    obj.timeout = timeout
    obj.callback = callback
    return obj
}

/* add an object to the animation queue */
function appendAnimationObject(element, timeout, callback) {
    animationQueue.push(makeAnimationObject(element, timeout, callback))
    createOneShotTimer(element, timeout, callback)
}

/* create a one shot timer */
function createOneShotTimer(element, duration, action) {
    var comp = Qt.createComponent('qrc:///components/SingleShotTimer.qml')
    comp.createObject(element, {
                          "action": action,
                          "interval": duration
                      })
}


/* match objects in array based on properties
   array is an array of objects
   properties is an array of objects in the form of: {property: someproperty, value: somevalue}
   [{property: someproperty, value: somevalue}, {property: someproperty, value: somevalue},...]

    *  property objects can be made with makePropertyObject(someproperty, somevalue)
*/
function matchObjectsByProperties(array, properties) {
    return array.filter(function (obj) {
        for (var i = 0; i < properties.length; i++) {
            var propObj = properties[i]
            var propName = propObj.property
            var propValue = propObj.value
            if (obj[propName] != propValue) {
                return false
            }
        }
        return true
    })
}

function filterObjectsByProperties(array, properties) {
    return array.filter(function (obj) {
        var maybeFilter = false
        for (var i = 0; i < properties.length; i++) {
            var propObj = properties[i]
            var propName = propObj.property
            var propValue = propObj.value
            if (obj[propName] != propValue) {
                maybeFilter = true
            }
        }
        return maybeFilter
    })
}

function makePropertyObject(prop, value) {
    return {
        "property": prop,
        "value": value
    }
}

// orientation is "bottom" or "top"
// returns true if blocks dropped
function compactBlocks(i_blocks, i_orientation) {
    var newBlocks = i_blocks
    var rv = false
    for (var i = 0; i < 6; i++) {
        var column = getColOfBlocks(i_blocks, i)
        var dropList = []
        if (column.length < 6) {
            // console.log("column", i, column, "needs to drop")
            for (var u = 5; u > 0; u--) {
                var blks = getBlocksByRowAndCol(i_blocks, u, i)
                if (blks.length == 0) {

                    var pblks = getBlocksByRowAndCol(i_blocks, u - 1, i)
                    if (pblks.length > 0) {
                        newBlocks[newBlocks.indexOf(pblks[0])].row++
                        rv = true
                    }
                }
            }
            var topBlock = getBlocksByRowAndCol(i_blocks, 0, i)
            if (topBlock.length == 0) {
                var chamberBlock = getBlocksByRowAndCol(i_blocks, -1, i)
                if (chamberBlock.length > 0) {
                    newBlocks[newBlocks.indexOf(chamberBlock[0])].row++
                    rv = true
                }
            }
        }
    }
    return [newBlocks, rv]
}

function getRowOfBlocks(i_blocks, row_num) {
    return matchObjectsByProperties(i_blocks, [makePropertyObject("row",
                                                                  row_num)])
}
function getColOfBlocks(i_blocks, col_num) {
    return filterObjectsByProperties(
                matchObjectsByProperties(i_blocks,
                                         [makePropertyObject("col", col_num)]),
                [makePropertyObject("row", -1)])
}

function getBlocksByRowAndCol(i_blocks, row_num, col_num) {
    return matchObjectsByProperties(i_blocks,
                                    [makePropertyObject(
                                         "row",
                                         row_num), makePropertyObject("col",
                                                                      col_num)])
}

function removeBlocksByRowAndCol(i_blocks, row_num, col_num) {
    var blks = getBlocksByRowAndCol(i_blocks, row_num, col_num)
    var blk = blks[0]

    var newBlocks = filterObjectsByProperties(
                i_blocks,
                [makePropertyObject("row",
                                    row_num), makePropertyObject("col",
                                                                 col_num)])

    return newBlocks
}

// find which blocks are adjacent to a given block
function getAdjacentBlocksToBlock(i_blocks, i_block, check_row, check_col) {
    var rv = []
    var row = i_block.row
    var col = i_block.col
    var color = i_block.color
    if (check_row) {
        if (row > 0) {

            var blks = getBlocksByRowAndCol(i_blocks, row - 1, col)
            if (blks.length > 0) {
                rv.push(blks[0])
            }
        }
        if (row < 5) {
            var blks = getBlocksByRowAndCol(i_blocks, row + 1, col)
            if (blks.length > 0) {
                rv.push(blks[0])
            }
        }
    }
    if (check_col) {
        if (col > 0) {
            var blks = getBlocksByRowAndCol(i_blocks, row, col - 1)
            if (blks.length > 0) {
                rv.push(blks[0])
            }
        }
        if (col < 5) {
            var blks = getBlocksByRowAndCol(i_blocks, row, col + 1)
            if (blks.length > 0) {
                rv.push(blks[0])
            }
        }
    }
    var adjacentBlocks = []
    for (var j = 0; j < rv.length; j++) {
        var blk = rv[j]
        if (blk.color == color) {
            adjacentBlocks.push(blk)
        }
    }
    return adjacentBlocks
}
/* Make a function that finds the adjacent Blocks for each Block in an array of blocks, and then groups together any set of adjacent Blocks which contain common Blocks with one another. */
function getAdjacentBlocksGroups(i_blocks) {
    var rv = []

    for (var u = 0; u < i_blocks.length; u++) {
        var adjacentBlocks = getAdjacentBlocksToBlock(i_blocks, i_blocks[u],
                                                      true, false)
        adjacentBlocks.push(i_blocks[u])
        for (var i = 0; i < adjacentBlocks.length; i++) {
            var adjacentBlock = adjacentBlocks[i]
            var adjacentBlockGroup = adjacentBlocks

            if (adjacentBlockGroup.length > 1) {
                rv.push(adjacentBlockGroup)
            }
        }
    }

    for (u = 0; u < i_blocks.length; u++) {
        var adjacentBlocks = getAdjacentBlocksToBlock(i_blocks, i_blocks[u],
                                                      false, true)
        adjacentBlocks.push(i_blocks[u])
        for (var i = 0; i < adjacentBlocks.length; i++) {
            var adjacentBlock = adjacentBlocks[i]
            var adjacentBlockGroup = adjacentBlocks

            if (adjacentBlockGroup.length > 1) {
                rv.push(adjacentBlockGroup)
            }
        }
    }

    return rv
}
function getRandomColor() {
    //var colors = ["green", "yellow", "blue", "red"]
    var colors = ["green", "yellow", "blue", "red"]
    var rv = colors[Math.floor(Math.random() * colors.length)]
    return rv
}
function generateUuid(len) {
    var mask = 'ux'
    for (var u = 0; u < len - 1; u += 2) {
        mask += 'xy'
    }
    var uuid = mask.replace(/[xy]/g, function (c) {
        var r = Math.random() * len | 0, v = c == 'x' ? r : (r & 0x3 | 0x8)
        return v.toString(len)
    })
    return uuid
}
function generateArmyRandomNumbers() {
    var rv = []
    for (var i = 0; i < 6; i++) {
        var obj = {}
        obj.col = i
        obj.colors = []
        obj.uuids = []
        for (var e = 0; e < 100; e++) {
            obj.colors.push(getRandomColor())
            obj.uuids.push(generateUuid(5))
        }
        rv.push(obj)
    }
    return rv
}
function getNextBlockColor(reinforcements, col) {
    var colReinforcements = matchObjectsByProperties(reinforcements,
                                                     [makePropertyObject("col",
                                                                         col)])
    if (colReinforcements.length > 0) {
        var colColors = colReinforcements[0].colors
        var color = colColors[0]
        var colUuids = colReinforcements[0].uuid
        var uuid = colUuids[0]
        colColors.slice(0, 1)
        colColors.push(color)
        colUuids.slice(0, 1)
        colUuids.push(uuid)
        var new_reinforcements = filterObjectsByProperties(reinforcements,
                                                           [makePropertyObject(
                                                                "col", col)])
        colReinforcements.colors = colColors
        new_reinforcements.push(new_reinforcements)

        return {
            "color": color,
            "reinforcements": new_reinforcements,
            "uuid": uuid
        }
    } else {
        return {
            "color": getRandomColor(),
            "reinforcements": reinforcements,
            "uuid": generateUuid(5)
        }
    }
}
function escapeJson(str) {
    return str.replace(/"/g, '\\"')
}
