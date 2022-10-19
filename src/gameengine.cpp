/* controls the flow of the game by receiving commands and signals from the QML flux system, performing operations,
  and then emitting signals back to the QML  front-end which is picked up by quickflux */

#include "gameengine.h"
#include "blockcpp.h"
#include <QHash>
#include <QtDebug>
#include <QQueue>
#include <QUuid>
#include <QVariantList>
#include <QTimer>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>
#include <QVariant>

#include "blockqueue.h"
GameEngine::GameEngine(QObject *parent, QString orientation)
    : QObject{parent}
{
    qSetGlobalQHashSeed(0);
    m_orientation = orientation;
    for (int i=0; i<6; i++) {
        this->createBlockQueue(i);
    }
    this->currentQueueToCheck = 0;
    mutexLocked = false;
    hasMoveBeenMade = false;
    didMoveForward = false;
    shouldRefillThisLoop = true;

    /*  for (int i=0; i<6; i++) {
        for (int u=0; u<6; u++) {
            QUuid uuid = QUuid::createUuid();
  //          qDebug() << uuid;
//            new_block = new BlockCPP(this, uuid.toString());



        }
    }


    for (QQueue<BlockCPP*> queue : m_queues.values()) {
        QVector<BlockCPP*> vec = queue.toVector();
        QVector<QString> uuids;
        for (BlockCPP* block : vec) {
            uuids << block->m_uuid;
        }
        qDebug() << uuids;
    } */
    /*  this->numberLaunched = 0;
    this->launchTimer = new QTimer(this);
    this->connect(launchTimer, SIGNAL(timeout()), this, SLOT(launchNext()));
    this->matchTimer = new QTimer(this);
    this->connect(matchTimer, SIGNAL(timeout()), this, SLOT(matchNextRow())); */
    // this->setMissionForAllBlockQueues(GameEngine::Mission::ReturnToBase);
    this->updateGameEngineTimer = new QTimer(this);
    this->connect(this->updateGameEngineTimer, SIGNAL(timeout()), this, SLOT(checkMissionStatus()));

    this->setMissionForAllBlockQueues(GameEngine::ReturnToBase);
    // this->updateGameEngineTimer->start(750);
}






BlockCPP *GameEngine::getBlockByUuid(QString uuid)
{
    if (this->m_blocks.keys().contains(uuid)) {
        return m_blocks.value(uuid);
    } else {
        //    qDebug() << "Could not find BlockCPP for uuid" << uuid;
        return nullptr;
    }
}

QList<BlockCPP *> GameEngine::getBlocksFromUuids(QStringList uuids)
{
    QList<BlockCPP*> rv;
    for (int i=0; i<uuids.length(); i++) {
        rv << getBlockByUuid(uuids.at(i));
    }
    return rv;
}

QStringList GameEngine::getColorsByUuids(QStringList uuids)
{
    QList<BlockCPP*> blocks = getBlocksFromUuids(uuids);
    QStringList rv;

    for (int i=0; i<blocks.length(); i++) {
        if (blocks.at(i) == nullptr) { continue; }
        rv << blocks.at(i)->m_color;
    }
    //qDebug() << "getColorsByUUids" << "for" << uuids << "returnin" << rv;
    return rv;

}

bool GameEngine::areAllMissionsComplete()
{
    foreach (BlockQueue* bq, this->blockQueueValues) {
        if (bq->isMissionComplete() == false) { return false; }
    }
    return true;
}





BlockQueue *GameEngine::getBlockQueue(int column)
{

    if (this->m_blockQueues.keys().contains(column)) {
        return this->m_blockQueues.value(column, nullptr);
    }
    return nullptr;
}

BlockQueue *GameEngine::getBlockQueueWithFewestSoldiers()
{
    int smallest_size = 999999;
    BlockQueue* rv;
    foreach (BlockQueue* bq, this->blockQueueValues) {
        if (bq->totalSoldiers() < smallest_size) {
            rv = bq;
        }
    }
    return rv;
}

