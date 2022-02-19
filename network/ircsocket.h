#ifndef IRCSOCKET_H
#define IRCSOCKET_H

#include <QObject>

class IRCSocket : public QObject
{
    Q_OBJECT
public:
    explicit IRCSocket(QObject *parent = nullptr);

signals:

};

#endif // IRCSOCKET_H
