#include "blockqueue.h"
#include "blockcpp.h"
#include <QLinkedList>
#include <QQueue>
#include <QObject>
#include <QVariant>
#include "gameengine.h"
#include <QJSValue>
#include <QJSEngine>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QHash>
#include <QRandomGenerator>
#include <QDateTime>
BlockQueue::BlockQueue(QObject *parent, int column, GameEngine* i_engine)
    : QObject(parent), m_engine(i_engine)
{
    m_column = column;
    this->isInit = false;
    m_standbyNextAssignmentIndex = 0;
}

BlockCPP* BlockQueue::getBlockFromUuid(QString uuid)
{


    return m_engine->m_blocks.value(uuid, nullptr);


}



QList<QString> BlockQueue::getPlayableBlocks(bool includeEmpty)
{

}

QVariantMap BlockQueue::serializeBattlefield(bool getColor, bool getPos, bool getNeighbors)
{
    QVariantMap rv;
    for (int i=0; i<6; i++) {
        BlockCPP* blk = this->getBlockFromUuid(this->m_battlefieldBlocks.value(i, ""));
        if (blk != nullptr) {
            rv[QString("%1").arg(i)] = blk->serialize(getColor, getPos, getPos, getNeighbors);
        }
    }
    /* foreach (QString uuid, this->m_attackingBlocks.values()) {
        BlockCPP* blk = this->getBlockFromUuid(uuid);
        if (blk != nullptr) {
            rv.append(blk->serialize());
        }
    } */
    return rv;
}

QString BlockQueue::getNextUuidForStandby()
{
    if (this->m_standbyNextAssignmentIndex >= this->m_assignedBlocks.keys().length()) {
        this->m_standbyNextAssignmentIndex = 0;
    }
    //QString uuid = this->m_assignedBlocks.value(this->m_standbyNextAssignmentIndex, "");
    QString uuid = "";
    int loopCount = 0;
    while (uuid == "") {

        loopCount++;
        if (loopCount > 20) { break; }
        uuid = this->m_assignedBlocks.value(this->m_standbyNextAssignmentIndex, "");
        if (uuid == "") { this->m_standbyNextAssignmentIndex++; continue; }
        if (this->getBlockFromUuid(uuid)->m_mission == BlockCPP::Mission::ReturnToBase) {
            this->m_standbyBlocks[this->getNextAvailableIdForStandby()] =  uuid;
            this->m_standbyNextAssignmentIndex++;
            return uuid;
        } else {
            uuid = "";
        }
        this->m_standbyNextAssignmentIndex++;
        if (this->m_standbyNextAssignmentIndex >= this->m_assignedBlocks.keys().length()) {
            this->m_standbyNextAssignmentIndex = 0;
        }
    }
    return "";

}


int BlockQueue::getNextAvailableIdForStandby()
{
    int i = 0;

    while (this->m_standbyBlocks.keys().contains(i)) {
        i++;
    }
    return i;
}

int BlockQueue::getNextAvailableIdForDeploymentToBattlefield()
{
    int i = 0;

    while (this->m_battlefieldBlocks.keys().contains(i)) {
        i++;
    }
    return i;
}

int BlockQueue::getNextAvailableIdForReturning()
{
    int i = 0;

    while (this->m_returningBlocks.keys().contains(i)) {
        i++;
    }
    return i;

}

int BlockQueue::getNextAvailableIdForAttacking()
{
    int i = 0;

    while (this->m_attackingBlocks.keys().contains(i)) {
        i++;
    }
    return i;
}

int BlockQueue::totalSoldiers()
{
    int rv = 0;
    rv += this->m_standbyBlocks.keys().length();
    rv += this->m_attackingBlocks.keys().length();
    rv += this->m_battlefieldBlocks.keys().length();
    rv += this->m_returningBlocks.keys().length();
    return rv;
}

QString BlockQueue::randomUuid()
{
    QStringList rv;
    QString str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    while (rv.length() < 5) {

        QStringList availableChars;
        availableChars << str.split("", Qt::SkipEmptyParts);
        int randomVal = QRandomGenerator::global()->generate() % availableChars.length();
        rv << availableChars.at(randomVal);
    }
    return rv.join("");

}

int BlockQueue::getNextPoolId()
{
    this->m_poolNextIndex++;
    if (this->m_poolNextIndex >= this->m_colorPool.keys().length()) {
        this->m_poolNextIndex = 0;
    }
    return this->m_poolNextIndex;
}

