import QtQuick 2.0
import QtQuick.Controls 2.12
import QtQuick.Controls.Universal 2.12
Item {
    id: buttonRoot
    property var text
    signal menuButtonClicked(var buttonText)
    property var fontSize: Math.min(buttonRoot.height * 0.5, buttonRoot.width * 0.5)
    property var selected: false
    property var theme: Universal.Dark
    onSelectedChanged: {

            theme = Qt.binding(function() { if (selected === true) { return Universal.Dark } return Universal.light });

    }
    Button {
        text: buttonRoot.text
        anchors.fill: parent
        font.pixelSize: fontSize
        onClicked: { buttonRoot.menuButtonClicked(buttonRoot.text) }

           Universal.theme: buttonRoot.theme
    }

}
