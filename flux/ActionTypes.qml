pragma Singleton

import QtQuick 2.0
import QuickFlux 1.0

KeyTable {
    id: actionTypes

    property string armyRoot: "armyRoot"
    property string armyBlocks: "armyBlock"
    property string block: "block"
    property string gameRoot: "gameRoot"
    property string armyBlocksCheckForMatches: "armyBlocksCheckForMatches"
    property string armyBlocksCompactBlocks: "armyBlocksCompactBlocks"
    property string armyBlocksRemoveMatching: "armyBlocksRemoveMaching"
    property string armyBlocksSwapBlocks: "armyBlocksSwapBlocks"
    property string armyBlocksCreateNewBlocks: "armyBlocksCreateNewBlocks"
    property string blockSetRow: "blockSetRow"
    property string blockSetColumn: "blockSetColumn"
    property string enqueueArmyBlocksSetLocked: "enqueueArmyBlocksSetLocked"
    property string armyBlocksSetLocked: "armyBlocksSetLocked"
    property string armyBlocksRequestMovement: "armyBlocksRequestMovement"
    property string blockAnimationFinished: "blockAnimationFinished"
    property string blockBeginLaunchSequence: "blockBeginLaunchSequence"
    property string armyBlocksBatchLaunch: "armyBlocksBatchLaunch"
    property string armyBlocksCheckFinishedWithMatches: "armyBlocksCheckFinishedWithMatches"
    property string armyBlocksCheckFinishedWithNoMatches: "armyBlocksCheckFinishedWithNoMatches"
    property string armyBlocksMoveFinished: "armyBlocksMoveFinished"
    property string armyBlocksEndTurn: "armyBlocksEndTurn"
    property string armyBlocksEnableMouseArea: "armyBlocksEnableMouseArea"
}
