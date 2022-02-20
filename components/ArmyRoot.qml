import QtQuick 2.0
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



    ArmyBlocks {
        id: armyBlocks
        z: 100
        armyOrientation: armyRoot.armyOrientation
    }
    ArmyHealth {
        id: armyHealth
    }
    ArmyPowerups {
        id: armyPowerups
    }
}