int BlockQueue::getBattlefieldRowOfUuid(QString uuid)
{
    for (int i=0; i<m_battlefieldBlocks.keys().length(); i++) {
        if (this->m_battlefieldBlocks.value(i, "") != "") {
            if (this->m_battlefieldBlocks.value(i, "") == uuid) {
                return i;
            }
        }
    }
    return -1;
}

bool BlockQueue::isBattlefieldRowEmpty(int row_num)
{
    if (!this->m_battlefieldBlocks.keys().contains(row_num)) { return true; }
    if (this->m_battlefieldBlocks.value(row_num, "") == "") { return true; }
    if (this->m_attackingBlocks.values().contains(m_battlefieldBlocks.value(row_num)) == true) { return true; }
    if (this->m_returningBlocks.values().contains(m_battlefieldBlocks.value(row_num))) {
        return true;
    }
    if (this->m_battlefieldBlocks.keys(this->m_battlefieldBlocks.value(row_num, "")).length() > 1) {
        qDebug() << "Duplicate keys in battlefield row -- column" << m_column << "row" << row_num << "uuid" << this->m_battlefieldBlocks.value(row_num, "");
        return false;
    }

    return false;
}

QJsonObject BlockQueue::serializePools()
{
    QJsonObject topObj;
    QJsonObject obj;
    foreach (int key, this->m_colorPool.keys()) {
        obj.insert(QString("%1").arg(key), this->m_colorPool.value(key));

    }
    QJsonObject obj2;
    foreach (int key, this->m_uuidPool.keys()) {
        obj2.insert(QString("%1").arg(key), this->m_uuidPool.value(key));

    }
    topObj.insert("colors", obj);
    topObj.insert("uuids", obj2);

    return topObj;



}

bool BlockQueue::hasBlanks()
{
    bool rv = false;
    for (int i=0; i<6; i++) {
        if (this->isBattlefieldRowEmpty(i)) { return true; }
    }
    return false;
}

void BlockQueue::assignBlockToQueue(QString uuid)
{

    if (this->m_assignedBlocks.values().contains(uuid)) { return; } else {
        int i = 0;
        while (m_assignedBlocks.keys().contains(i)) {
            i++;
        }
        this->m_assignedBlocks[i] = uuid;

    }




}




void BlockQueue::setBlockBelow(QString uuid, QString uuidBelow)
{
    BlockCPP* block = this->getBlockFromUuid(uuid);
    if (block != nullptr) {
        block->m_uuidRowBelow = uuidBelow;

    }
}

void BlockQueue::setBlockAbove(QString uuid, QString uuidAbove)
{
    BlockCPP* block = this->getBlockFromUuid(uuid);
    if (block != nullptr) {
        block->m_uuidRowAbove = uuidAbove;

    }
}

void BlockQueue::setBlockLeft(QString uuid, QString uuidLeft)
{
    BlockCPP* block = this->getBlockFromUuid(uuid);
    if (block != nullptr) {
        block->m_uuidColumnLeft = uuidLeft;

    }
}

void BlockQueue::setBlockRight(QString uuid, QString uuidRight)
{
    BlockCPP* block = this->getBlockFromUuid(uuid);
    if (block != nullptr) {
        block->m_uuidColumnRight = uuidRight;

    }
}

void BlockQueue::setBlockRow(QString uuid, int row)
{
    BlockCPP* blk = this->getBlockFromUuid(uuid);
    if (blk != nullptr) {
        blk->m_row = row;
    }
}



