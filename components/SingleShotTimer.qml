import QtQuick 2.15
import QuickFlux 1.1
import "../flux"

Timer {
    property var action
    property var element
    // Assing a function to this, that will be executed
    running: true
    onTriggered: {
        action()
        this.destroy(
                 ) // If this timer is dynamically instantitated it will be destroyed when triggered
    }
}
