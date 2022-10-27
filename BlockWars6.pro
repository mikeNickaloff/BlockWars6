QT += quick \
    widgets
QT += webchannel

CONFIG += c++17

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        abilities/ability.cpp \
        abilities/abilitytargetblockmatcher.cpp \
        abilities/abilitytargetcomponent.cpp \
        abilities/abilitytargetplayerhealth.cpp \
        abilities/abilitytargetplayerheroes.cpp \
        abilities/abilitytargetplayermoves.cpp \
        abilities/abilitytypepropertymodifier.cpp \
        abilities/abilitytypespawner.cpp \
        abilities/hero.cpp \
        main.cpp \
        network/ircsocket.cpp \
        network/webchanneltransport.cpp \
        src/blockcpp.cpp \
        src/blockprocessor.cpp \
        src/blockqueue.cpp \
        src/gameengine.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    abilities/ability.h \
    abilities/abilitytargetblockmatcher.h \
    abilities/abilitytargetcomponent.h \
    abilities/abilitytargetplayerhealth.h \
    abilities/abilitytargetplayerheroes.h \
    abilities/abilitytargetplayermoves.h \
    abilities/abilitytypepropertymodifier.h \
    abilities/abilitytypespawner.h \
    abilities/hero.h \
    network/ircsocket.h \
    network/webchanneltransport.h \
    src/blockcpp.h \
    src/blockprocessor.h \
    src/blockqueue.h \
    src/gameengine.h

   include(shared/tools/quickflux/quickflux.pri)

DISTFILES += \
    README.md
