import QtQuick 2.0
import QtQuick.Controls 2.5

import "../qml_shared"
Item {
    id: baseRoot
    anchors.fill: parent
    signal powerupActivated(var powerupName)

    // match properties is array of object properties that much match
    //     [ { 'property' : 'color', 'value' : 'red' } ]

    //assignProperties is the same only with properties to assign
    //     [ { 'property' : 'state', 'value' : 'launch' } ]
    signal selfPowerupMatchAndExecute(var matchProperties, var assignProperties)
    signal enemyPowerupMatchAndExecute(var matchProperties, var assignProperties)
    function setEnergy(newNRG) { energy = newNRG }
    function addEnergy(i_color, amt) { if (color === i_color) { energy += amt; console.log("Energy increased to " + energy);  } }
    property int energy: 0
    property int maxEnergy: 100
    property int xSize: 1
    property int ySize: 1
    property int gridIndex: 101
    property var powerupName: ""
    property var color: "black"
    onEnergyChanged: {
        powerupProgress.value = energy / maxEnergy;

    }
    PowerupModel {
        id: powerupModel
    }
    ProgressBar {
        z: 900
         value: 0
         Behavior on value {
             NumberAnimation {
              duration: 300
             }
         }
         padding: 2
         id: powerupProgress
         anchors.bottom: parent.bottom
         width: parent.width
         height: parent.height * 0.20
         background: Rectangle {
             implicitWidth: parent.width
             implicitHeight: parent.height * 0.20
             color: "black"
             radius: 5
         }

         contentItem: Item {

             implicitWidth: parent.width
             implicitHeight: parent.height * 0.20

             Rectangle {
                 width: powerupProgress.visualPosition * parent.width
                 height: parent.height
                 radius: 2
                 color: baseRoot.color
             }
         }
     }

    function loadPowerup(i_powerupName) {
        for (var i=0; i<powerupModel.count; i++) {
            if (powerupModel.get(i).name === i_powerupName) {
                var entry  = powerupModel.get(i);
                maxEnergy = entry.energy;
                powerupName = entry.name;
                baseRoot.color = entry.color
            }
        }
    }
    function activatePowerup() {
       if (energy >= maxEnergy) {
            energy = 0;
            powerupActivated(powerupName);
        }
    }
}
