import QtQuick 2.0
//import QtQml.Models 2.13
ListModel {
    id: powerupModel
    ListElement {
        name: "BlueShield"

        text: "Blue Shield"
        description: "When deployed, increases all blue blocks strength by +10"
        energy: 80
        component: "qrc://qml_powerups/BlueShield.qml"
        color: "steelblue"
    }

    ListElement {
        name: "RedSword"

        text: "Red Sword"
        description: "When activated, immediately launches all red blocks."
        energy: 100
        component: "qrc://qml_powerups/RedSword.qml"
        color: "firebrick"
    }
    ListElement {
        name: "Fireball"
        text: "Fireball"
        description: "Launches a fireball at the opponent's grid."
        energy: 30
        component: "qrc://qml_powerups/Fireball.qml"
        color: "gold"
    }
    ListElement {
        name: "Crossblade"
        text: "Cross Blade"
        description: "Attacks in criss-cross pattern across the opponent's board"
        energy: 60
        component: "qrc://qml_powerups/Crossblade.qml"
        color: "gold"
    }
    ListElement {
        name: "FreezeBomb"
        text: "Freeze Bomb"
        description: "Causes two random 4 x 4 areas to freeze for the next turn"
        energy: 80
        component: "qrc://qml_powerups/FreezeBomb.qml"
        color: "steelblue"
    }
    ListElement {
        name: "HealthRandom"
        text: "Health [Random]"
        description: "Grants health to random blocks."
        energy: 40
        component: "qrc://qml_powerups/FreezeBomb.qml"
        color: "forestgreeen"
    }
    ListElement {
        name: "Firewall"
        text: "Firewall"
        description: "Attacks 2 complete rows of blocks."
        energy: 70
        component: "qrc://qml_powerups/Firewall.qml"
        color: "firebrick"
    }
    ListElement {
        name: "Cornerbomb"
        text: "Corner Bomb"
        description: "Deals damage to the four corners of the enemy's grid."
        energy: 70
        component: "qrc://qml_powerups/Cornerbomb.qml"
        color: "forestgreen"
    }
    ListElement {
        name: "Cannon"
        text: "Cannon"
        description: "Attacks the back 3 rows of the opponent's grid."
        energy: 70
        component: "qrc://qml_powerups/Cannon.qml"
        color: "firebrick"
}

}
