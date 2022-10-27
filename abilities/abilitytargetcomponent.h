#ifndef ABILITYTARGETCOMPONENT_H
#define ABILITYTARGETCOMPONENT_H

#include <QObject>
#include "../src/gameengine.h"
class GameEngine;
class AbilityTargetComponent : public QObject
{
    Q_OBJECT
public:
    AbilityTargetComponent(QObject *parent = nullptr, GameEngine* i_engine = nullptr);
    GameEngine* m_engine;
    QJsonObject serialize();
signals:

protected:

};

#endif // ABILITYTARGETCOMPONENT_H
