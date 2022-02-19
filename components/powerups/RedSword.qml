import QtQuick 2.0

PowerupBase {
    anchors.fill: parent
    Component.onCompleted: {

        loadPowerup("RedSword");
    }
    Image {
        id: powerupImage
        source: "qrc:///images/powerup_redsword.png"
        anchors.fill: parent
    }

    function activate() {
         if (energy >= maxEnergy) {
             selfPowerupMatchAndExecute([{ "property" : "blockColor", "value" : "firebrick" }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "launch"}]);
             activatePowerup(powerupName);
         } else {

         }
    }




}
