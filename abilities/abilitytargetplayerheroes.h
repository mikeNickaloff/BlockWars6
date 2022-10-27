#ifndef ABILITYTARGETPLAYERHEROES_H
#define ABILITYTARGETPLAYERHEROES_H

#include "abilitytargetcomponent.h"
#include <QObject>

class AbilityTargetPlayerHeroes : public AbilityTargetComponent
{
    Q_OBJECT
public:
    explicit AbilityTargetPlayerHeroes(QObject *parent = nullptr);
};

#endif // ABILITYTARGETPLAYERHEROES_H
