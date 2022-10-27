#ifndef ABILITYTARGETBLOCKMATCHER_H
#define ABILITYTARGETBLOCKMATCHER_H

#include "abilitytargetcomponent.h"

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>

class GameEngine;
class AbilityTargetBlockMatcher : public AbilityTargetComponent
{
    Q_OBJECT
public:
    AbilityTargetBlockMatcher(QObject *parent = nullptr, GameEngine* i_engine = nullptr);
    QList<QPair<int, int> > m_positions;
    qint64 m_count;
    enum matchType {
        ByGridPosition,
        ByColor,
        ByRandom
    };

    matchType m_matchType;
    virtual QJsonObject serialize() {
        QJsonObject obj;

        obj.insert("type", QVariant::fromValue(QString("BlockMatcher")).toJsonValue());
        obj.insert("positions", QVariant::fromValue(m_positions).toJsonValue());
        obj.insert("matchType", QVariant::fromValue(static_cast<int>(m_matchType)).toJsonValue());
        obj.insert("count", QVariant::fromValue(m_count).toJsonValue());
        return obj;
    }
};

#endif // ABILITYTARGETBLOCKMATCHER_H
