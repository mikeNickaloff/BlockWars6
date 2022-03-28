import QtQuick 2.15
import com.blockwars.network 1.0
import "."

Item {
    id: armyRoot


    /*   armyOrientation:  "top" or "bottom"
     *   determines direction of blocks moving and order of powerups and position of health bar
     */
    property var armyOrientation: "none"
    property var playerId: null
    property var startingHealth: 1000
    property var chosenPowerups: []
    property var irc: null
    property var armyReinforcements: []
    property alias blocks: armyBlocks
    property bool locked: false
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
        armyBlocks.locked = armyRoot.locked
    }
    ArmyBlocks {
        id: armyBlocks
        z: 100
        armyOrientation: armyRoot.armyOrientation
        armyReinforcements: armyRoot.armyReinforcements
        onBlockRemoved: {
            armyRoot.blockRemoved(row, col)
        }
        irc: armyRoot.irc
        locked: armyRoot.locked
    }
    ArmyHealth {
        id: armyHealth
    }
    ArmyPowerups {
        id: armyPowerups
    }
}