QVariantList GameEngine::computeBlocksToDestroy(QVariant i_health, QVariant i_column)
{
    int column = i_column.toInt();
    int health = i_health.toInt();
    BlockQueue* queue = this->getBlockQueue(column);
    if (queue == nullptr) { return QVariantList(); }
    qDebug() << "Checking" << i_column << "for blocks with less than or equal to" << i_health << "health" << "from" << queue->m_battlefieldBlocks.values() ;

    QVariantList rv;
    for (int i=6; i>=0; i--) {
        QString blkUuid = queue->m_battlefieldBlocks.value(i, "");
        BlockCPP* blk = queue->getBlockFromUuid(blkUuid);

        if (blk != nullptr) {
            qDebug() << "---->" << "column" << blk->m_column << "block" << blk->m_uuid << "has" << blk->m_health;
            if (blk->m_health > 0) {
                if (health > blk->m_health) {
                    health -= blk->m_health;
                    blk->m_health = 0;
                    rv.append(blk->m_uuid);
                } else {
                    if (health < blk->m_health) {
                        health = 0;
                        blk->m_health -= health;
                    } else {
                        health = 0;
                        blk->m_health = 0;
                        rv.append(blk->m_uuid);
                    }
                }
            }
        }
    }
    if (health > 0) {
        emit this->dealDamage(health);
        // deal damage directly to player
    }
    if (rv.length() == 0) {
//        foreach (int key, queue->m_battlefieldBlocks.keys()) {
//            queue->m_standbyBlocks[queue->getNextAvailableIdForStandby()] = queue->m_battlefieldBlocks.value(key);
//            queue->m_battlefieldBlocks.remove(key);

//        }
    }
    return rv;
}

bool GameEngine::anyQueueFoundAttacker()
{
    foreach (BlockQueue* bq, this->blockQueueValues) {
        if (bq->foundAttackers == true) { return true; }
    }
    return false;
}

QVariant GameEngine::serializePools()
{
    QJsonDocument doc;
    QJsonObject topObj;
    foreach (BlockQueue* bq, this->blockQueueValues) {
        QJsonObject bqObj = bq->serializePools();
        topObj.insert(QString("%1").arg(bq->m_column), bqObj);
    }
    doc.setObject(topObj);
    QVariant var = QVariant::fromValue(doc.toJson(QJsonDocument::Compact));
    return var;

}

QVariant GameEngine::getUuidFromUuidAndDirection(QString _uuid, QString _direction)
{

    QVariant uuid = QVariant::fromValue(_uuid);
    QVariant direction = QVariant::fromValue(_direction);
    BlockCPP* blk = this->getBlockByUuid(uuid.toString());
    if (blk != nullptr) {
        QString dirString = direction.toString();

        if (dirString == "up") {
            if (blk->m_uuidRowAbove != "") { return QVariant::fromValue(blk->m_uuidRowAbove); }
        }
        if (dirString == "down") {
            if (blk->m_uuidRowBelow != "") { return QVariant::fromValue(blk->m_uuidRowBelow); }
        }
        if (dirString == "left") {
            if (blk->m_uuidColumnRight != "") { return QVariant::fromValue(blk->m_uuidColumnRight); }
        }
        if (dirString == "right") {
            if (blk->m_uuidColumnLeft != "") { return QVariant::fromValue(blk->m_uuidColumnLeft); }
        }
    }
    return QVariant::fromValue(QString(""));
}

QString GameEngine::generateDebugString()
{
    QString rv = QString(" %1 %2 %3 ").arg(this->areAllMissionsComplete()).arg(this->mutexLocked).arg(this->movesRemaining);
    return rv;


}

bool GameEngine::hasBlank()
{
    foreach (BlockQueue* bq, this->blockQueueValues) {
        if (bq->hasBlanks()) { return true; }
    }
    return false;
}

bool GameEngine::areQueuesCaughtUp()
{
    foreach (BlockQueue* bq, this->blockQueueValues) {
        if (bq->m_mission == BlockQueue::WaitForQueueCatchup) { return true; }
    }
    return false;
}


void GameEngine::createBlockCPP(int column)
{
    BlockQueue* targetQueue = this->getBlockQueue(column);
    if (targetQueue == nullptr) { return; }
    QString blkUuid = targetQueue->m_uuidPool.value(targetQueue->m_poolNextIndex);
    QString color = targetQueue->m_colorPool.value(targetQueue->m_poolNextIndex);
    targetQueue->m_poolNextIndex++;
    if (targetQueue->m_poolNextIndex >= targetQueue->m_colorPool.keys().length()) {
        targetQueue->m_poolNextIndex = 0;
    }
    this->new_block = new BlockCPP(this, blkUuid);
    this->new_block->m_column = column;
    this->new_block->m_color = color;
    this->new_block->m_uuid = blkUuid;
    emit this->blockCreated(column, blkUuid, color, targetQueue->m_poolNextIndex);
    this->assignSoldierToBlockQueue(blkUuid, targetQueue);
    targetQueue->addUuidToReturningBlocks(blkUuid);
    m_blocks[blkUuid] = new_block;
    this->getBlockByUuid(blkUuid)->m_mission = BlockCPP::Mission::Standby;
    this->getBlockByUuid(blkUuid)->m_missionStatus = BlockCPP::MissionStatus::Complete;
    new_block->m_row = -15;



    /*  if ((row > 5) || (row < 0)) {
        QQueue<QString> queue = this->m_queues.value(column);
        queue.enqueue(uuid);

        m_queues[column] = queue;

        emit this->signalQueueUpdated(column, getQueue(column));
        //emit this->signalColumnQueueUpdate(column);
    } else {

        QQueue<QString> stack = this->m_stacks.value(column);
        QQueue<QString> newStack = insertUuidIntoStack(uuid, row, stack);
        m_stacks[column] = newStack;

        emit this->signalStackUpdated(column,getStack(column));

    }
 */

}



