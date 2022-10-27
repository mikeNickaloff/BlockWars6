#include "hero.h"
#include "ability.h"
#include "abilitytargetcomponent.h"
#include "abilitytypepropertymodifier.h"
#include "abilitytargetblockmatcher.h"

Hero::Hero(QObject *parent)
    : QObject{parent}
{

}

AbilityTypePropertyModifier* Hero::createAbilityPropertyModifier(Ability::TargetPlayer targetPlayer, AbilityTargetComponent* targetComponent, QString i_property, AbilityTypePropertyModifier::PropertyModifierOperation i_operation, QVariant i_value)
{
    this->new_abilityPropertyModifier = new AbilityTypePropertyModifier(this);
    new_abilityPropertyModifier->m_targetPlayer = targetPlayer;
    new_abilityPropertyModifier->m_targetComponent = qobject_cast<QObject*>(targetComponent);
    new_abilityPropertyModifier->m_targetProperty = i_property;
    new_abilityPropertyModifier->m_operation = i_operation;
    new_abilityPropertyModifier->m_value = i_value;
    insertAbilityToHash(qobject_cast<QObject*>(new_abilityPropertyModifier));
    return new_abilityPropertyModifier;

}

void Hero::insertAbilityToHash(QObject* i_ability)
{
    QList<int> keys;
    keys << this->m_abilities.keys();
    std::sort(keys.begin(), keys.end());
    int newKey = keys.last();
    newKey++;
    this->m_abilities[newKey] = i_ability;
}