void BlockQueue::setQueueMission(BlockQueue::Mission mission)
{
    //this->startPerfTimer();
    //qDebug() << "Set mission for" << m_column << "to" << this->convertMissionToString(mission);
    this->mutexLocked = false;
    this->m_mission = mission;
    this->m_missionStatus = BlockQueue::Started;
    if (this->m_mission == BlockQueue::Mission::PrepareStandby) {

        this->startStandbyMission();
    }
    if (this->m_mission == BlockQueue::Mission::DeployToBattlefield) {
        this->startBattlefieldDeploymentMission();
        
    }
    if (this->m_mission == BlockQueue::Mission::ReadyFiringPositions){
        this->startReadyFiringPositionsMission();
    }
    if (this->m_mission == BlockQueue::Mission::IdentifyTargets) {
        this->foundAttackers = false;
        this->startIdentifyTargetsMission();
    }

    if (this->m_mission == BlockQueue::Mission::AttackTargets) {

        this->launchedBlocksThisMission = false;

        this->startAttackMission();

    }
    if (this->m_mission == BlockQueue::Mission::MoveRanksForward) {
        this->startMoveRanksForwardMission();
    }

    if (this->m_mission == BlockQueue::Mission::Defense) {

      this->startDefenseMission();

    }
    if (this->m_mission == BlockQueue::Mission::WaitForOrders) {

    }
    if (this->m_mission == BlockQueue::Mission::WaitForNetworkResponse) {

    }
    if (this->m_mission == BlockQueue::Mission::ReturnToStandby) {
       /* this->mutexLocked = false;
        this->organizeStandbyQueue();
        this->organizeReturningQueue();
        if (this->m_returningBlocks.values().length() == 0) {
            qDebug() << "No more matches, move over.";
        }
        foreach (QString uuid, this->m_returningBlocks.values()) {
            if (this->m_standbyBlocks.values().contains(uuid)) {
                continue;
            }
            this->getBlockFromUuid(uuid)->m_row = getNextAvailableIdForStandby();

            //this->m_standbyBlocks[getNextAvailableIdForStandby()] = uuid;

        }
        this->m_returningBlocks.clear();

        this->organizeStandbyQueue();
        this->m_engine->handleReportedBattlefieldStatus(m_column, this->serializBattlefield().toVariantList());
        this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        */
        this->startReturningMission();

    }
    //this->stopPerfTimer(QString("queue #%1 -- mission %2 -- checkCurrentMission -- ").arg(m_column).arg(this->convertMissionToString(this->m_mission)));
    checkCurrentMission();
    this->mutexLocked = false;
}

void BlockQueue::startStandbyMission()
{

    if (this->m_assignedBlocks.keys().length() < 6) {
        QTimer::singleShot(50, this, SLOT(startStandbyMission()));
        return;
    }

    while (this->m_standbyBlocks.keys().length() < 6) {
        QString newUuid = this->getNextUuidForStandby();
        BlockCPP* blk = this->getBlockFromUuid(newUuid);
        if (blk != nullptr) {
            blk->m_color = this->m_colorPool.value(this->getNextPoolId());
            blk->m_mission = BlockCPP::Mission::Standby;
        }
    }
   // qDebug() << "Standby Queue is" << this->m_standbyBlocks.keys() << this->m_standbyBlocks.values();
    organizeStandbyQueue();


    //        while (m_standbyBlocks.keys().count() < 6) {

    //            if (m_standbyNextAssignmentIndex >= this->m_assignedBlocks.keys().length()) {
    //                m_standbyNextAssignmentIndex = 0;
    //            }

    //            blk->m_mission = BlockCPP::Standby;

    //            int poolId = this->getNextPoolId();

    //            this->m_standbyBlocks[getNextAvailableIdForStandby()] = blk->m_uuid;
    //           // m_engine->hideBlock(blk->m_uuid);
    //            blk->m_color = this->m_colorPool.value(poolId);
    //            organizeStandbyQueue();
    //            blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
    //            //qDebug() << "Standby queue is" << m_standbyBlocks.keys();
    //            this->m_standbyNextAssignmentIndex++;
    //        }







}





void BlockQueue::startDeploymentMission()
{
    int keysLen = this->m_battlefieldBlocks.keys().length();

    while (keysLen < 6) {
        QString uuid = this->m_standbyBlocks.value(0);
        organizeStandbyQueue();
        organizeBattlefieldQueue();
        this->m_battlefieldBlocks[getNextAvailableIdForDeploymentToBattlefield()] = uuid;
        m_standbyBlocks.remove(m_standbyBlocks.keys().first());
        keysLen++;



    }

}

void BlockQueue::organizeStandbyQueue()
{
    int id =  0;
   // int last = this->getNextAvailableIdForStandby() - 1;
   // QLinkedList<QString> uuids;
    QHash<int, QString> standbyQueue2;
    QLinkedList<int> standbyKeys;


    int u = 0;
    int sbc = standbyKeys.count();
    QList<int> sbk;
    sbk << this->m_standbyBlocks.keys();
    int sbvl = sbk.length();

    while (sbc < sbvl) {
        if (sbk.contains(u)) {
            standbyKeys.append(u);
            sbc++;
        }

        u++;
    }

    //    qDebug() << "Standby Queue is now" << standbyKeys.toStdList();
    int newKey = 0;
    while (!standbyKeys.isEmpty()) {
        int oldKey = standbyKeys.takeFirst();
        QString oldVal = this->m_standbyBlocks.value(oldKey);
        standbyQueue2[newKey] = oldVal;
        newKey++;
    }
    this->m_standbyBlocks.clear();
    QList<int> sb2k;
    sb2k << standbyQueue2.keys();
    foreach (int key, sb2k) {
        m_standbyBlocks[key] = standbyQueue2.value(key);
    }
    if (m_column == 3) {

    }
}

