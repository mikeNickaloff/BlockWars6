#ifndef ABILITYTYPEPROPERTYMODIFIER_H
#define ABILITYTYPEPROPERTYMODIFIER_H

#include "ability.h"
#include "abilitytargetcomponent.h"
#include "abilitytargetblockmatcher.h"
#include <QObject>
#include <QJsonObject>
class AbilityTypePropertyModifier : public Ability
{
    Q_OBJECT
public:
    explicit AbilityTypePropertyModifier(QObject *parent = nullptr);
    QString m_targetProperty;

    TargetPlayer m_targetPlayer;
    QObject* m_targetComponent;
    enum PropertyModifierOperation {
        add,
        subtract,
        multiply,
        divide,
        set
    };
    PropertyModifierOperation m_operation;
    QVariant m_value;

    QJsonObject serialize() {
        QJsonObject obj;
        obj.insert("targetProperty", QVariant::fromValue(m_targetProperty).toJsonValue());
        obj.insert("targetPlayer", QVariant::fromValue(static_cast<int>(m_targetPlayer)).toJsonValue());
        AbilityTargetBlockMatcher* comp = qobject_cast<AbilityTargetBlockMatcher*>(this->m_targetComponent);
        if (comp) {
            obj.insert("targetComponent", comp->serialize());
        }
        obj.insert("operation", QVariant::fromValue(static_cast<int>(m_operation)).toJsonValue());
        obj.insert("value", m_value.toJsonValue());
        return obj;
    }
};

#endif // ABILITYTYPEPROPERTYMODIFIER_H
