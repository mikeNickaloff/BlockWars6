pragma Singleton

import QtQuick 2.0
import QuickFlux 1.1
import "./"

ActionCreator {

    signal armyBlocksRemoveBlock(var i_data)

    /* Create action by signal */


    /*
    "signal pickPhoto(url)

    It is equivalent to:

    function pickPhoto(url) {
        AppDispatcher.dispatch("pickPhoto", {url: url});
    }
    */

    //  signal compactBlocks(t_orientation)
    //  signal removeMatchingBlocks(t_orientation)
    function armyBlocksCheckForMatches(t_orientation) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksCheckForMatches,
                               t_orientation)
    }
    function blockSetRow(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockSetRow, i_data)
    }
    function blockSetColumn(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockSetColumn, i_data)
    }

    function armyBlocksCreateNewBlocks(t_orientation) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksCreateNewBlocks,
                               t_orientation)
    }
    function enqueueArmyBlocksSetLocked(i_data) {
        AppDispatcher.dispatch(ActionTypes.enqueueArmyBlocksSetLocked, i_data)
    }
    function armyBlocksSetLocked(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksSetLocked, i_data)
    }
    function armyBlocksSwapBlocks(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksSwapBlocks, i_data)
    }
    function armyBlocksRequestMovement(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksRequestMovement, i_data)
    }

    // uuid: block_id,  row: block.row, column: block.col
    function blockAnimationFinished(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockAnimationFinished, i_data)
    }

    // uuids: <List of Block IDs to Launch>
    function armyBlocksBatchLaunch(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksBatchLaunch, i_data)
    }

    // uuids: <list of uuids that match>
    function armyBlocksCheckFinishedWithMatches(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksCheckFinishedWithMatches,
                               i_data)
    }
    function armyBlocksCheckFinishedWithNoMatches(i_data) {
        AppDispatcher.dispatch(
                    ActionTypes.armyBlocksCheckFinishedWithNoMatches, i_data)
    }
    function armyBlocksMoveFinished(i_data) {

        AppDispatcher.dispatch(ActionTypes.armyBlocksMoveFinished, i_data)
    }

    function armyBlocksEndTurn(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksEndTurn, i_data)
    }
    function armyBlocksEnableMouseArea(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksEnableMouseArea, i_data)
    }

    function blockBeginLaunchSequence(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockBeginLaunchSequence, i_data)
    }

    // orientation: <top or bottom>, column: <column num>, health: <block health>, attackModifier: <attack modifier>, healthModifier: <health modifier>, uuid: <block uuid>
    function armyBlocksRequestLaunchTargetDataFromOpponent(i_data) {
        //console.log("Requesting target data:", JSON.stringify(i_data))
        AppDispatcher.dispatch(
                    ActionTypes.armyBlocksRequestLaunchTargetDataFromOpponent,
                    i_data)
    }

    // orientation: <top or bottom>, damagePoints: <array of y-vals that will trigger damage>, damageAmounts: <array of amounts of damage to deal>
    function armyBlocksProvideLaunchTargetDataToOpponent(i_data) {

        //     console.log("Providing target data:", JSON.stringify(i_data))
        AppDispatcher.dispatch(
                    ActionTypes.armyBlocksProvideLaunchTargetDataToOpponent,
                    i_data)
    }
    //orientation,  uuid, health, pos: <global pos>
    function blockSetHealthAndPos(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockSetHealthAndPos, i_data)
    }
    function blockLaunchCompleted(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockLaunchCompleted, i_data)
    }
    function armyBlocksDetermineNextAction(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksDetermineNextAction,
                               i_data)
    }
    function gameRootRequestQueue(i_data) {
        AppDispatcher.dispatch(ActionTypes.gameRootRequestQueue, i_data)
    }

    function armyBlocksRequestQueue(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksRequestQueue, i_data)
    }
    function armyBlocksProcesssQueue(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksProcessQueue, i_data)
    }
    function armyBlocksEnqueueConditional(i_cmd, i_data, i_action) {
        var t_data = {
            "command": i_cmd,
            "data": i_data,
            "action": i_action
        }
        AppDispatcher.dispatch(ActionTypes.armyBlocksEnqueueConditional, t_data)
    }
    function armyBlocksProcessSync(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksProcessSync, i_data)
    }
    function blockDeserialize(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockDeserialize, i_data)
    }
    function armyBlocksWaitForSync(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksWaitForSync, i_data)
    }

    function armyBlocksPostSyncFixUp(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksPostSyncFixUp, i_data)
    }

    function armyBlocksBeginTurn(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksBeginTurn, i_data)
    }
    function armyBlocksFixBlocks(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksFixBlocks, i_data)
    }
    function crossArmySignalTurnEnded(i_data) {
        AppDispatcher.dispatch(ActionTypes.crossArmySignalTurnEnded, i_data)
    }
    function signalBlockCreated(i_data) {
        AppDispatcher.dispatch(ActionTypes.signalBlockCreated, i_data)
    }
    function signalBlockRemoved(i_data) {
        AppDispatcher.dispatch(ActionTypes.signalBlockRemoved, i_data)
    }

    function signalBlocksSwapped(i_data) {
        AppDispatcher.dispatch(ActionTypes.signalBlocksSwapped, i_data)
    }
    function signalLauchComplete(i_data) {
        AppDispatcher.dispatch(ActionTypes.signaLaunchComplete, i_data)
    }
    function queryNearbyBlockColors(i_data) {
        AppDispatcher.dispatch(ActionTypes.queryNearbyBlockColors, i_data)
    }
    function provideNearbyBlockColors(i_data) {
        AppDispatcher.dispatch(ActionTypes.provideNearbyBlockColors, i_data)
    }
    function provideSelfBlockColors(i_data) {
        AppDispatcher.dispatch(ActionTypes.provideSelfBlockColors, i_data)
    }

    function blockSetOpacity(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockSetOpacity, i_data)
    }
    function blockSetColor(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockSetColor, i_data)
    }
    function blockFireAtTarget(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockFireAtTarget, i_data)
    }

    function reportBlockTargetDataToBackEnd(i_data) {
        AppDispatcher.dispatch(ActionTypes.reportBlockTargetDataToBackEnd,
                               i_data)
    }

    function blockKilledFromFrontEnd(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockKilledFromFrontEnd,
                               i_data)
    }
    function reportBlockMovementFinished(i_data) {
        AppDispatcher.dispatch(ActionTypes.reportBlockMovementFinished, i_data);
    }

    signal signalFromGameEngineSetBlockPosition(var i_data)
    signal sendToGameEngineBlockColorUpdated(var i_data)
}