void BlockQueue::organizeReturningQueue()
{
    int last =  this->getNextAvailableIdForReturning();
    QHash<int, QString> returningCopy;
    QList<int> keys;
    keys << this->m_returningBlocks.keys();
    QLinkedList<QString> uuids;


    for (int i=0; i<keys.count() ; i++)  {
        if (keys.contains(i)) {
            uuids.append(this->m_returningBlocks.value(i));
        }

    }
    this->m_returningBlocks.clear();
    int id = 0;
    while (!uuids.isEmpty()) {
        this->m_returningBlocks[id] = uuids.takeFirst();
        id++;
    }
}

void BlockQueue::organizeAttackingQueue()
{
    int id =  0;
    int last = this->getNextAvailableIdForAttacking() - 1;
    QLinkedList<QString> uuids;
    while (id <= last) {
        if (this->m_attackingBlocks.keys().contains(id)) {
            uuids.append(this->m_attackingBlocks.value(id));
        }
        id++;
    }
    this->m_attackingBlocks.clear();
    id = 0;
    while (!uuids.isEmpty()) {
        this->m_attackingBlocks[getNextAvailableIdForAttacking()] = uuids.takeFirst();
    }
}

void BlockQueue::organizeBattlefieldQueue()
{
    QLinkedList<QString> uuids;
    QHash<int, QString> standbyQueue2;
    QLinkedList<int> standbyKeys;
    int u = 0;
    int bfLen = this->m_battlefieldBlocks.values().length();
    int sbLen =  standbyKeys.count();
    while (sbLen < bfLen) {
        if (this->m_battlefieldBlocks.keys().contains(u)) {
            standbyKeys.append(u);
            sbLen++;
        }
        u++;
    }
    //qSort(standbyKeys.begin(), standbyKeys.end());
    int newKey = 0;
    int numToDrop = 6 - standbyKeys.count();
    while (!standbyKeys.empty()) {
        int oldKey = standbyKeys.takeFirst();
        QString oldVal = this->m_battlefieldBlocks.value(oldKey);
        standbyQueue2[newKey + numToDrop] = oldVal;
        newKey++;
    }
    this->m_battlefieldBlocks.clear();
    QList<int> sb2Keys;
    sb2Keys << standbyQueue2.keys();
    foreach (int key, sb2Keys) {
        m_battlefieldBlocks[key] = standbyQueue2.value(key);
        setBlockRow(this->m_battlefieldBlocks.value(key), key);
    }
    if (m_column == 3) {
        //  qDebug() << "Battlefield Queue is now" << this->m_battlefieldBlocks.keys();
    }


    //organizeBattlefieldQueue();
    int lastId = this->getNextAvailableIdForDeploymentToBattlefield();

    for (int i=0; i<this->m_battlefieldBlocks.keys().length(); i++) {
        BlockCPP* blk = this->getBlockFromUuid(this->m_battlefieldBlocks.value(i, nullptr));
        if (blk != nullptr) {
            blk->m_row = i;
            blk->m_mission = BlockCPP::Deploy;
            blk->m_missionStatus = BlockCPP::MissionStatus::Started;
            // block 5 has no block above , otherwise set it
            if (i != lastId) {
                blk->m_uuidRowAbove = this->m_battlefieldBlocks.value(i + 1, "");
            }
            // block 0 has no block below , otherwise set it
            if (i != 0) {
                blk->m_uuidRowBelow = this->m_battlefieldBlocks.value(i - 1, "");
            }
            // m_engine->showBlock(blk->m_uuid);

        }
    }


    /* foreach (QString uuid, this->m_assignedBlocks.values()) {
        BlockCPP* blk = this->getBlockFromUuid(uuid);
        if (blk != nullptr) {
            if (!m_battlefieldBlocks.values().contains(blk->m_uuid)) {
                if (!m_attackingBlocks.values().contains(blk->m_uuid)) {
                    m_engine->hideBlock(blk->m_uuid);

                }
            }
        }
    } */
}

