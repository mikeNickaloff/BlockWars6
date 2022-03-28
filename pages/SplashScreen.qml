import QtQuick 2.15

Rectangle {
    signal requestStackChange(var stack, var properties)
    color: "black"
    gradient: Gradient {
        GradientStop {
            position: 0.42
            color: "#000000"
        }
        GradientStop {
            position: 1.00
            color: "#ffffff"
        }
    }
    border.color: "black"
    width: parent.width * 0.65
    height: parent.height * 0.65
}
