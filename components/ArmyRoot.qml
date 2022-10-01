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
    }
    ArmyHealth {
        id: armyHealth
    }
    ArmyPowerups {
        id: armyPowerups
    }
    Component.onCompleted: {
        armyBlocks.armyRoot = armyRoot
        armyBlocks.armyOpponent = armyRoot.armyOpponent
    }
    GameEngine {
        id: gameEngine

        onSignalQueueUpdated: function (column, queue) {
            console.log("Got order to update queue", column, queue)
            blocks.armyBlockQueues[column] = queue
            for (var i = 0; i < queue.length; i++) {
                if (!gameEngine.isBlockInLaunchQueues(queue[i])) {
                    ActionsController.blockSetOpacity({
                                                          "orientation": blocks.armyOrientation,
                                                          "uuid": queue[i],
                                                          "opacity": 0
                                                      })
                }


                /*     ActionsController.blockSetRow({
                                                  "orientation": blocks.armyOrientation,
                                                  "uuid": queue[i],
                                                  "row": 5 + i
                                              })*/

                //                ActionsController.blockSetColumn({
                //                                                     "orientation": blocks.armyOrientation,
                //                                                     "uuid": queue[i],
                //                                                     "column": column
                //                                                 })
            }
        }
        onSignalStackUpdated: function (column, i_stack) {
            var stack = i_stack
            console.log("Stack for column", column, "setting to", i_stack)


            /*            blocks.armyActionLogger.push({
                                             "command": "stackUpdate",
                                             "column": column,
                                             "stack": stack
                                         }) */


            /*console.log("Stack logger is",
                        JSON.stringify(blocks.armyActionLogger).length) */
            blocks.armyBlockStacks[column] = stack
            for (var i = 0; i < stack.length; i++) {
                ActionsController.blockSetRow({
                                                  "orientation": blocks.armyOrientation,
                                                  "uuid": stack[i],
                                                  "row": 5 - i
                                              })
                ActionsController.blockSetColumn({
                                                     "orientation": blocks.armyOrientation,
                                                     "uuid": stack[i],
                                                     "column": column
                                                 })
                ActionsController.blockSetOpacity({
                                                      "orientation": blocks.armyOrientation,
                                                      "uuid": stack[i],
                                                      "opacity": 1.0
                                                  })
            }
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
                gameEngine.createBlockCPP(i_uuid, i_color, i_column,
                                          i_row, i_health)


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

    AppListener {
        filter: ActionTypes.blockBeginLaunchSequence
        onDispatched: function (actionType, i_data) {
            var t_orientation = i_data.orientation
            var t_uuid = i_data.uuid
            if (t_orientation == blocks.armyOrientation) {
                if (t_uuid != null) {
                    gameEngine.launchBlock(t_uuid)
                }
            }
        }
    }


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
            }
        }
    }
}