void BlockQueue::checkCurrentMission()
{
    if (this->m_missionStatus == BlockQueue::Failed) {
        qDebug() << "Mission failed" << m_column << this->m_mission;
        return;
    }

    if (this->mutexLocked) { return; }
    mutexLocked = true;
    //  this->mutexLocked = false;
    // qDebug() << "BlockQueue Status:" << m_column << m_mission << m_missionStatus;
    if (this->m_mission == BlockQueue::Mission::PrepareStandby) {
        bool is_complete = true;
        if (this->m_standbyBlocks.values().length() <= 5) { is_complete = false; }
        for (int i=0; i<6; i++) {
            if (this->m_standbyBlocks.value(i, "") == "") {
                is_complete = false;
                // break;
            }
        }

        if (is_complete) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
            //qDebug() << "Mission Status Updated for BlockQueue:" << m_column << this->m_missionStatus << "for mission" << this->m_mission;

        } else {
            organizeStandbyQueue();
            //          qDebug() << "STANDBY MISSION STATUS" << this->m_standbyBlocks.keys() << this->m_standbyBlocks.keys() << this->m_standbyBlocks.values() << "with returning blocks:" << this->m_returningBlocks.values() << "with assigned blocks" << this->m_assignedBlocks.keys() << this->m_assignedBlocks.values();
            //this->startStandbyMission();
            //  this->m_missionStatus = BlockQueue::MissionStatus::NotStarted;
        }
    }
    if (this->m_mission == BlockQueue::Defense) {
        QList<int> bfKeys;
        bfKeys << this->m_battlefieldBlocks.keys();
        foreach (int key, bfKeys) {
            QString uuid = this->m_battlefieldBlocks.value(key);
            BlockCPP* blk = this->getBlockFromUuid(uuid);
            if (blk != nullptr) {
                if (blk->m_health <= 0) {
                    if (blk->m_mission == BlockCPP::Mission::Dead) {
                       // this->m_engine->hideBlock(uuid);

                        this->m_battlefieldBlocks.remove(key);
                        blk->m_mission = BlockCPP::ReturnToBase;
                        blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
                        this->addUuidToReturningBlocks(blk->m_uuid);
                        continue;
                    }
                }
            }
        }
        organizeBattlefieldQueue();
    }
    if (this->m_mission == BlockQueue::WaitForOrders) {
        if (this->hasBlanks()) {
            this->m_missionStatus = BlockQueue::MissionStatus::Failed;
        }
    }



    if (this->m_mission == BlockQueue::Mission::DeployToBattlefield) {
        bool is_complete;

        for (int i=0; i<6; i++) {
            if (this->m_battlefieldBlocks.value(i, "") == "") {
                is_complete = false;

            }



        }
        if (is_complete) {

            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        } else {
            //    qDebug() << "battlefield mission state" << this->m_battlefieldBlocks.keys() << this->m_battlefieldBlocks.values() << this->m_standbyBlocks.keys() << this->m_standbyBlocks.keys() << this->m_standbyBlocks.values();
        }

    }
    if (this->m_mission == BlockQueue::Mission::ReturnToStandby) {
        if (this->m_returningBlocks.keys().length() == 0) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        } else {
            organizeReturningQueue();
             this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }
    }

    if (this->m_mission == BlockQueue::Mission::ReadyFiringPositions) {

    }


    if (this->m_mission == BlockQueue::Mission::IdentifyTargets) {
        bool all_identified = true;
        foreach(QString uuid, this->m_attackingBlocks.values()) {

            BlockCPP* blk = this->getBlockFromUuid(uuid);
            if (blk != nullptr) {
                if (blk->targetIdentified == false) {
                    all_identified = false;
                }
            }
        }

        if (all_identified) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }
    }

    if (this->m_mission == BlockQueue::Mission::AttackTargets) {
        if (this->m_attackingBlocks.keys().length() == 0) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }  else {
            this->m_missionStatus = BlockQueue::MissionStatus::Started;
        }
    }

    if (this->m_mission == BlockQueue::Mission::MoveRanksForward) {
        bool isCompact = true;
        bool foundBlank = false;

        for (int i=0; i<6; i++) {
            if (foundBlank) {
                if (m_battlefieldBlocks.value(i, "") != "") {
                    isCompact = false;

                    break;
                }
            } else {
                if (m_battlefieldBlocks.value(i, "") == "") {
                    foundBlank = true;
                }
            }
        }
        if (isCompact) {
            if (foundBlank) {
                this->m_missionStatus = BlockQueue::MissionStatus::Complete;
                m_engine->shouldRefillThisLoop = true;
                m_engine->didMoveForward = false;
            } else {
                m_engine->shouldRefillThisLoop = false;
                m_engine->didMoveForward = false;
            }

        } else {
            if (foundBlank) {
                m_engine->didMoveForward = true;
                m_engine->shouldRefillThisLoop = false;
            }

            //  this->startMoveRanksForwardMission();
        }

    }

   // this->mutexLocked = false;
    // organizeBattlefieldQueue();
}

