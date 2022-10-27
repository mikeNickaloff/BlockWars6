#ifndef ABILITYTARGETPLAYERMOVES_H
#define ABILITYTARGETPLAYERMOVES_H

#include "abilitytargetcomponent.h"
#include <QObject>

class AbilityTargetPlayerMoves : public AbilityTargetComponent
{
    Q_OBJECT
public:
    explicit AbilityTargetPlayerMoves(QObject *parent = nullptr);
};

#endif // ABILITYTARGETPLAYERMOVES_H