void GameEngine::setBlockColor(QString uuid, QString color)
{
    if (this->getBlockByUuid(uuid) != nullptr) {
        this->getBlockByUuid(uuid)->m_color = color;
    }
}



void GameEngine::createBlockQueue(int column)
{

    this->m_newBlockQueue = new BlockQueue(this, column, this);
    this->m_newBlockQueue->isInit = false;
    m_newBlockQueue->mutexLocked = false;
    /*this->connect(m_newBlockQueue, SIGNAL(requestUuidAtPosition(int, int, QString)), this, SLOT(handleRelayRequestUuidAtPosition(int, int, QString)));
    this->connect(m_newBlockQueue, SIGNAL(respondUuidAtPosition(int, int, QString)), this, SLOT(handleRelayRespondUuidAtPosition(int, int, QString)));
    this->connect(this, SIGNAL(forwardRequestUuidAtPosition(int,int, QString)),m_newBlockQueue, SLOT(receiveUuidAtPositionRequest(int, int, QString)));
    this->connect(this, SIGNAL(forwardResponseUuidAtPosition(int,int, QString)),m_newBlockQueue, SLOT(receiveUuidAtPositionResponse(int, int, QString))); */
    // m_newBlockQueue->generateColors();

    this->m_blockQueues[column] = m_newBlockQueue;
    this->blockQueueValues << m_newBlockQueue;
    m_newBlockQueue->mutexLocked = false;

}

