#ifndef GAMEENGINE_H
#define GAMEENGINE_H

#include <QObject>
#include <QQuickItem>
#include <QQueue>
#include <QStack>
#include <QTimer>
#include <QJsonArray>
#include <QVariant>
#include "blockqueue.h"
class BlockCPP;
class BlockQueue;
class GameEngine : public QObject
{
    Q_OBJECT
public:
    GameEngine(QObject *parent = nullptr, QString orientation = "none");
    BlockCPP* new_block;
    QHash<QString, BlockCPP*> m_blocks;
    QString m_orientation;
    Q_INVOKABLE QString orientation() { return m_orientation; }

    BlockCPP* getBlockByUuid(QString uuid);
    QList<BlockCPP*> getBlocksFromUuids(QStringList uuids);
    QStringList getColorsByUuids(QStringList uuids);
    BlockQueue* m_newBlockQueue;
    bool areAllMissionsComplete();
    int currentQueueToCheck;

    bool hasMoveBeenMade;
    int movesRemaining;
    bool isOffense;
    bool isPostMoveLooping;
    QHash<int, BlockQueue*> m_blockQueues;
    QList<BlockQueue*> blockQueueValues;
    enum Mission {
        PrepareStandby,
        DeployToBattlefield,
        ReadyFiringPositions,
        IdentifyTargets,
        AttackTargets,
        MoveRanksForward,
        ReturnToBase,
        Defense,
        Offense,
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
        rv[ReturnToBase] = "ReturnToStandby";
        rv[Defense] = "Defense";
        rv[Offense] = "Offense";
        rv[WaitForOrders] = "WaitForOrders";
        rv[WaitForNetworkResponse] = "WaitForNetworkResponse";
        return rv.value(mission, "Invalid Mission");
    }
    GameEngine::Mission m_mission;
    Q_INVOKABLE BlockQueue* getBlockQueue(int column);

    BlockQueue* getBlockQueueWithFewestSoldiers();
   Q_INVOKABLE QVariantList computeBlocksToDestroy(QVariant i_health, QVariant i_column);

    bool anyQueueFoundAttacker();
    QTimer* updateGameEngineTimer;
    Q_INVOKABLE QVariant serializePools();
    Q_INVOKABLE QVariant getUuidFromUuidAndDirection(QString _uuid, QString _direction);

signals:
    void signalColumnQueueUpdate(int column);
    void signalStackUpdated(int column, QVariantList stack);
    void signalQueueUpdated(int column, QVariantList queue);
    void signalCheckMatches();
    void signalStartLaunchSequence(QVariantList uuids);
    void signalFinishedMatchChecking(bool foundMatches);
    void beginLaunchSequence(QString uuid);
    void launchingFinished();

    void relayRequestUuidAtPosition(int req_column, int req_position, QString req_uuid);
    void relayRespondUuidAtPosition(int res_column, int res_position, QString res_uuid);
    void forwardResponseUuidAtPosition(int res_column, int res_position, QString res_uuid);
    void forwardRequestUuidAtPosition(int req_column, int req_position, QString req_uuid);
    void bumpBlocksUp(int column, int bumpStartRow);

    void sendBlockDataToFrontEnd(int column, QVariant blockData);
    void blockCreated(int column, QString uuid, QString color, int row);
    void launchAnimationStarted(QString uuid);

    void sendOrderToFireBlockToFrontEnd(QVariant uuid, QVariant launchData);
    void dealDamage(int amount);
    void blockHidden(QString uuid);
    void blockShown(QString uuid);
    void missionAssigned(QVariant newMission);

public slots:
    Q_INVOKABLE void setOrientation(QString orientation) { m_orientation = orientation; }
    Q_INVOKABLE void createBlockCPP( int column);


    Q_INVOKABLE void setBlockColor(QString uuid, QString color);
    void createBlockQueue(int column);

    void checkMissionStatus();

    void setMissionForAllBlockQueues(GameEngine::Mission mission);
    void assignSoldierToBlockQueue(QString uuid, BlockQueue* blockQueue);

    void handleReportedBattlefieldStatus(int column, QVariantList blockData);
    Q_INVOKABLE void generateTest();
    void startLaunchAnimation(QString uuid);
    Q_INVOKABLE void receiveLaunchTargetData(QVariant uuid, QVariant data);

    void fireBlockAtEnemy(QVariant uuid, QVariant launchTargetData);
    void completeLaunch(QVariant uuid, QVariant column);

    void swapBlocks(QString uuid1, QString uuid2);

    Q_INVOKABLE void startOffense();
    Q_INVOKABLE void startDefense();
    void hideBlock(QString uuid);
    void showBlock(QString uuid);
    Q_INVOKABLE void deserializePools(QVariant i_pool_data);

};

#endif // GAMEENGINE_H
