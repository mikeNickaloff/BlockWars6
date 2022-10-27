#include "abilitytargetcomponent.h"

AbilityTargetComponent::AbilityTargetComponent(QObject *parent, GameEngine* i_engine)
    : QObject{parent}, m_engine(i_engine)
{

}

QJsonObject AbilityTargetComponent::serialize()
{
    QJsonObject obj;
    return obj;
}
