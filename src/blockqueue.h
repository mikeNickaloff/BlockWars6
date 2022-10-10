#ifndef BLOCKQUEUE_H
#define BLOCKQUEUE_H

#include <QObject>
#include <QHash>
#include <QHash>
#include <QVariant>
#include <QJSValue>
#include "blockcpp.h"
class BlockCPP;
class GameEngine;
class BlockQueue : public QObject
{
    Q_OBJECT
public:

     BlockQueue(QObject *parent  = nullptr, int column = -1, GameEngine* i_engine = nullptr);
    QHash<int, QString> m_standbyBlocks;
    QHash<int, QString> m_battlefieldBlocks;
    QHash<int, QString> m_attackingBlocks;
    QHash<int, QString> m_destroyedBlocks;
    QHash<int, QString> m_colorAssigments;
    QHash<int, QString> m_assignedBlocks;
    QHash<int, QString> m_returningBlocks;
    QHash<int, QString> m_colorPool;
    QHash<int, QString> m_uuidPool;
    int m_poolNextIndex;
    int m_standbyNextAssignmentIndex;
    GameEngine* m_engine;
    BlockCPP* getBlockFromUuid(QString uuid);
    QList<QString> getPlayableBlocks(bool includeEmpty  = false);
    QJsonArray serializBattlefield();
    QString getNextUuidForStandby();

    bool foundAttackers;


    bool launchedBlocksThisMission;
    int m_column;

    enum Mission {
        PrepareStandby,
        DeployToBattlefield,
        ReadyFiringPositions,
        IdentifyTargets,
        AttackTargets,
        MoveRanksForward,
        ReturnToStandby,
        Defense,
        WaitForOrders,
        WaitForNetworkResponse
    };
    QString convertMissionToString(Mission mission) {
        QHash<Mission, QString> rv;
        rv[PrepareStandby] = "PrepareStandby";
        rv[DeployToBattlefield] = "DeployToBattlefield";
        rv[ReadyFiringPositions] = "ReadyFiringPositions";
        rv[IdentifyTargets] = "IdentifyTargets";
        rv[AttackTargets] = "AttackTargets";
        rv[MoveRanksForward] = "MoveRanksForward";
        rv[ReturnToStandby] = "ReturnToStandby";
        rv[Defense] = "Defense";
        rv[WaitForOrders] = "WaitForOrders";
        rv[WaitForNetworkResponse] = "WaitForNetworkResponse";
        return rv.value(mission, "Invalid Mission");
    }

    enum MissionStatus {
        NotStarted,
        Started,
        Complete,
        Failed
    };

    Mission m_mission;
    MissionStatus m_missionStatus;

    int getNextAvailableIdForStandby();
    int getNextAvailableIdForDeploymentToBattlefield();


    int getNextAvailableIdForReturning();
    int getNextAvailableIdForAttacking();

    bool isMissionComplete() {
        if (this->m_missionStatus == BlockQueue::MissionStatus::Complete) { return true; }
        return false;
    }
    int totalSoldiers();
    QString randomUuid();
    int getNextPoolId();
    int numberOfBlocksMovedForward;
    bool isInit;

    int getBattlefieldRowOfUuid(QString uuid);
    bool isBattlefieldRowEmpty(int row_num);

    bool mutexLocked;
    QJsonObject serializePools();

signals:


public slots:

    void assignBlockToQueue(QString uuid);
    void setBlockBelow(QString uuid, QString uuidBelow);
    void setBlockAbove(QString uuid, QString uuidAbove);
    void setBlockLeft(QString uuid, QString uuidLeft);
    void setBlockRight(QString uuid, QString uuidRight);

    void setQueueMission(BlockQueue::Mission mission);

    
    
    void startStandbyMission();
    void startDeploymentMission();
    void organizeStandbyQueue();
    void organizeReturningQueue();
    void organizeAttackingQueue();
    void organizeBattlefieldQueue();
    
    

    void checkCurrentMission();



    void startBattlefieldDeploymentMission();

    void startReadyFiringPositionsMission();
    Q_INVOKABLE void printStringToConsole(QJSValue val);


    void generateColors();
    void addUuidToReturningBlocks(QString uuid);

    void startIdentifyTargetsMission();

    void startAttackMission();

    void startMoveRanksForwardMission();


    void hideBlocksWithNoHealth();
    void deserializePool(QJsonObject pool_data);


    void startReturningMission();
};

#endif // BLOCKQUEUE_H
