import QtQuick 2.0

PowerupBase {
    anchors.fill: parent
    Component.onCompleted: {

        loadPowerup("BlueShield");
    }
    Image {
        source: "qrc:///images/powerup_blueshield.png"
        anchors.fill: parent
    }

    function activate() {
         if (energy >= maxEnergy) {
             selfPowerupMatchAndExecute([{ "property" : "blockColor", "value" : "steelblue" }, { "property" : "state", "value" : "idle" } ], [{"property" : "healthAdd", "value" : "10"}, {"property" : "state", "value" : "healthGain"}]);
             activatePowerup(powerupName);
         } else {
             /* test code */
             energy = maxEnergy;
             activate()
             /* end test code */
         }
    }


}
