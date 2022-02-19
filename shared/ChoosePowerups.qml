import QtQuick 2.0
import QtQml.Models 2.13
import QtQuick.Controls 2.12
import QtQuick.Controls.Universal 2.12

import "../qml_ui"
import "../qml_shared"
Item {
    id: powerupMenuContainer
    signal requestStackChange(var stack, var properties)
    signal selectPowerup(var powerupName)
    signal deselectPowerup(var powerupName)
    property var title: "Choose Powerups"
    property var selectedPowerup
    property var gameRoot
    property var powerups: []
    Universal.theme: Universal.Dark

    Column {
        width: parent.width
        height: parent.height
        anchors.centerIn: parent

        Rectangle {
            id: chosenPowerupsContainer
            height: { return parent.height * 0.25 }
            width: { return parent.width * 0.80 }
            Universal.theme: Universal.Dark
            color: "black"

            Text {
                text: "Choose 4 powerups"

                font.pixelSize: { return Math.min(parent.height * 0.30, parent.width * 0.30) }
                anchors.fill: parent
            }
        }

        Row {
               width: parent.width
               height: { return parent.height * 0.65 }
            ListView {
                id: powerupMenuListView

                width: { return parent.width * 0.40 }
                height: { return parent.height}
                model: powerupModel
                delegate: MainMenuButton {
                    id: delegateButton
                    text: model.text
                    width: { return powerupMenuListView.width  }
                    height: { return powerupMenuListView.height / Math.min(powerupModel.count, 6) }
                    selected: false
                    Universal.theme: Universal.Dark
                    function checkSelectedPowerup(powerupName) {
                        if (powerupName === model.name) {
                            selected = true;
                            descriptionRect.text = model.description
                            selectedPowerup = model.name;
                            console.log("Selected " + powerupName);
                        }
                    }
                    function checkDeSelectedPowerup(powerupName) {
                        if (powerupName === model.name) {
                            selected = false;
                            descriptionRect.text = model.description
                            selectedPowerup = model.name;
                            console.log("De-Selected " + powerupName);
                        }
                    }
                    onMenuButtonClicked: {
                       // powerupMenuContainer.selectPowerup(model.name)
                        descriptionRect.text = model.description
                        selectedPowerup = model.name;
                    }
                    Component.onCompleted: {
                        powerupMenuContainer.selectPowerup.connect(delegateButton.checkSelectedPowerup)
                        powerupMenuContainer.deselectPowerup.connect(delegateButton.checkDeSelectedPowerup)
                    }
                }
            }
            Rectangle {
                id: descriptionRect
                width: { return parent.width * 0.50 }
                height: { return parent.height }
                color: "#382020"

                property alias text: descriptionArea.text
                Column {
                           height: { return parent.height }

                           width: { return parent.width }

                           Row {
                               width: { return parent.width }
                               height: { return parent.height * 0.30 }
                               MainMenuButton {
                                   id: equipButton
                                   text: "Select"
                                   width: { return parent.width * 0.45 }
                                   height: { return parent.height * 0.90 }
                                   fontSize: { return parent.height * 0.40 }
                                   onMenuButtonClicked: {
                                       selectPowerup(selectedPowerup)
                                       equipPowerup(selectedPowerup)
                                       unequipButton.visible = Qt.binding(function() { return hasPowerup(selectedPowerup); })
                                       equipButton.visible = Qt.binding(function() { return !hasPowerup(selectedPowerup); })

                                   }
                                   visible: { return !hasPowerup(selectedPowerup); }
                               }
                               MainMenuButton {
                                   id: unequipButton
                                   text: "Remove"
                                   width: { return parent.width * 0.45 }
                                   height: { return parent.height * 0.90 }
                                   onMenuButtonClicked: {
                                                 deselectPowerup(selectedPowerup)
                                       unequipPowerup(selectedPowerup)
                                       unequipButton.visible = Qt.binding(function() { return hasPowerup(selectedPowerup); })
                                       equipButton.visible = Qt.binding(function() { return !hasPowerup(selectedPowerup); })

                                   }
                                   visible: { return hasPowerup(selectedPowerup); }
                                   fontSize: { return parent.height * 0.40 }
                               }
                           }

                    TextArea {
                        wrapMode: TextArea.WordWrap
                        width: { return parent.width }
                        height: { return parent.height * 0.60 }
                        id: descriptionArea
                        font.pixelSize: { return Math.min(parent.height * 0.10, parent.width * 0.20) }
                        readOnly: true
                    }
                }
            }
        }
        PowerupModel {
            id: powerupModel
        }
    }
    function hasPowerup(powerupName) {
        return powerups.indexOf(powerupName) !== -1 ? true : false
    }
    function equipPowerup(powerupName) {
        if (!hasPowerup(powerupName))  {
            powerups.push(powerupName);
        }
    }
    function unequipPowerup(powerupName) {
        if (hasPowerup(powerupName))  {
                    powerups.splice(powerups.indexOf(powerupName), 1);
                }
    }
}
