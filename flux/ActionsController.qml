pragma Singleton

import QtQuick 2.0
import QuickFlux 1.0
import "./"

ActionCreator {
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
        AppDispatcher.dispatch(ActionTypes.armyBlocksMoveFinished, i_data)
    }
    function armyBlocksEnableMouseArea(i_data) {
        AppDispatcher.dispatch(ActionTypes.armyBlocksEnableMouseArea, i_data)
    }

    function blockBeginLaunchSequence(i_data) {
        AppDispatcher.dispatch(ActionTypes.blockBeginLaunchSequence, i_data)
    }
    /* Create action by traditional method */
    function previewPhoto(url) {
        AppDispatcher.dispatch(ActionTypes.previewPhoto, {
                                   "url": url
                               })
    }
}
