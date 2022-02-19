import QtQuick 2.15
import QtQuick.Controls 1.4
import QtQuick.Window 2.15
import "pages"
import "scripts/main.js" as JS

Window {
    visible: true
    width: Math.min(Screen.desktopAvailableWidth, Screen.desktopAvailableHeight)
    height: Math.min(Screen.desktopAvailableWidth,
                     Screen.desktopAvailableHeight)
    title: qsTr("Hello World")

    Item {
        id: rootItem
        anchors.fill: parent

        StackView {
            anchors.fill: parent
            id: rootStackView
            initialItem: splashScreen
            onCurrentItemChanged: {
                if (Qt.isQtObject(rootStackView.currentItem)) {
                    rootStackView.currentItem.requestStackChange.connect(
                                rootStackView.push)
                }
            }
        }

        Component {
            id: splashScreen
            SplashScreen {
                anchors.fill: parent
            }
        }

        Component {
            id: mainMenu
            MainMenu {
                anchors.fill: parent
            }
        }
        Component.onCompleted: {

            // clear the stack view after 3 seconds
            JS.appendAnimationObject(rootItem, 3000, function () {
                rootStackView.clear()
                console.log("Clearing Stack View!")
            })

            JS.appendAnimationObject(rootItem, 3500, function () {
                JS.pushComponentToStack(mainMenu, rootStackView)

                console.log("Loading Main Menu!")
            })
        }
    }
}
