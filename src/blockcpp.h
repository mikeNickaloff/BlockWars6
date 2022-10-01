#ifndef BLOCKCPP_H
#define BLOCKCPP_H

#include <QMainWindow>
#include <QObject>
#include <QQuickItem>

class BlockCPP : public QObject
{
    Q_OBJECT
public:
    explicit BlockCPP(QObject *parent = nullptr, QString uuid = "");
    QString m_uuid;
    QString m_color;
signals:

};

#endif // BLOCKCPP_H
