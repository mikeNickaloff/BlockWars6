import QtQuick 2.0

PowerupBase {
    anchors.fill: parent
    Component.onCompleted: {

        loadPowerup("Fireball");
    }
    Image {
        id: powerupImage
        source: "qrc:///images/powerup_fireball.png"
        anchors.fill: parent
    }

    function activate() {
         if (energy >= maxEnergy) {
             var randomCol = Math.floor(Math.random() * 5)
             selfPowerupMatchAndExecute([{ "property" : "col", "value" : randomCol }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "launch"}]);
             //enemyPowerupMatchAndExecute([{ "property" : "col", "value" : randomCol + 1 }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "launch"}]);
             activatePowerup(powerupName);
         } else {

         }
    }




}