void GameEngine::checkMissionStatus()
{

    bool shouldProceed = false;
    if (mutexLocked == mutexLocked) {

        mutexLocked = false;
        //qDebug() << "Game Engine Mission: " << this->m_mission << this->areAllMissionsComplete();



        BlockQueue* queue;
        bool hasWaitingForCatchupQueue = false;
        //if ((currentQueueToCheck % 2) == 0) {
            for (int i=0; i<6; i++) {
                queue = this->getBlockQueue(i);

                if ((queue->m_missionStatus == BlockQueue::MissionStatus::Complete) || (queue->m_missionStatus == BlockQueue::MissionStatus::Failed)) {
                    queue->m_mission = BlockQueue::WaitForQueueCatchup;
                }
                if (queue->m_mission == BlockQueue::WaitForQueueCatchup) {
                    hasWaitingForCatchupQueue = true;
                }
                queue->checkCurrentMission();



            }

            if (hasWaitingForCatchupQueue) {
             if (this->areQueuesCaughtUp()) {
                 shouldProceed = true;
             }
            }
            if (shouldProceed) {
            for (int i=0; i<6; i++) {
                if (queue->m_missionStatus == BlockQueue::MissionStatus::Failed) {
                    queue = this->getBlockQueue(i);
                    if (queue->m_mission == BlockQueue::Mission::PrepareStandby) {
                        qDebug() << "Standby Mission Failure!" << queue->m_standbyBlocks.keys() << queue->m_standbyBlocks.values();
                        mutexLocked = false;
                        setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);

                        return;
                    }
                    if (queue->m_mission == BlockQueue::Mission::WaitForOrders) {
                        this->setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);
                        if (hasBlank()) {
                            this->setMissionForAllBlockQueues(GameEngine::Mission::MoveRanksForward);
                        }
                        mutexLocked = false;
                        return;
                    }
                    if (queue->m_mission == BlockQueue::Mission::DeployToBattlefield) {
                       // queue->setQueueMission(BlockQueue::Mission::PrepareStandby);
                        //setMissionForAllBlockQueues(GameEngine::Mission::;
                        mutexLocked = false;
                        return;
                    }
                    if (queue->m_mission == BlockQueue::Mission::MoveRanksForward) {
                        this->setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);

                        queue->organizeBattlefieldQueue();
                        queue->m_missionStatus = BlockQueue::MissionStatus::Started;
                        mutexLocked = false;
                        return;
                    }
                    if (queue->m_mission == BlockQueue::Mission::AttackTargets) {
                        //qDebug() << "Waiting for attacking Targets to complete launch";
                        //queue->m_missionStatus = BlockQueue::MissionStatus::Started;
                        //this->setMissionForAllBlockQueues(GameEngine::Mission::AttackTargets);
                        return;
                    }
                    if (queue->m_mission == BlockQueue::Mission::ReadyFiringPositions) {

                    }
                }

            }
}



        if (1 == 1) {


            if ((shouldProceed) && (areAllMissionsComplete())) {

                if (this->m_mission == GameEngine::Mission::PrepareStandby) {

                    setMissionForAllBlockQueues(GameEngine::Mission::DeployToBattlefield);
                    return;
                }

                if (this->m_mission == GameEngine::Mission::DeployToBattlefield) {
                    setMissionForAllBlockQueues(GameEngine::Mission::ReadyFiringPositions);
                    return;
                }

                if (this->m_mission == GameEngine::Mission::ReturnToBase) {
                    setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);
                    return;
                }
                if (this->m_mission == GameEngine::Mission::ReadyFiringPositions) {
                    setMissionForAllBlockQueues(GameEngine::Mission::IdentifyTargets);
                    return;
                }
                if (this->m_mission == GameEngine::Mission::IdentifyTargets) {





                    if (!hasMoveBeenMade) {
                        if (!anyQueueFoundAttacker()) {

                            setMissionForAllBlockQueues(GameEngine::Mission::WaitForOrders);
                            emit this->unlockUserInput();
                        } else {
                            setMissionForAllBlockQueues(GameEngine::Mission::AttackTargets);
                        }
                    } else {
                        if (!anyQueueFoundAttacker()) {
                            qDebug() << "Move Completed";

                            if (this->movesRemaining <= 0) {

                                setMissionForAllBlockQueues(GameEngine::Mission::Defense);
                                emit this->turnEnd();
                                mutexLocked = false;
                                this->lockUserInput();
                                return;
                            } else {
                                this->setMissionForAllBlockQueues(GameEngine::Mission::WaitForOrders);
                                emit this->unlockUserInput();
                            }


                            setMissionForAllBlockQueues(GameEngine::Mission::WaitForOrders);
                        } else {
                            setMissionForAllBlockQueues(GameEngine::Mission::AttackTargets);
                        }

                    }
                    mutexLocked = false;
                    return;
                }
                if (this->m_mission == GameEngine::Mission::WaitForOrders) {
                    if (hasBlank()) { shouldRefillThisLoop = true; }
                    if (shouldRefillThisLoop) {
                        if (didMoveForward) {
                            didMoveForward = false;

                            mutexLocked = false;
                            shouldRefillThisLoop = false;
                            setMissionForAllBlockQueues(GameEngine::Mission::MoveRanksForward);
                            return;
                        } else {
                          // comment this out last change
                            didMoveForward = false;
                            setMissionForAllBlockQueues(GameEngine::Mission::ReadyFiringPositions);
                            mutexLocked = false;
                            return;
                        }

                    } else {
                        if (didMoveForward) {
                            didMoveForward = false;

                            setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);
                            mutexLocked = false;
                            return;

                        } else {
                            //   this->hasMoveBeenMade = false;
                            //  this->shouldRefillThisLoop = false;
                            this->shouldRefillThisLoop = true;
                            this->didMoveForward = false;
                            setMissionForAllBlockQueues(GameEngine::Mission::ReadyFiringPositions);
                            return;
                        }
                    }
                    qDebug() << "Arrived at 2nd gate in GameEngine::checkMissionStatus when mission equals WaitForOrders";
                    if (hasMoveBeenMade) {
                        if ((!didMoveForward) && (!shouldRefillThisLoop)) {

                            hasMoveBeenMade = false;
                           // this->movesRemaining--;
                            if (this->movesRemaining <= 0) {

                                setMissionForAllBlockQueues(GameEngine::Mission::Defense);
                             //   emit this->turnFinished();
                                mutexLocked = false;
                                return;
                            } else {
                                //this->setMissionForAllBlockQueues(GameEngine::Mission::WaitForOrders);
                                emit this->unlockUserInput();
                            }


                        } else {
                                setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);
                                return;
                        }
                    }
                }
                if (this->m_mission == GameEngine::Mission::AttackTargets) {
                    this->isPostMoveLooping = false;
                    didMoveForward = false;

                    setMissionForAllBlockQueues(GameEngine::Mission::MoveRanksForward);
                    mutexLocked = false;
                    return;

                }

                if (this->m_mission == GameEngine::Mission::MoveRanksForward) {
                    if (didMoveForward) {
                        qDebug() << "Did move forward";
                        this->setMissionForAllBlockQueues(GameEngine::Mission::DeployToBattlefield);
                    } else {
                        qDebug() << "Did not move forward";

                        setMissionForAllBlockQueues(GameEngine::DeployToBattlefield);
                        //this->setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);
                    }

                    mutexLocked = false;
                    return;
                }
                if (this->m_mission == GameEngine::Mission::Defense) {
                    for (int i=0; i<6; i++) {
                        BlockQueue* bq = this->m_blockQueues.value(i);
                        bq->hideBlocksWithNoHealth();
                    }
                    mutexLocked = false;
                }
            } else {

            }
            mutexLocked = false;
            currentQueueToCheck++;
            if (currentQueueToCheck > 5) {

                currentQueueToCheck = 0;
            }
        }
    }
}



