#ifndef HERO_H
#define HERO_H

#include <QObject>
#include <QHash>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include "ability.h"
#include "abilitytargetcomponent.h"
#include "abilitytypepropertymodifier.h"
#include "abilitytargetblockmatcher.h"


class Ability;
class AbilityTypePropertyModifier;
class AbilityTargetComponent;
class AbilityTargetBlockMatcher;
class Hero : public QObject
{
    Q_OBJECT
public:
    explicit Hero(QObject *parent = nullptr);
    QHash<int, QString> m_blocks;
    qint64 m_health;
    qreal m_chargeRate;
    QString m_chargeColor;
    qreal m_chargeMax;
    int m_cellWidth;
    int m_cellHeight;
    QString m_portrait;
    QString m_name;
    qreal m_resistance;
    QHash<int, QObject*> m_abilities;

    Ability* new_ability;
    AbilityTypePropertyModifier* new_abilityPropertyModifier;
    AbilityTypePropertyModifier* createAbilityPropertyModifier(Ability::TargetPlayer targetPlayer, AbilityTargetComponent* targetComponent, QString i_property, AbilityTypePropertyModifier::PropertyModifierOperation i_operation, QVariant i_value);

    QJsonObject serialize() {
        QJsonObject obj;
        obj.insert("health", m_health);
        obj.insert("chargeRate", m_chargeRate);
        obj.insert("chargeColor", m_chargeColor);
        obj.insert("chargeMax", m_chargeMax);
        obj.insert("cellWidth", m_cellWidth);
        obj.insert("cellHeight", m_cellHeight);
        obj.insert("portrait", m_portrait);
        obj.insert("name", m_name);
        obj.insert("resistance", m_resistance);
        QJsonArray array;
        foreach (QObject* ability, m_abilities) {
            //if (QString(ability->metaObject()->className()) == "AbilityTypePropertyModifier") {
                AbilityTypePropertyModifier* modifier = qobject_cast<AbilityTypePropertyModifier*>(ability);
                array.append(modifier->serialize());
           // }

        }
        obj.insert("abilities", array);
        return obj;
    }
signals:

public slots:
    void insertAbilityToHash(QObject *i_ability);

};

#endif // HERO_H
