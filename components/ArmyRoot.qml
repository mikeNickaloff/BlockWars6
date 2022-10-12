import QtQuick 2.15
import com.blockwars.network 1.0
import "."
import "../flux"
import QuickFlux 1.1
import "../scripts/main.js" as JS

Item {
    id: armyRoot


    /*   armyOrientation:  "top" or "bottom"
     *   determines direction of blocks moving and order of powerups and position of health bar
     */
    property var armyOrientation: "none"
    property var armyOpponent: null
    property var playerId: null
    property var startingHealth: 1000
    property var chosenPowerups: []
    property var irc: null
    property var armyReinforcements: []
    property alias blocks: armyBlocks
    property bool locked: false
    property int armyMovesMade: 0
    property alias engine: gameEngine
    property var playerHealth: 1000
    signal blockRemoved(var row, var col)
    width: {
        return parent.width * 0.75
    }
    height: {
        return parent.height * 0.45
    }
    Rectangle {
        color: "green"
        anchors.fill: parent
    }
    onArmyReinforcementsChanged: {
        armyBlocks.armyReinforcements = armyRoot.armyReinforcements
    }
    onLockedChanged: {

        //  armyBlocks.locked = armyRoot.locked
    }


    /* onMovesMadeChanged: {
        armyBlocks.armyMovesMade = movesMade
    } */
    onArmyOpponentChanged: {
        armyBlocks.armyOpponent = armyRoot.armyOpponent
    }
    onArmyOrientationChanged: {
        gameEngine.setOrientation(armyBlocks.armyOrientation)
    }
    ArmyBlocks {
        id: armyBlocks
        z: 100
        armyOrientation: armyRoot.armyOrientation
        armyReinforcements: armyRoot.armyReinforcements
        armyMovesMade: 0
        armyOpponent: armyRoot.armyOpponent
        onBlockRemoved: {
            armyRoot.blockRemoved(row, col)
        }
        irc: armyRoot.irc
        locked: false
        onLockedChanged: {

        }
        armyGameEngine: gameEngine
    }
    ArmyHealth {
        id: armyHealth
    }
    ArmyPowerups {
        id: armyPowerups
    }
    Text {
        id: debugArea
        font.pointSize: 29
        color: "white"
        anchors.bottom: armyRoot.top

        width: armyBlocks.width
        text: "Debug Messages"
    }
    Component.onCompleted: {
        armyBlocks.armyRoot = armyRoot
        armyBlocks.armyOpponent = armyRoot.armyOpponent

        gameEngine.generateTest()
        if (armyOrientation == "bottom") {

            //gameEngine.startOffense()
        } else {

            //gameEngine.startDefense()
        }
    }
    GameEngine {
        id: gameEngine

        //                ActionsController.blockSetColumn({
        //                                                     "orientation": blocks.armyOrientation,
        //                                                     "uuid": queue[i],
        //                                                     "column": column
        //                                                 })
        onLockUserInput: function () {
            ActionsController.armyBlocksEnableMouseArea({
                                                            "orientation": blocks.armyOrientation,
                                                            "enabled": false
                                                        })
        }
        onUnlockUserInput: function () {
            ActionsController.armyBlocksEnableMouseArea({
                                                            "orientation": blocks.armyOrientation,
                                                            "enabled": true
                                                        })
        }

        onTurnEnd: function () {
            ActionsController.armyBlocksEndTurn({
                                                    "orientation": blocks.armyOrientation
                                                })
        }
        onMissionAssigned: function (missionStr) {
            debugArea.text = missionStr
        }
        onSendBlockDataToFrontEnd: function (column, blockData) {
            //console.log("Received request to send block data to front end",
            //                        blockData)
            for (var i = 0; i < 6; i++) {
                var blkRow = null
                var blkColumn = null
                var blkColor = null
                var blk = blockData[i.toString()]
                if (blk != null) {
                    if (blk.row != null)
                        var blkRow = blk.row
                    if (blk.column != null)
                        var blkColumn = blk.column
                    if (blk.color != null)
                        var blkColor = blk.color
                    var blkUuid = blk.uuid
                }
                //  console.log("Dispatching", blk.row, blk.column, blk.uuid,
                //            blk.color)
                if (blkRow != null) {
                    ActionsController.blockSetRow({
                                                      "uuid": blkUuid,
                                                      "row": blkRow,
                                                      "orientation": orientation
                                                  })
                }
                if (blkColumn != null) {
                    ActionsController.blockSetColumn({
                                                         "uuid": blkUuid,
                                                         "column": blkColumn,
                                                         "orientation": orientation
                                                     })
                }
                if (blkRow < 6) {
                    if (blkRow >= 0) {
                        ActionsController.blockSetOpacity({
                                                              "uuid": blkUuid,
                                                              "opacity": 1.0,
                                                              "orientation": orientation
                                                          })
                    }
                }
                if (blkColor != null) {
                    ActionsController.blockSetColor({
                                                        "uuid": blkUuid,
                                                        "opacity": 1.0,
                                                        "orientation": orientation,
                                                        "color": blkColor
                                                    })
                }
            }
        }

        onSendOrderToFireBlockToFrontEnd: function (uuid, launchData) {
            //     console.log("Firing block order received by front-end", uuid,
            //                  JSON.stringify(launchData))
            ActionsController.blockFireAtTarget(launchData)
        }

        onBlockCreated: function (column, uuid, color, row) {

            blocks.createBlock(row, column, uuid, color)
            if (row < 6) {
                if (row > 0) {
                    ActionsController.blockSetOpacity({
                                                          "uuid": uuid,
                                                          "orientation": blocks.armyOrientation,
                                                          "opacity": 1
                                                      })
                } else {
                    ActionsController.blockSetOpacity({
                                                          "uuid": uuid,
                                                          "orientation": blocks.armyOrientation,
                                                          "opacity": 0
                                                      })
                }
            } else {
                ActionsController.blockSetOpacity({
                                                      "uuid": uuid,
                                                      "orientation": blocks.armyOrientation,
                                                      "opacity": 0
                                                  })
            }
        }

        onLaunchAnimationStarted: function (uuid) {
            ActionsController.blockBeginLaunchSequence({
                                                           "orientation": blocks.armyOrientation,
                                                           "uuid": uuid
                                                       })
        }
        onBeginLaunchSequence: function (uuid) {


            /*   ActionsController.armyBlocksBatchLaunch({
                                                        "uuids": uuid,
                                                        "orientation": blocks.armyOrientation
                                                    }) */
            //            if (blocks.armyNextAction == ActionTypes.stateArmyBlocksPreWaitForMatcher) {
            //                blocks.armyNextAction = ActionTypes.stateArmyBlocksPreWaitForLauncher
            //            }
            //            if (blocks.armyNextAction == ActionTypes.stateArmyBlocksWaitForMatcher) {
            //                blocks.armyNextAction = ActionTypes.stateArmyBlocksWaitForLauncher
            //            }
            ActionsController.blockBeginLaunchSequence({
                                                           "orientation": blocks.armyOrientation,
                                                           "uuid": uuid
                                                       })
        }
        onSignalFinishedMatchChecking: function (foundMatches) {

            //   console.log(gameEngine.getBlockQueue(3).serializeAllBlocks())
            console.log("got signal that match checking finished!",
                        foundMatches, blocks.armyNextAction)
            if (foundMatches) {
                if (blocks.armyNextAction == ActionTypes.stateArmyBlocksPreWaitForMatcher) {
                    blocks.armyNextAction = ActionTypes.stateArmyBlocksPreCheckMatches
                } else {
                    if (blocks.armyNextAction == ActionTypes.stateArmyBlocksWaitForMatcher) {
                        blocks.armyNextAction = ActionTypes.stateArmyBlocksCheckMatches
                        //ActionsController.armyBlocksCheckFinishedWithMatches({"orientation": armyBlocks.armyOrientation })
                    }
                }
            } else {
                if (blocks.armyNextAction == ActionTypes.stateArmyBlocksPreWaitForMatcher) {
                    blocks.armyNextAction = ActionTypes.stateArmyBlocksMoveStart
                }
                if (blocks.armyNextAction == ActionTypes.stateArmyBlocksWaitForMatcher) {
                    blocks.armyNextAction = ActionTypes.stateArmyBlocksMoveComplete
                    //ActionsController.armyBlocksCheckFinishedWithMatches({"orientation": armyBlocks.armyOrientation })
                }
            }
        }

        onBlockHidden: function (iuuid) {
            ActionsController.blockSetOpacity({
                                                  "uuid": iuuid,
                                                  "opacity": 0.0,
                                                  "orientation": orientation
                                              })
        }

        onBlockShown: function (iuuid) {
            ActionsController.blockSetOpacity({
                                                  "uuid": iuuid,
                                                  "opacity": 1.0,
                                                  "orientation": orientation
                                              })
        }
    }
    function startOffense() {
        gameEngine.startOffense()
    }
    function startDefense() {
        gameEngine.startDefense()
    }
    AppListener {
     filter: ActionTypes.blockKilledFromFrontEnd
     onDispatched: function (actionType, i_data) {
         if (i_data.orientation == blocks.armyOrientation) {
             gameEngine.blockKilled(i_data.uuid);
         }
     }
    }
    AppListener {
        filter: ActionTypes.armyBlocksEndTurn
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation != blocks.armyOrientation) {
                gameEngine.startTurn()
                //  engine.startOffense()
            } else {

                //    engine.startDefense()
            }
        }
    }
    AppListener {
        filter: ActionTypes.signalBlockCreated
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            var i_uuid = i_data.uuid
            var i_color = i_data.color
            var i_column = i_data.column
            var i_row = i_data.row
            var i_health = i_data.health
            if (i_orientation == blocks.armyOrientation) {

                //   gameEngine.createBlockCPP(i_uuid, i_color, i_column,
                //                            i_row, i_health)


                /*     console.log(armyOrientation, "queue for column", i_column,
                            "is now", gameEngine.getBlocksByColumn(i_column)) */
            }
        }
    }
    AppListener {
        filter: ActionTypes.signalBlockRemoved
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            if (i_orientation == blocks.armyOrientation) {
                gameEngine.removeBlock(i_data.uuid, i_data.column)
            }
        }
    }

    AppListener {
        filter: ActionTypes.signalBlocksSwapped
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == blocks.armyOrientation) {
                gameEngine.swapBlocks(i_data.uuid1, i_data.uuid2)
            }
        }
    }

    //    AppListener {
    //        filter: ActionTypes.blockBeginLaunchSequence
    //        onDispatched: function (actionType, i_data) {
    //            var t_orientation = i_data.orientation
    //            var t_uuid = i_data.uuid
    //            if (t_orientation == blocks.armyOrientation) {
    //                if (t_uuid != null) {
    //                    gameEngine.launchBlock(t_uuid)
    //                }
    //            }
    //        }
    //    }


    /*AppListener {
        filter: ActionTypes.signalLauchComplete
        onDispatched: function (actionType, i_data) {
            var i_orientation = i_data.orientation
            if (i_orientation == blocks.armyOrientation) {

                gameEngine.completeLaunch(i_data.uuid)
                //gameEngine.launchBlock(t_uuid)
            }
        }
    }*/
    AppListener {
        filter: ActionTypes.blockLaunchCompleted
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == blocks.armyOrientation) {
                gameEngine.completeLaunch(i_data.uuid, i_data.column)
                ActionsController.blockSetOpacity({
                                                      "orientation": blocks.armyOrientation,
                                                      "uuid": i_data.uuid,
                                                      "opacity": 0
                                                  })
            }
        }
    }
    //    AppListener {
    //        filter: ActionTypes.blockSetColumn
    //        onDispatched: function (actionType, i_data) {
    //            if (i_data.orientation == blocks.armyOrientation) {
    //                if (i_data.sender != "gameEngine") {
    //                    if (gameEngine.getBlockColumn(
    //                                i_data.uuid) != i_data.column) {
    //                        gameEngine.setBlockColumn(i_data.uuid,
    //                                                  i_data.column, false)
    //                    }
    //                }
    //            }
    //        }
    //    }
    //    AppListener {
    //        filter: ActionTypes.blockSetRow
    //        onDispatched: function (actionType, i_data) {
    //            if (i_data.orientation == blocks.armyOrientation) {
    //                if (((5 - i_data.row) <= 5) && (5 - i_data.row >= 0)) {
    //                    if (i_data.sender != "gameEngine") {
    //                        if (gameEngine.getBlockRow(
    //                                    i_data.uuid) != (5 - i_data.row)) {
    //                            gameEngine.setBlockRow(i_data.uuid,
    //                                                   5 - i_data.row, false)
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }


    /*AppListener {
      filter: ActionTypes.armyBlocksDetermineNextAction
        onDispatched: function (actionType, i_data) {

            for (var i = 0; i < 6; i++) {
                gameEngine.dropColumnDown(0, i)
            }
            gameEngine.updateBlockPropsFromStacks()
        }
    } */
    AppListener {
        filter: ActionTypes.sendToGameEngineBlockColorUpdated
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == blocks.armyOrientation) {
                gameEngine.setBlockColor(i_data.uuid, i_data.color)
            }
        }
    }

    AppListener {
        filter: ActionTypes.blockSetHealthAndPos
        onDispatched: function (actionType, i_data) {
            //console.log("launch data", JSON.stringify(i_data))
            if (i_data.orientation == blocks.armyOrientation) {
                gameEngine.receiveLaunchTargetData(i_data.uuid, i_data)
            }
        }
    }
    AppListener {
        filter: ActionTypes.armyBlocksSwapBlocks
        onDispatched: function (actionType, i_data) {
            if (i_data.orientation == blocks.armyOrientation) {
                gameEngine.swapBlocks(i_data.uuid1, i_data.uuid2)
            }
        }
    }
}
