import QtQuick 2.0
import "multiplayer"

Item {
    property var title: "Multi Player Menu"
    signal requestStackChange(var stack, var properties)

    id: multiPlayerMenuContainer
    ListView {
        id: multiPlayerMenuListView
        anchors.centerIn: parent
        width: {
            return parent.width * 0.8
        }
        height: {
            return parent.height * 0.3
        }
        model: multiPlayerMenuModel
        delegate: MainMenuButton {
            text: model.text
            width: {
                return multiPlayerMenuListView.width
            }
            height: {
                return multiPlayerMenuListView.height / multiPlayerMenuModel.count
            }
            onMenuButtonClicked: {
                multiPlayerMenuContainer.requestStackChange(model.stack, {})
            }
        }
    }
    ListModel {
        id: multiPlayerMenuModel
        ListElement {
            text: "Normal Game"
            stack: "qrc:///pages/multiplayer/NormalGame.qml"
        }
        ListElement {
            text: "Practice Game"
            stack: "qml_multiplayer/PracticeGame.qml"
        }
        ListElement {
            text: "Random Game"
            stack: "qml_multiplayer/RandomGame.qml"
        }
        ListElement {
            text: "Custom Game"
            stack: "qml_multiplayer/CustomGame.qml"
        }
    }
}