void GameEngine::setMissionForAllBlockQueues(Mission mission)
{
    if (this->m_mission == GameEngine::WaitForOrders) {
                if (mission != GameEngine::WaitForOrders) {
                    emit this->lockUserInput();
                }
    }
    this->m_mission = mission;
    emit this->missionAssigned(QVariant::fromValue(this->convertMissionToString(mission).append(generateDebugString())));
    //qDebug() << "Set Game Engine Mission to" << mission;
    if (mission == GameEngine::Mission::PrepareStandby) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::PrepareStandby);
        }

    }

    if (mission == GameEngine::Mission::DeployToBattlefield) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::DeployToBattlefield);
        }
    }
    if (mission == GameEngine::Mission::ReadyFiringPositions) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::ReadyFiringPositions);
        }
    }
    if (mission == GameEngine::Mission::IdentifyTargets) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::IdentifyTargets);
        }
    }

    if (mission == GameEngine::Mission::AttackTargets) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::AttackTargets);
        }
    }
    if (mission == GameEngine::Mission::MoveRanksForward) {


        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::MoveRanksForward);
        }
    }
    if (mission == GameEngine::Mission::ReturnToBase) {

        foreach (BlockQueue* bq, this->blockQueueValues) {

            bq->setQueueMission(BlockQueue::Mission::PrepareStandby);

        }
    }
    if (mission == GameEngine::Mission::Defense) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::Defense);
        }
    }

    if (mission == GameEngine::Mission::Offense) {
        this->hasMoveBeenMade = false;
        this->movesRemaining = 3;
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::PrepareStandby);
        }
    }

    if (mission == GameEngine::Mission::WaitForOrders) {
        emit this->unlockUserInput();
        foreach (BlockQueue* bq, this->blockQueueValues) {


            bq->setQueueMission(BlockQueue::Mission::WaitForOrders);
         //   bq->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }
    }
    if (mission == GameEngine::Mission::WaitForNetworkResponse) {
        foreach (BlockQueue* bq, this->blockQueueValues) {
            bq->setQueueMission(BlockQueue::Mission::WaitForNetworkResponse);
        }
    }



}

void GameEngine::assignSoldierToBlockQueue(QString uuid, BlockQueue *blockQueue)
{


    blockQueue->assignBlockToQueue(uuid);

}

void GameEngine::handleReportedBattlefieldStatus(int column, QVariantMap blockData)
{
    emit this->sendBlockDataToFrontEnd(column, blockData);

    // qDebug() << blockData;
}

void GameEngine::generateTest()
{
    //this->setMissionForAllBlockQueues(GameEngine::ReturnToBase);
    foreach (BlockQueue* bq, this->blockQueueValues) {
        bq->generateColors();
        /*  for (int i=0; i<18; i++) {

            this->createBlockCPP(bq->m_column);
        } */
    }
    this->setMissionForAllBlockQueues(GameEngine::Mission::ReturnToBase);

}

void GameEngine::startLaunchAnimation(QString uuid)
{
    emit this->launchAnimationStarted(uuid);
}

void GameEngine::receiveLaunchTargetData(QVariant uuid, QVariant data)
{
    BlockCPP* blk = this->getBlockByUuid(uuid.toString());
    if (blk != nullptr) {
        blk->targetIdentified = true;
        blk->targetData = data;
        if (blk->m_row > 0) {
            QTimer::singleShot((10 * ( blk->m_row + 3)) + (20 * (blk->m_column + 2)), [this, blk]() {  fireBlockAtEnemy(QVariant::fromValue(blk->m_uuid), blk->targetData); } );
        } else {
            fireBlockAtEnemy(QVariant::fromValue(blk->m_uuid), blk->targetData);
        }
    }
}

void GameEngine::fireBlockAtEnemy(QVariant uuid, QVariant launchTargetData)
{

    //qDebug() << "Firing block " << uuid << launchTargetData;
    emit this->sendOrderToFireBlockToFrontEnd(uuid, launchTargetData);


}

