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

function makeFunctionFromObject(fn_str, args) {}


/* match objects in array based on properties
   array is an array of objects
   properties is an array of objects in the form of: {property: someproperty, value: somevalue}
   [{property: someproperty, value: somevalue}, {property: someproperty, value: somevalue},...]

    *  property objects can be made with makePropertyObject(someproperty, somevalue)
*/
function matchObjectsByProperties(array, properties) {
    if (typeof array == "undefined") {
        console.log("failed!")
        return []
    }
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
    var syncList = []
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
                        dropList.push(newBlocks[newBlocks.indexOf(pblks[0])])
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
                    dropList.push(newBlocks[newBlocks.indexOf(chamberBlock[0])])
                    rv = true
                }
            }

            for (var p = 0; p < dropList.length; p++) {
                if (syncList.indexOf(dropList[p]) == -1) {
                    syncList.push(dropList[p])
                }
            }
        } else {

        }
    }
    return [newBlocks, rv, syncList]
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
function getGridBlocks(i_blocks) {
    var rv = []
    for (var a = 0; a < 6; a++) {
        var blockCol = getColOfBlocks(i_blocks, a)
        for (var b = 0; b < blockCol.length; b++) {
            rv.push(blockCol[b])
        }
    }
    return rv
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
function generateUuid(n, _useExtra) {
    // ⴀⴁⴂⴃⴄⴅⴆⴇⴈⴉⴊⴋⴌⴍⴎⴐⴑⴒⴓⴔⴖⴗⴘⴙⴚⴛⴜⴝⴞⴟⴠⴡⴢⴣⴤⴥⴧⴭ!@#$%^&*()<>?/.,:;=-|𐔰𐔱𐔲𐔳𐔴𐔵𐔶𐔷𐔸𐔹𐔺𐔻𐔼𐔽𐔾𐕀𐔿𐕁𐕂𐕃𐕄𐕅𐕆𐕇𐕈𐕉𐕊𐕋𐕎𐕍𐕏𐕐𐕑𐕒𐕓𐕔𐕕𐕖𐕗𐕘𐕙𐕚𐕛𐕜𐕝𐕞𐕟𐕠𐕡𐕢
    var useExtra = _useExtra
    if (_useExtra == null) {
        useExtra = false
    }
    var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('')
    if (useExtra) {
        chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_,.-+=|/<?>'.split(
                    '')
    }
    var uuid = [], i
    for (i = 0; i < n; i++) {
        uuid[i] = chars[Math.floor(Math.random() * chars.length)]
    }
    return uuid.join('')
}

