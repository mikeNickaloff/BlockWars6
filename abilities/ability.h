#ifndef ABILITY_H
#define ABILITY_H

#include <QObject>

class Ability : public QObject
{
    Q_OBJECT
public:
    explicit Ability(QObject *parent = nullptr);
    enum TargetPlayer {
        self,
        opponent
    };
signals:

};

#endif // ABILITY_H