void GameEngine::completeLaunch(QVariant _uuid, QVariant column)
{
    BlockCPP* blk = this->getBlockByUuid(_uuid.toString());
    if (blk != nullptr) {
        QString uuid = blk->m_uuid;

        //this->getBlockQueue(blk->m_column)->organizeStandbyQueue();
           this->hideBlock(uuid);
        blk->m_row = -20;

        blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
        int bfKey = this->getBlockQueue(blk->m_column)->m_battlefieldBlocks.key(blk->m_uuid);
       /* if (this->getBlockQueue(blk->m_column)->m_battlefieldBlocks.keys().contains(bfKey)) {
            this->getBlockQueue(blk->m_column)->m_battlefieldBlocks.remove(bfKey);
            this->getBlockQueue(blk->m_column)->m_standbyBlocks[this->getBlockQueue(blk->m_column)->getNextAvailableIdForStandby()] = uuid;
        } */

    }
    // this->getBlockQueue(blk->m_column)->organizeBattlefieldQueue();

}

void GameEngine::swapBlocks(QString uuid1, QString uuid2)
{
    if (this->m_mission != GameEngine::Mission::WaitForOrders) {
        //QTimer::singleShot(300, [this, uuid1, uuid2]() {  this->swapBlocks(uuid1, uuid2); } );
        return;
    }
    BlockCPP* blk1 =  this->getBlockByUuid(uuid1);
    BlockCPP* blk2 =  this->getBlockByUuid(uuid2);
    if ((blk1 == nullptr)   || (blk2 == nullptr)) { return; }

    QPair<QString, QString> uuidsBelow = qMakePair(blk1->m_uuidRowBelow, blk2->m_uuidRowBelow);
    QPair<QString, QString> uuidsAbove = qMakePair(blk1->m_uuidRowAbove, blk2->m_uuidRowAbove);
    QPair<QString, QString> uuidsRight = qMakePair(blk1->m_uuidColumnRight, blk2->m_uuidColumnRight);
    QPair<QString, QString> uuidsLeft = qMakePair(blk1->m_uuidColumnLeft, blk2->m_uuidColumnLeft);
    QPair<int, int> rows = qMakePair(blk1->m_row, blk2->m_row);
    QPair<int, int> columns = qMakePair(blk1->m_column, blk2->m_column);


    //below's above
    BlockCPP* blk1_below = this->getBlockByUuid(uuidsBelow.first);
    BlockCPP* blk2_below = this->getBlockByUuid(uuidsBelow.second);
    if (blk1_below != nullptr) {
        if (blk1_below->m_uuid != blk2->m_uuid)
            blk1_below->m_uuidRowAbove = blk2->m_uuid;
    }

    if (blk2_below != nullptr) {
        if (blk2_below->m_uuid != blk1->m_uuid)
            blk2_below->m_uuidRowAbove = blk1->m_uuid;
    }

    //above's below
    BlockCPP* blk1_above = this->getBlockByUuid(uuidsAbove.first);
    BlockCPP* blk2_above = this->getBlockByUuid(uuidsAbove.second);
    if (blk1_above != nullptr) {
        if (blk1_above->m_uuid != blk2->m_uuid)
            blk1_above->m_uuidRowBelow = blk2->m_uuid;
    }
    if (blk2_above != nullptr) {
        if (blk2_above->m_uuid != blk1->m_uuid)
            blk2_above->m_uuidRowBelow = blk1->m_uuid;
    }
    // left's rght

    BlockCPP* blk1_left = this->getBlockByUuid(uuidsLeft.first);
    BlockCPP* blk2_left = this->getBlockByUuid(uuidsLeft.second);
    if (blk1_left != nullptr) {
        if (blk1_left->m_uuid != blk2->m_uuid)
            blk1_left->m_uuidColumnRight = blk2->m_uuid;
    }
    if (blk2_left != nullptr) {
        if (blk2_left->m_uuid != blk1->m_uuid)
            blk2_left->m_uuidColumnRight = blk1->m_uuid;
    }

    // right's left

    BlockCPP* blk1_right = this->getBlockByUuid(uuidsRight.first);
    BlockCPP* blk2_right = this->getBlockByUuid(uuidsRight.second);
    if (blk1_right != nullptr) {
        if (blk1_right->m_uuid != blk2->m_uuid)
            blk1_right->m_uuidColumnLeft = blk2->m_uuid;
    }
    if (blk2_right != nullptr) {
        if (blk2_right->m_uuid != blk1->m_uuid)
            blk2_right->m_uuidColumnRight = blk1->m_uuid;
    }


    // left
    if (uuidsLeft.second != blk1->m_uuid) {
        blk1->m_uuidColumnLeft = uuidsLeft.second;
    } else {
        blk1->m_uuidColumnLeft = blk2->m_uuid;
    }

    if (uuidsLeft.first != blk2->m_uuid) {
        blk2->m_uuidColumnLeft = uuidsLeft.first;
    } else {
        blk2->m_uuidColumnLeft = blk1->m_uuid;
    }


    // right
    if (uuidsRight.second != blk1->m_uuid) {
        blk1->m_uuidColumnRight = uuidsRight.second;
    } else {
        blk1->m_uuidColumnRight = blk2->m_uuid;
    }

    if (uuidsRight.first != blk2->m_uuid) {
        blk2->m_uuidColumnRight = uuidsRight.first;
    } else {
        blk2->m_uuidColumnRight = blk1->m_uuid;
    }


    //down
    if (uuidsBelow.second != blk1->m_uuid) {
        blk1->m_uuidRowBelow = uuidsBelow.second;
    } else {
        blk1->m_uuidRowBelow = blk2->m_uuid;
    }

    if (uuidsBelow.first != blk2->m_uuid) {
        blk2->m_uuidRowBelow = uuidsBelow.first;
    } else {
        blk2->m_uuidRowBelow = blk1->m_uuid;
    }


    //up
    if (uuidsAbove.second != blk1->m_uuid) {
        blk1->m_uuidRowAbove = uuidsAbove.second;
    } else {
        blk1->m_uuidRowAbove = blk2->m_uuid;
    }

    if (uuidsAbove.first != blk2->m_uuid) {
        blk2->m_uuidRowAbove = uuidsAbove.first;
    } else {
        blk2->m_uuidRowAbove = blk1->m_uuid;
    }


    if (columns.first != columns.second) {
        QPair<int, int> assignments = qMakePair(this->getBlockQueue(columns.first)->m_assignedBlocks.key(blk1->m_uuid), this->getBlockQueue(columns.second)->m_assignedBlocks.key(blk2->m_uuid));
        QPair<int, int> bfPos = qMakePair(this->getBlockQueue(columns.first)->m_battlefieldBlocks.key(blk1->m_uuid), this->getBlockQueue(columns.second)->m_battlefieldBlocks.key(blk2->m_uuid));
        this->getBlockQueue(columns.first)->m_assignedBlocks[assignments.first] = blk2->m_uuid;
        this->getBlockQueue(columns.second)->m_assignedBlocks[assignments.second] = blk1->m_uuid;
        this->getBlockQueue(columns.first)->m_battlefieldBlocks[bfPos.first] = blk2->m_uuid;
        this->getBlockQueue(columns.second)->m_battlefieldBlocks[bfPos.second] = blk1->m_uuid;

    }

    if (rows.first != rows.second) {
        QPair<int, int> bfPos = qMakePair(this->getBlockQueue(columns.first)->m_battlefieldBlocks.key(blk1->m_uuid), this->getBlockQueue(columns.second)->m_battlefieldBlocks.key(blk2->m_uuid));
        this->getBlockQueue(columns.first)->m_battlefieldBlocks[bfPos.first] = blk2->m_uuid;
        this->getBlockQueue(columns.second)->m_battlefieldBlocks[bfPos.second] = blk1->m_uuid;
    }



    blk1->m_row = rows.second;
    blk2->m_row = rows.first;
    blk2->m_column = columns.first;
    blk1->m_column = columns.second;
    this->hasMoveBeenMade = true;
    this->movesRemaining--;
    this->shouldRefillThisLoop = false;
    this->didMoveForward = false;
    this->setMissionForAllBlockQueues(GameEngine::Mission::ReadyFiringPositions);
    //this->movesRemaining--;
    emit this->lockUserInput();
    /* getBlockQueue(columns.first)->organizeBattlefieldQueue();
    getBlockQueue(columns.second)->organizeBattlefieldQueue(); */
    this->reportBlockPosition(blk1->m_uuid, blk1->m_row, blk1->m_column);
    this->reportBlockPosition(blk2->m_uuid, blk2->m_row, blk2->m_column);
    /*this->handleReportedBattlefieldStatus(columns.first, getBlockQueue(columns.first)->serializBattlefield().toVariantList());
    this->handleReportedBattlefieldStatus(columns.second, getBlockQueue(columns.second)->serializBattlefield().toVariantList()); */


}