//  [ { col: 0, index: 5,
//     data: [ { col: 0, index: 3, uuid: 9394, color: "red" } ]
//  } ]
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
            obj.uuid = generateUuid(5, true)
            obj.color = getRandomColor()
            new_data.push(obj)
        }
        index_obj.data = new_data
        rv.push(index_obj)
    }
    return rv
    console.log(JSON.stringify(rv))
}
function getArmyTopLevelObjectByCol(reinforcements, col) {
    if (reinforcements.length > 0) {
        var colReinforcements = matchObjectsByProperties(reinforcements,
                                                         [makePropertyObject(
                                                              "col", col)])[0]

        return colReinforcements
    } else {
        console.log("cannot getArmyTopLevelObjectByCol",
                    reinforcements.length, col)
    }
}
function getArmyCurrentIndex(armyBlocksObject, col) {
    return getArmyIndices[col]
}
function getArmyIndices(armyBlocksObject) {
    var rv = []

    for (var i = 0; i < 6; i++) {
        var obj = {
            "col": i,
            "index": armyBlocksObject.getArmyCurrentIndex(i)
        }
        rv.push(obj)
    }
    return rv
}
function getArmyBlockDataByIndex(reinforcements, col, index) {
    var colData = getArmyTopLevelObjectByCol(reinforcements, col)
    var new_idx = index
    if (colData.data.length <= index) {
        new_idx = index % colData.data.length
    }
    var blockData = matchObjectsByProperties(colData.data,
                                             [makePropertyObject("index",
                                                                 new_idx)])[0]
    //console.log("getArmyBlockByIndex(reinforcements", col, index, "):",
    //          JSON.stringify(blockData))
    return blockData
}
function getNextBlockColor(reinforcements, col) {
    var colReinforcements = getArmyTopLevelObjectByCol(reinforcements, col)
    if (colReinforcements.data.length > 0) {
        var curIdx = colReinforcements.index
        var curData = colReinforcements.data
        var newIdx = 0
        if (curData.length < (curIdx + 1)) {
            newIdx = curIdx + 1
        } else {
            newIdx = 0
        }
        var new_data = matchObjectsByProperties(colReinforcements.data,
                                                [makePropertyObject("index",
                                                                    newIdx)])
        var color = new_data[0].color
        var uuid = new_data[0].uuid

        var new_reinforcements = filterObjectsByProperties(reinforcements,
                                                           [makePropertyObject(
                                                                "col", col)])
        colReinforcements.index = newIdx
        new_reinforcements.push(colReinforcements)

        return {
            "color": color,
            "reinforcements": new_reinforcements,
            "uuid": uuid
        }
    } else {
        return {
            "color": getRandomColor(),
            "reinforcements": reinforcements,
            "uuid": generateUuid(4, true)
        }
    }
}
function escapeJson(str) {
    return str.replace(/"/g, '\\"')
}

/* make a function to convert an object's keys into a single letter each */
function keysToLetters(obj) {
    var letters = []
    for (var key in obj) {
        letters.push(key.charAt(0))
    }
    return letters
}

/* make an array that can store letter, key pairs */
var letterKeyPairs = []

/* make a function that accepts a key and checks if it exists within letterKeyPairs, if not then adds a new object to letterKeyPairs with key value pair key : firstLetterOfKey */
function addKeyToLetterKeyPairs(key) {
    var firstLetterOfKey = key.charAt(0)
    var usedKeys = matchObjectsByProperties(letterKeyPairs,
                                            [makePropertyObject("key", key)])
    if (usedKeys.length > 0) {
        return usedKeys[0].letter
    }
    var usedLetters = matchObjectsByProperties(
                letterKeyPairs,
                [makePropertyObject("letter",
                                    firstLetterOfKey)]).map(function (item) {
                                        return item.letter
                                    })

    if (usedLetters.indexOf(firstLetterOfKey) === -1) {
        letterKeyPairs.push({
                                "key": key,
                                "letter": firstLetterOfKey
                            })
    } else {
        firstLetterOfKey = key.charAt(0) + key.charAt(1)
        usedLetters = matchObjectsByProperties(
                    letterKeyPairs, [makePropertyObject("letter",
                                                        firstLetterOfKey)]).map(
                    function (item) {
                        return item.letter
                    })

        if (usedLetters.indexOf(firstLetterOfKey) === -1) {
            letterKeyPairs.push({
                                    "key": key,
                                    "letter": firstLetterOfKey
                                })
        } else {
            firstLetterOfKey = key.charAt(0) + key.charAt(1) + key.charAt(2)
            usedLetters = matchObjectsByProperties(
                        letterKeyPairs,
                        [makePropertyObject("letter", firstLetterOfKey)]).map(
                        function (item) {
                            return item.letter
                        })

            if (usedLetters.indexOf(firstLetterOfKey) === -1) {
                letterKeyPairs.push({
                                        "key": key,
                                        "letter": firstLetterOfKey
                                    })
            } else {

            }
        }
    }
    return firstLetterOfKey
}

/* make a function that accepts an object and changes every key to the return value of addKeyToLetterKeyPairs(key) while keeping the values */
function changeKeysToLetters(obj) {
    var newObj = {}
    for (var key in obj) {
        newObj[addKeyToLetterKeyPairs(key)] = obj[key]
    }
    return newObj
}

/* make a function to recursively change keys to letter over a multi-dimensional array of objects which may or may not have child arrays and/or child objects */
function changeKeysToLettersRecursively(obj) {
    if (Array.isArray(obj)) {
        var newObj = []
        for (var i = 0; i < obj.length; i++) {
            newObj.push(changeKeysToLettersRecursively(obj[i]))
        }
        return newObj
    } else if (typeof obj === 'object') {
        var newObj = {}
        for (var key in obj) {
            newObj[addKeyToLetterKeyPairs(
                       key)] = changeKeysToLettersRecursively(obj[key])
        }
        return newObj
    } else {
        return obj
    }
}

/* make a function that uses letterKeyPairs to convert a letter into a key for the keys in an object */
function letterToKey(letter) {
    for (var i = 0; i < letterKeyPairs.length; i++) {
        if (letterKeyPairs[i].letter === letter) {
            return letterKeyPairs[i].key
        }
    }
}

/* make a function to take an array of objects and convert the letters to keys recursively over child objects, child arrays, and top level objects */
function changeLettersToKeysRecursively(obj) {
    if (Array.isArray(obj)) {
        var newObj = []
        for (var i = 0; i < obj.length; i++) {
            newObj.push(changeLettersToKeysRecursively(obj[i]))
        }
        return newObj
    } else if (typeof obj === 'object') {
        var newObj = {}
        for (var key in obj) {
            newObj[letterToKey(key)] = changeLettersToKeysRecursively(obj[key])
        }
        return newObj
    } else {
        return obj
    }
}

/* convert the keys to letter for the array: [ { "col" : 4, "row": 4 }, { "col" : 4, "row": 5 }, { "col" : 2, "row": 3 }  ] and print the result on screen */
var array = [{
                 "col": 4,
                 "row": 4
             }, {
                 "col": 4,
                 "row": 5
             }, {
                 "col": 2,
                 "row": 3
             }]
var arrayWithLetters = changeKeysToLettersRecursively(array)
console.log(JSON.stringify(arrayWithLetters))
var convertedArray = changeLettersToKeysRecursively(arrayWithLetters)
console.log(JSON.stringify(convertedArray))

function compressArray(iarray) {
    var dict = {}
    // console.log(findAllStrings(iarray), generateUuids(findAllStrings(iarray)))
    letterKeyPairs = []
    var rv = changeKeysToLettersRecursively(iarray)
    return {
        "dict": letterKeyPairs,
        "array": rv
    }
}

function decompressArray(iarray) {
    letterKeyPairs = iarray.dict
    var rv = changeLettersToKeysRecursively(iarray.array)

    return rv
}
/* wrap the combination finding code into a function */
function getCombinations(n) {
    var numbers = []
    for (var i = 0; i < n; i++) {
        numbers.push(i)
    }
    var combinations = []
    for (var i = 0; i < numbers.length; i++) {
        for (var j = 0; j < numbers.length; j++) {
            for (var k = 0; k < numbers.length; k++) {
                for (var l = 0; l < numbers.length; l++) {
                    for (var m = 0; m < numbers.length; m++) {

                        combinations.push(
                                    [numbers[i], numbers[j], numbers[k], numbers[l], numbers[m]])
                    }
                }
            }
        }
    }
    return combinations
}

/* make a function to replace all string values of an object with a unique symbol, then add the symbol to the "dict" object as a property and the string as the value */
function replaceAll(dict, obj, str, sym) {
    for (var prop in obj) {
        if (obj.hasOwnProperty(prop)) {
            if (typeof obj[prop] === 'string') {
                obj[prop] = sym
            }
        }
    }
    dict[sym] = str
}

/* make a function to replace all occurances of a string within an object or array of objects or within a child object or child array of object with a specific string */
function replaceAllIn(dict, obj, str, sym) {
    for (var prop in obj) {
        if (obj.hasOwnProperty(prop)) {
            if (typeof obj[prop] === 'string') {
                obj[prop] = obj[prop].replace(str, sym)
            } else if (typeof obj[prop] === 'object') {
                replaceAllIn(dict, obj[prop], str, sym)
            }
        }
    }
    return {
        "dict": dict,
        "object": obj
    }
}

/* make a function to find all properties with string values within an object, array, and within child arrays or child objects and return an array of every unique string */
function findAllStrings(obj) {
    var arr = []
    for (var prop in obj) {
        if (obj.hasOwnProperty(prop)) {
            if (typeof obj[prop] === 'string') {
                arr.push(obj[prop])
            } else if (typeof obj[prop] === 'object') {
                arr = arr.concat(findAllStrings(obj[prop]))
            }
        }
    }
    return arr
}

/* make a function to generate a  5 characters long uuid for each string in  an array and return the array of generated uuids */
function generateUUIDs(arr) {
    var uuids = []
    for (var i = 0; i < arr.length; i++) {
        uuids.push(generateUuid(3, true))
    }
    return uuids
}