void BlockQueue::startBattlefieldDeploymentMission()
{
    int a = 0;
    while (this->m_battlefieldBlocks.values().length() < 6) {
        int nextId = getNextAvailableIdForDeploymentToBattlefield();
        QString uuid = "";
        if (this->m_standbyBlocks.keys().length() > 0) {
            uuid = this->m_standbyBlocks.value(a);
            this->m_battlefieldBlocks[nextId] = uuid;
       //     m_engine->showBlock(uuid);
        }
        this->m_standbyBlocks.remove(a);
        this->organizeStandbyQueue();



    }
    this->organizeBattlefieldQueue();
    this->m_missionStatus = BlockQueue::MissionStatus::Complete;
    m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(true, true, false));
}

void BlockQueue::startReadyFiringPositionsMission()
{

    this->m_missionStatus = BlockQueue::MissionStatus::Started;

    //QJsonArray arr = this->serializBattlefield();

    // setup the Left and Right blocks for matching next
    for (int i=0; i<6; i++) {
        BlockCPP* blk = this->getBlockFromUuid(this->m_battlefieldBlocks.value(i, ""));
        if (blk != nullptr) {
            if (this->m_column > 0) {
                blk->m_uuidColumnLeft = m_engine->getBlockQueue(m_column - 1)->m_battlefieldBlocks.value(i, "");
            } else {
                blk->m_uuidColumnLeft = "";
            }
            if (this->m_column < 5) {
                blk->m_uuidColumnRight = m_engine->getBlockQueue(m_column + 1)->m_battlefieldBlocks.value(i, "");
            } else {
                blk->m_uuidColumnRight = "";
            }
            m_engine->showBlock(blk->m_uuid);
        }
    }

    // up down left right ready for all battlefield blocks
    // inform the game engine that we are ready

    this->m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(false, true, false));


    for (int i=0; i<6; i++) {
        BlockCPP* blk = this->getBlockFromUuid(this->m_battlefieldBlocks.value(i, ""));
        if (blk != nullptr) {
            BlockCPP* above = this->getBlockFromUuid(blk->m_uuidRowAbove);
            BlockCPP* below = this->getBlockFromUuid(blk->m_uuidRowBelow);
            BlockCPP* left = this->getBlockFromUuid(blk->m_uuidColumnLeft);
            BlockCPP* right = this->getBlockFromUuid(blk->m_uuidColumnRight);
            if ((above != nullptr) && (below != nullptr)) {
                if (above->m_color == below->m_color) {
                    if (above->m_color == blk->m_color) {
                        blk->m_mission = BlockCPP::Mission::Attacking;
                        blk->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        above->m_mission = BlockCPP::Mission::Attacking;
                        above->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        below->m_mission = BlockCPP::Mission::Attacking;
                        below->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                    }
                }
            }



            if ((left != nullptr) && (right != nullptr)) {
                if (left->m_color == right->m_color) {
                    if (left->m_color == blk->m_color) {
                        blk->m_mission = BlockCPP::Mission::Attacking;
                        blk->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        left->m_mission = BlockCPP::Mission::Attacking;
                        left->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        right->m_mission = BlockCPP::Mission::Attacking;
                        right->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                    }
                }
            }
        }
    }


    this->m_missionStatus = BlockQueue::MissionStatus::Complete;



}







void BlockQueue::printStringToConsole(QJSValue val)
{
    qDebug() << val.toString();
    val.call();

}

