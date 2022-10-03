#ifndef BLOCKCPP_H
#define BLOCKCPP_H

#include <QMainWindow>
#include <QObject>
#include <QQuickItem>

class BlockCPP : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int row READ getRow WRITE setRow NOTIFY rowChanged)
    Q_PROPERTY(int column READ getColumn WRITE setColumn NOTIFY columnChanged)
public:
    explicit BlockCPP(QObject *parent = nullptr, QString uuid = "");
    QString m_uuid;
    QString m_color;
    int m_row;
    int m_column;
    int getRow() { return m_row; }
    int getColumn() { return m_column; }
    QString serialize() {
        return QString("%1,%2,%3,%4,%5,%6,%7,%8").arg(m_uuid).arg(m_color).arg(m_row).arg(m_column).arg(m_uuidRowBelow).arg(m_uuidRowAbove).arg(m_uuidColumnLeft).arg(m_uuidColumnRight);
    }
    QString m_uuidRowBelow;
    QString m_uuidRowAbove;
    QString m_uuidColumnLeft;
    QString m_uuidColumnRight;
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
