#ifndef BLOCKCPP_H
#define BLOCKCPP_H

#include <QMainWindow>
#include <QObject>
#include <QQuickItem>
#include <QJsonObject>
#include <QJsonDocument>

class BlockQueue;

class BlockCPP : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int row READ getRow WRITE setRow NOTIFY rowChanged)
    Q_PROPERTY(int column READ getColumn WRITE setColumn NOTIFY columnChanged)
public:
    BlockCPP(QObject *parent = nullptr, QString uuid = "");
    QString m_uuid;
    QString m_color;
    int m_row;
    int m_column;
    int m_health;
    int getRow() { return m_row; }
    int getColumn() { return m_column; }
    QJsonObject serialize() {
        QJsonObject obj;
        obj.insert("uuid", m_uuid);
        obj.insert("color", m_color);
        obj.insert("row", m_row);
        obj.insert("column", m_column);
        obj.insert("above", m_uuidRowAbove);
        obj.insert("below", m_uuidRowBelow);
        obj.insert("left", m_uuidColumnLeft);
        obj.insert("right", m_uuidColumnRight);
        return obj;
    }
    QString m_uuidRowBelow;
    QString m_uuidRowAbove;
    QString m_uuidColumnLeft;
    QString m_uuidColumnRight;
    enum Mission {
        Standby,
        Deploy,
        HoldFire,
        ReadyFiringPosition,
        Attacking,
        MovingForward,
        ReturnToBase,
    };
    enum MissionStatus {
        NotStarted,
        Started,
        Complete,
        Failed
    };
    Mission m_mission;
    MissionStatus m_missionStatus;
    bool targetIdentified;
    QVariant targetData;
signals:
    void positionChanged(QString uuid, int row, int column);
    void rowChanged(int row);
    void columnChanged(int column);
public slots:
    void setRow(int newRow) { this->m_row = newRow; sendUpdatePositionSignal(); }
    void setColumn(int newCol) { this->m_column = newCol; sendUpdatePositionSignal(); }
    void sendUpdatePositionSignal();
};

#endif // BLOCKCPP_H