void BlockQueue::generateColors()
{
    QHash<int, QString> colors;
    colors[0] = "red";
    colors[1] = "green";
    colors[2] = "yellow";
    colors[3] = "blue";

    QHash<int, int> colorCounts;
    colorCounts[0] = 0;
    colorCounts[1] = 0;
    colorCounts[2] = 0;
    colorCounts[3] = 0;

    int totalCount = 4;
    for (int i=0; i<18; i++) {
        int colorIdx = QRandomGenerator::global()->generate() % colors.keys().length();
        int smallestIdx = 0;
        if (totalCount > 4) {
            int largest = -2;
            int smallest = 9999;
            int secondLargest = -1;
            for (int a=0; a<colorCounts.keys().length(); a++) {
                if (colorCounts.value(a) > largest) { largest = colorCounts.value(a); }
                if (colorCounts.value(a) < smallest) { smallest = colorCounts.value(a); smallestIdx = a; }
                //if ((colorCounts.value(a) < largest) && (colorCounts.value(a) > secondLargest))  { secondLargest = colorCounts.value(a); }
            }

            if (smallest != largest) {
                while (colorCounts.value(colorIdx) == largest) { colorIdx = smallestIdx;  break; }
                //if (colorCounts.value(colorIdx) == secondLargest) { colorIdx = colorCounts.key(smallest); }
                //   colorIdx = QRandomGenerator::global()->generate() % colors.keys().length();

            }
        }

        this->m_colorPool[i] = colors.value(colorIdx, "");
        this->m_uuidPool[i] = this->randomUuid();
        totalCount++;
        colorCounts[colorIdx] = colorCounts.value(colorIdx, 0) + 1;
        if (m_colorPool[i] == "") { qDebug() << "Cannot generate color" << i << "in queue" << m_column << "with color idx" << colorIdx;  break; }

    }
    this->m_poolNextIndex = 0;
}

void BlockQueue::addUuidToReturningBlocks(QString uuid)
{
    int i = 0;
    while (i < this->m_returningBlocks.keys().length()) {
        if (!this->m_returningBlocks.keys().contains(i)) {
            this->m_returningBlocks[i] = uuid;
            BlockCPP* blk = this->getBlockFromUuid(uuid);
            if (blk != nullptr) {
                blk->m_mission = BlockCPP::Mission::ReturnToBase;
            }
            return;
        }
        i++;
    }
}

void BlockQueue::startIdentifyTargetsMission()
{
    bool hasAttackers = false;
    bool mustReset = false;
    for (int i=0; i<6; i++) {
        BlockCPP* blk = getBlockFromUuid(this->m_battlefieldBlocks.value(i));
        if (blk != nullptr) {
            if (blk->m_mission == BlockCPP::Mission::Attacking) {

                hasAttackers = true;
                int u=0;
                while (this->m_attackingBlocks.keys().contains(u)) {
                    u++;
                }
                this->m_attackingBlocks[u] = blk->m_uuid;

                blk->targetIdentified = false;
                blk->m_missionStatus = BlockCPP::MissionStatus::Started;
                mutexLocked = true;
                QTimer::singleShot(100 * (6 - blk->m_row) + (50) , [this, blk]() {  m_engine->startLaunchAnimation(blk->m_uuid); } );
                QTimer::singleShot(100 * (7) + (50) , [this]() {  this->mutexLocked = false; this->m_missionStatus = BlockQueue::MissionStatus::Complete; } );

                //m_engine->startLaunchAnimation(blk->m_uuid);


            }
        }

    }
    foundAttackers = hasAttackers;

  //  this->m_missionStatus = BlockQueue::MissionStatus::Complete;
}

void BlockQueue::startAttackMission()
{


    for (int i=0; i<this->m_attackingBlocks.keys().length(); i++)  {
        BlockCPP* blk = this->getBlockFromUuid(m_attackingBlocks.value(i, ""));
        this->m_returningBlocks[this->getNextAvailableIdForReturning()] = blk->m_uuid;
        blk->m_missionStatus = BlockCPP::MissionStatus::Started;
        //QTimer::singleShot((5 * blk->m_row) + (10 * blk->m_column) + 100  , [this, blk]() {  m_engine->fireBlockAtEnemy(QVariant::fromValue(blk->m_uuid), blk->targetData); } );

    }
    m_attackingBlocks.clear();
    this->m_missionStatus = BlockQueue::MissionStatus::Complete;
}

void BlockQueue::startMoveRanksForwardMission()
{

    //if (!m_engine->isOffense) { this->m_missionStatus = BlockQueue::MissionStatus::Complete; }
    if (m_column == 3) {
        //qDebug() << "Moving blocks forward in column 3";

    }

    int battlefieldBlockCount = 0;
    int movementOffset = 0;
    bool foundBlank = false;
    bool isCompact = true;
    for(int i=0; i<6; i++) {
        if (this->isBattlefieldRowEmpty(i)) {
            if (m_column == 3) {
                //   qDebug() << "row " << i << "is empty";

            }
            this->m_battlefieldBlocks.remove(i);
        foundBlank = true;

            m_engine->shouldRefillThisLoop = true;
            /* if (this->m_standbyBlocks.keys().contains(0)) {
                   int targetRow = i;
                   this->m_battlefieldBlocks[targetRow] = m_standbyBlocks.value(0);
                   m_standbyBlocks.remove(0);
                   organizeStandbyQueue();
                   battlefieldBlockCount++;
               } else { organizeStandbyQueue(); continue; } */
        } else {
            if (foundBlank) {
                m_engine->didMoveForward = true;
                m_engine->shouldRefillThisLoop = false;
                isCompact = false;
            }
            battlefieldBlockCount++;
        }
    }
    if (isCompact) {
        m_engine->didMoveForward = false;
        if (foundBlank) {
            m_engine->shouldRefillThisLoop = true;
        } else {


        }
    }

    organizeBattlefieldQueue();
    //  hideBlocksWithNoHealth();
    m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(false, true, false));
    this->m_missionStatus = BlockQueue::MissionStatus::Complete;
}

