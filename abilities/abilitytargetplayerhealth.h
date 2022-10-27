#ifndef ABILITYTARGETPLAYERHEALTH_H
#define ABILITYTARGETPLAYERHEALTH_H

#include "abilitytargetcomponent.h"
#include <QObject>

class AbilityTargetPlayerHealth : public AbilityTargetComponent
{
    Q_OBJECT
public:
    explicit AbilityTargetPlayerHealth(QObject *parent = nullptr);
};

#endif // ABILITYTARGETPLAYERHEALTH_H
