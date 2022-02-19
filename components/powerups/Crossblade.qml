import QtQuick 2.0

PowerupBase {
    anchors.fill: parent
    Component.onCompleted: {

        loadPowerup("Crossblade");
    }
    Image {
        id: powerupImage
        source: "qrc:///images/powerup_crossblade.png"
        anchors.fill: parent
    }

    function activate() {
        if (energy >= maxEnergy) {
            var randomCol = Math.floor(Math.random() * 5)
            var currentCol1 = randomCol;
            var currentCol2 = randomCol;
            var direction1 = -1;
            var direction2 = 1;
            for (var i=0; i<6; i++) {
                if (currentCol1 <= 0) {
                    direction1 = 1;
                }
                currentCol1 += direction1;
                if (currentCol2 >= 5) {
                    direction2 = -1;
                }
                currentCol2 += direction2;
                enemyPowerupMatchAndExecute([{ "property" : "row", "value" : i }, { "property" : "col", "value" : currentCol1 }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "exploding"}]);
                enemyPowerupMatchAndExecute([{ "property" : "row", "value" : i }, { "property" : "col", "value" : currentCol2 }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "exploding"}]);

            }

            //             selfPowerupMatchAndExecute([{ "property" : "col", "value" : randomCol }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "launch"}]);
            //enemyPowerupMatchAndExecute([{ "property" : "col", "value" : randomCol + 1 }, { "property" : "state", "value" : "idle" } ], [{"property" : "state", "value" : "launch"}]);
            activatePowerup(powerupName);
        }
    }





}
