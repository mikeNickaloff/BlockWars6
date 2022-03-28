import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Item {
    id: mainMenuContainer
    signal requestStackChange(var stack, var properties)
    width: Math.min(Screen.desktopAvailableWidth, Screen.desktopAvailableHeight)
    height: Math.min(Screen.desktopAvailableWidth,
                     Screen.desktopAvailableHeight)
    ListView {
        id: mainMenuListView
        anchors.fill: parent
        width: {
            return parent.width * 0.8
        }
        height: {
            return parent.height * 0.8
        }
        model: mainMenuModel
        delegate: MainMenuButton {
            text: model.text
            width: {
                return mainMenuListView.width
            }
            height: {
                return mainMenuListView.height / mainMenuModel.count
            }
            onMenuButtonClicked: {
                mainMenuContainer.requestStackChange(model.stack, {})
            }
        }
    }
    ListModel {
        id: mainMenuModel
        ListElement {
            text: "Single Player"
            stack: "qrc:///pages/SinglePlayer.qml"
        }
        ListElement {
            text: "Multiplayer"
            stack: "qrc:///pages/Multiplayer.qml"
        }
        ListElement {
            text: "Customize"
        }
        ListElement {
            text: "Settings"
        }
        ListElement {
            text: "Exit"
        }
    }
}