void GameEngine::startOffense()
{
    this->isOffense = true;
    this->movesRemaining = 3;
    this->hasMoveBeenMade = false;
    this->setMissionForAllBlockQueues(GameEngine::Mission::ReturnToBase);
    updateGameEngineTimer->start(300);
}

void GameEngine::startDefense()
{
    this->isOffense = false;
    this->hasMoveBeenMade  = false;
    this->movesRemaining = 0;
    this->setMissionForAllBlockQueues(GameEngine::Mission::Defense);
    updateGameEngineTimer->start(300);
}

void GameEngine::hideBlock(QString uuid)
{
    BlockCPP* blk = this->getBlockByUuid(uuid);

    if (blk != nullptr) {
        if (blk->m_hidden == false) {
            blk->m_hidden = true;
            emit this->blockHidden(uuid);
        }
    }

}

void GameEngine::showBlock(QString uuid)
{
    BlockCPP* blk = this->getBlockByUuid(uuid);
    if (blk != nullptr) {

        if (blk->m_hidden  == true) {
            blk->m_hidden = false;
            emit this->blockShown(uuid);
        }
    }

}

void GameEngine::deserializePools(QVariant i_pool_data)
{

    m_blocks.clear();
    QJsonDocument doc;
    doc = QJsonDocument::fromJson(i_pool_data.toByteArray());
    QJsonObject obj = doc.object();
   // qDebug() << "Deserializing" << obj;
    //  qDebug() << "Deserializing" << doc.toJson(QJsonDocument::Compact);
    for (int i=0; i<6; i++) {
        this->getBlockQueue(i)->mutexLocked = true;
        //    m_blockQueues.value(i)->generateColors();
        m_blockQueues.value(i)->deserializePool(obj.value(QString("%1").arg(i)).toObject());

        for (int a=0; a<18; a++) {


        }

        this->getBlockQueue(i)->mutexLocked = false;

    }
    //startOffense();
    this->setMissionForAllBlockQueues(GameEngine::Mission::PrepareStandby);

    //updateGameEngineTimer->start(1000);
}

