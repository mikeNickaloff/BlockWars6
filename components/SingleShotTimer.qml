import QtQuick 2.0

Timer {
    property var action
    // Assing a function to this, that will be executed
    running: true
    onTriggered: {
        action()
        this.destroy(
                 ) // If this timer is dynamically instantitated it will be destroyed when triggered
    }
}