void BlockQueue::hideBlocksWithNoHealth()
{

    for (int i=0; i<6; i++) {
        BlockCPP* blk = m_engine->getBlockByUuid(this->m_battlefieldBlocks.value(i));
        if (blk != nullptr) {
            if (blk->m_health <= 0) {
                this->m_battlefieldBlocks.remove(i);
                m_engine->hideBlock(blk->m_uuid);
            }
        }
    }

}

void BlockQueue::deserializePool(QJsonObject pool_data)
{
    QJsonObject colors = pool_data.value("colors").toObject();
    QJsonObject uuids = pool_data.value("uuids").toObject();
    this->m_uuidPool.clear();
    this->m_colorPool.clear();
    this->m_poolNextIndex = 0;
    this->m_assignedBlocks.clear();
    this->m_attackingBlocks.clear();
    this->m_battlefieldBlocks.clear();
    this->m_attackingBlocks.clear();
    this->m_standbyBlocks.clear();

    for (int i=0; i<18; i++) {
        QString color = colors.value(QString("%1").arg(i)).toString();
        QString uuid = uuids.value(QString("%1").arg(i)).toString();
        //    qDebug() << i << m_column << color << uuid;
        this->m_uuidPool[i] = uuid;
        this->m_colorPool[i] = color;
        // this->m_assignedBlocks[i] = uuid;


        m_engine->createBlockCPP(m_column);
        //     this->addUuidToReturningBlocks(uuid);
    }
    this->isInit = true;
   // this->m_engine->startOffense();
       this->setQueueMission(BlockQueue::Mission::ReturnToStandby);
}

void BlockQueue::startReturningMission()
{
    foreach (QString uuid, this->m_returningBlocks.values()) {
        this->getBlockFromUuid(uuid)->m_mission = BlockCPP::Mission::ReturnToBase;
    }
    this->m_returningBlocks.clear();
    this->m_missionStatus = BlockQueue::MissionStatus::Complete;

}

void BlockQueue::startDefenseMission()
{
    if (this->m_assignedBlocks.keys().length() < 6) {
        QTimer::singleShot(500, this, SLOT(startDefenseMission()));

        return;
    } else {
        this->m_standbyNextAssignmentIndex = 0;
        QList<QString> uuids;
        while (this->m_standbyBlocks.keys().length() < 6) {
            uuids << this->getNextUuidForStandby();
        }
        while (this->m_battlefieldBlocks.keys().length() < 6) {
            this->m_battlefieldBlocks[this->getNextAvailableIdForDeploymentToBattlefield()] = this->m_standbyBlocks.value(this->m_standbyBlocks.keys().first());

            this->m_standbyBlocks.remove(this->m_standbyBlocks.keys().first());
            this->organizeStandbyQueue();
        }

        this->organizeBattlefieldQueue();
        foreach (int key, this->m_battlefieldBlocks.keys()) {
            BlockCPP* blk = this->getBlockFromUuid(m_battlefieldBlocks.value(key, ""));
            if (blk != nullptr) {
                blk->m_row = key;
            }
        }
        this->m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(true, true, true));
        foreach (QString uuid, uuids) {
            this->m_engine->showBlock(uuid);
        }
    }
}

qint64 BlockQueue::getCurrentTimestamp()
{
    return QDateTime::currentMSecsSinceEpoch();
}

void BlockQueue::startPerfTimer()
{
    this->startDebugTime = this->getCurrentTimestamp();

}

void BlockQueue::stopPerfTimer(QString prependToOutput)
{
    this->endDebugTime = this->getCurrentTimestamp();
    qDebug() << prependToOutput << this->endDebugTime - this->startDebugTime << "ms";
}