void GameEngine::startTurn()
{
    this->updateGameEngineTimer->stop();
    this->movesRemaining = 3;
    this->hasMoveBeenMade = false;
    this->shouldRefillThisLoop = false;
    this->didMoveForward = false;
    this->isOffense = true;
  /*  this->handleReportedBattlefieldStatus(0, this->getBlockQueue(0)->serializeBattlefield(true, true, false));
    this->handleReportedBattlefieldStatus(1, this->getBlockQueue(1)->serializeBattlefield(true, true, false));
    this->handleReportedBattlefieldStatus(2, this->getBlockQueue(2)->serializeBattlefield(true, true, false));
    this->handleReportedBattlefieldStatus(3, this->getBlockQueue(3)->serializeBattlefield(true, true, false));
    this->handleReportedBattlefieldStatus(4, this->getBlockQueue(4)->serializeBattlefield(true, true, false));
    this->handleReportedBattlefieldStatus(5, this->getBlockQueue(5)->serializeBattlefield(true, true, false)); */
    this->updateGameEngineTimer->start(300);
    this->setMissionForAllBlockQueues(GameEngine::Mission::DeployToBattlefield);

    qDebug() << "Starting turn!";
}

void GameEngine::blockKilled(QVariant uuid)
{
    BlockCPP* blk = this->getBlockByUuid(uuid.toString());
    if (blk != nullptr) {
        blk->m_mission = BlockCPP::Mission::Dead;



            QString uuid = blk->m_uuid;

//            this->getBlockQueue(blk->m_column)->organizeStandbyQueue();

            blk->m_row = -20;
             this->hideBlock(uuid);
            blk->m_mission = BlockCPP::Mission::Standby;
            int bfKey = this->getBlockQueue(blk->m_column)->m_battlefieldBlocks.key(blk->m_uuid);
            if (this->getBlockQueue(blk->m_column)->m_battlefieldBlocks.keys().contains(bfKey)) {
                this->getBlockQueue(blk->m_column)->m_battlefieldBlocks.remove(bfKey);
                this->getBlockQueue(blk->m_column)->m_standbyBlocks[this->getBlockQueue(blk->m_column)->getNextAvailableIdForStandby()] = uuid;
                blk->m_missionStatus = BlockCPP::MissionStatus::Started;

            }
            this->reportBlockPosition(uuid, blk->m_row, blk->m_column);

      //  this->completeLaunch(uuid, blk->m_column);


        //this->hideBlock(blk->m_uuid);
       // this->handleReportedBattlefieldStatus(blk->m_column, this->getBlockQueue(blk->m_column)->serializeBattlefield(true, false, false));
    }
}

void GameEngine::reportBlockPosition(QString uuid, int row, int column)
{
    emit this->notifyFrontEndBlockPosition(uuid, row, column);
}

void GameEngine::blockMovementFinishedCallbackFromFrontEnd(QString uuid)
{
    BlockCPP* blk = this->getBlockByUuid(uuid);
    if (blk != nullptr) {
        if (this->m_mission == GameEngine::DeployToBattlefield) {

            blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
        }
        if (this->m_mission == GameEngine::MoveRanksForward) {
               blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
        }


    }
}

void GameEngine::blockTargetFoundCallbackFromFrontEnd(QString uuid)
{
    BlockCPP* blk = this->getBlockByUuid(uuid);
    if (blk != nullptr) {
        if (this->m_mission == GameEngine::IdentifyTargets) {

            blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
        }


    }
}

void GameEngine::reportMatchingBlockNeedTarget(QString uuid, int row, int column, int health)
{
    emit this->notifyFrontEndMatchingBlockNeedsTarget(uuid, row, column, health);
}





