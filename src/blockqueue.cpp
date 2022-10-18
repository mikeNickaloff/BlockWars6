#include "blockqueue.h"
#include "blockcpp.h"
#include "blockprocessor.h"
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

        this->m_standbyBlocks[this->getNextAvailableIdForStandby()] =  uuid;



        this->m_standbyNextAssignmentIndex++;
        if (this->m_standbyNextAssignmentIndex >= this->m_assignedBlocks.keys().length()) {
            this->m_standbyNextAssignmentIndex = 0;
        }
        return uuid;
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
    if (m_battlefieldBlocks.values().contains(uuid)) {
        return m_battlefieldBlocks.key(uuid);
    }
    return -1;
}

bool BlockQueue::isBattlefieldRowEmpty(int row_num)
{
    if (!this->m_battlefieldBlocks.keys().contains(row_num)) { return true; }
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
    for (int i=0; i<6; i++) {
        if (this->isBattlefieldRowEmpty(i)) { return true; }
    }
    return false;
}

QList<QString> BlockQueue::getBlocksWithMissionFromHash(QHash<int, QString> ihash, BlockCPP::Mission imission)
{
    QList<QString> rv;
    foreach (QString str, ihash.values()) {
        BlockCPP* blk = this->getBlockFromUuid(str);
        if (blk != nullptr) {
            if (blk->m_mission == imission) {
              rv << blk->m_uuid;
            }
        }

    }
    return rv;
}

bool BlockQueue::areBattlefieldBlocksMissionsComplete()
{
    bool allComplete = true;

    foreach (QString str, m_battlefieldBlocks.values()) {
        BlockCPP* blk = this->getBlockFromUuid(str);
        if (blk != nullptr) {
            if (blk->m_missionStatus != BlockCPP::MissionStatus::Complete) {
                allComplete = false;
                return allComplete;
            }
        }

    }
    return allComplete;
}

void BlockQueue::assignBlockToQueue(QString uuid)
{

   this->m_standbyBlocks[getNextAvailableIdForStandby()] = uuid;





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
        m_engine->reportBlockPosition(uuid, row, blk->m_column);
    }

}



void BlockQueue::setQueueMission(BlockQueue::Mission mission)
{

    if (m_column == 3) {
    this->startPerfTimer();
    }
    //qDebug() << "Set mission for" << m_column << "to" << this->convertMissionToString(mission);
    this->mutexLocked = true;
    this->m_mission = mission;
    this->m_missionStatus = BlockQueue::Started;
    if (this->m_mission == BlockQueue::Mission::PrepareStandby) {

        this->startStandbyMission();
    }
    if (this->m_mission == BlockQueue::Mission::DeployToBattlefield) {
        this->startDeploymentMission();
        
    }
    if (this->m_mission == BlockQueue::Mission::ReadyFiringPositions){
        this->startReadyFiringPositionsMission();
    }
    if (this->m_mission == BlockQueue::Mission::IdentifyTargets) {
        this->foundAttackers = false;
         this->launchedBlocksThisMission = false;
        this->startIdentifyTargetsMission();
    }

    if (this->m_mission == BlockQueue::Mission::AttackTargets) {



        this->startAttackMission();

    }
    if (this->m_mission == BlockQueue::Mission::MoveRanksForward) {
        this->startMoveRanksForwardMission();
    }

    if (this->m_mission == BlockQueue::Mission::Defense) {

      this->startDefenseMission();
    //  organizeBattlefieldQueue();

    }
    if (this->m_mission == BlockQueue::Mission::WaitForOrders) {

    }
    if (this->m_mission == BlockQueue::Mission::WaitForNetworkResponse) {

    }
    if (m_column == 3) {
    this->stopPerfTimer(QString("%4 -- queue #%1 -- mission %2 -- checkCurrentMission -- ").arg(m_column).arg(this->convertMissionToString(this->m_mission)).arg(m_engine->m_orientation));
    }

    this->mutexLocked = false;
     //   checkCurrentMission();
}
void BlockQueue::startStandbyMission()
{


   // organizeStandbyQueue();
    QList<QString> vals;
    vals << this->m_standbyBlocks.values();
int u = 0;
    foreach (QString str, vals) {
        m_engine->hideBlock(str);

        m_engine->reportBlockPosition(str, 20, m_column);
        BlockCPP* blk = this->getBlockFromUuid(str);
        if (blk != nullptr) {
            blk->m_mission = BlockCPP::Standby;
        }
        u++;


    }


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




    //this->m_missionStatus = BlockQueue::MissionStatus::Complete;


}





void BlockQueue::startDeploymentMission()
{
    BlockProcessor* processor = new BlockProcessor(this);
    processor->setHashTable(m_battlefieldBlocks);
    processor->reIndexHashTableToFront();
    m_battlefieldBlocks.clear();
    m_battlefieldBlocks.insert(processor->getHashTable());
    //organizeStandbyQueue();
    //organizeBattlefieldQueue();



//    BlockProcessor* processor = new BlockProcessor(this);
    processor->setFromTable(this->m_standbyBlocks);
    processor->setToTable(this->m_battlefieldBlocks);
    int keysLen = this->m_battlefieldBlocks.keys().length();
    while (keysLen < 6) {
        processor->transferItemFirstToFront();

        keysLen++;
    }

    this->m_battlefieldBlocks.clear();
    this->m_standbyBlocks.clear();
    this->m_battlefieldBlocks.insert(processor->getToTable());
    this->m_standbyBlocks.insert(processor->getFromTable());
    //qDebug() << m_battlefieldBlocks.keys() << m_battlefieldBlocks.values();
    //qDebug() << this->m_standbyBlocks.keys() << this->m_standbyBlocks.values();
//    organizeStandbyQueue();
    organizeBattlefieldQueue();
    foreach (QString uuid, this->m_battlefieldBlocks.values()) {
        BlockCPP* blk = this->getBlockFromUuid(uuid);
        if (blk != nullptr)  {
            blk->m_row = this->m_battlefieldBlocks.key(uuid);
            blk->m_mission = BlockCPP::Mission::Deploy;
            blk->m_missionStatus = BlockCPP::MissionStatus::Started;
            m_engine->showBlock(uuid);
            m_engine->reportBlockPosition(blk->m_uuid, blk->m_row, m_column);

        }
    }
   // m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(true, true, false));
     //this->m_missionStatus = BlockQueue::MissionStatus::Complete;

}

void BlockQueue::organizeStandbyQueue()
{
    int id =  0;
   // int last = this->getNextAvailableIdForStandby() - 1;
   // QLinkedList<QString> uuids;
    BlockProcessor* processor = new BlockProcessor(this);
    processor->setHashTable(this->m_standbyBlocks);
    processor->reIndexHashTableToFront();
    this->m_standbyBlocks.clear();
    this->m_standbyBlocks.insert(processor->getHashTable());
    foreach (QString uuid, m_standbyBlocks.values()) {
        m_engine->hideBlock(uuid);
    }

}

void BlockQueue::organizeReturningQueue()
{

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
    BlockProcessor* processor = new BlockProcessor(this);

    processor->setFromTable(m_standbyBlocks);
    processor->setToTable(m_battlefieldBlocks);
    while (processor->getToTable().keys().length() < 6) {
        processor->transferItemFirstToFront();
    }
    processor->setHashTable(processor->getToTable());
    processor->reIndexHashTableToFront();

    m_battlefieldBlocks.clear();
    m_standbyBlocks.clear();
    m_battlefieldBlocks.insert(processor->getHashTable());
    m_standbyBlocks.insert(processor->getFromTable());



//    setBlockRow(this->m_battlefieldBlocks.value(key), key);
        //int lastId = this->getNextAvailableIdForDeploymentToBattlefield();

    for (int i=0; i<6; i++) {
        BlockCPP* blk = this->getBlockFromUuid(this->m_battlefieldBlocks.value(i, nullptr));
        if (blk != nullptr) {
            blk->m_row = i;
            blk->m_mission = BlockCPP::Deploy;
            blk->m_missionStatus = BlockCPP::MissionStatus::Started;
            // block 5 has no block above , otherwise set it
            if (i != 5) {
                blk->m_uuidRowAbove = this->m_battlefieldBlocks.value(i + 1, "");
            }
            // block 0 has no block below , otherwise set it
            if (i != 0) {
                blk->m_uuidRowBelow = this->m_battlefieldBlocks.value(i - 1, "");
            }
             m_engine->showBlock(blk->m_uuid);
             m_engine->reportBlockPosition(blk->m_uuid, blk->m_row, m_column);

        } else {
            m_battlefieldBlocks.remove(i);
            organizeBattlefieldQueue();
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

        checkCurrentMission2();
        return;


    //  organizeBattlefieldQueue();
}

void BlockQueue::checkCurrentMission2()
{
    bool allComplete = this->areBattlefieldBlocksMissionsComplete();
    if (allComplete) {


        if (this->m_mission == BlockQueue::Mission::PrepareStandby) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }


        if (this->m_mission == BlockQueue::DeployToBattlefield) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }

        if (this->m_mission == BlockQueue::Mission::ReadyFiringPositions) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }
        if (this->m_mission == BlockQueue::Mission::IdentifyTargets) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }
        if (this->m_mission == BlockQueue::Mission::AttackTargets) {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }



    }
    if (!allComplete) {
        if (this->m_mission == BlockQueue::PrepareStandby) {
            /* waiting for blocks to finish launching / moving / exploding */
            return;
        }
        if (this->m_mission == BlockQueue::DeployToBattlefield) {
            /* waiting for blocks to to drop in to their final positions, ready to match */
            this->m_missionStatus = BlockQueue::MissionStatus::Started;
            return;
        }
        if (this->m_mission == BlockQueue::ReadyFiringPositions) {
            /* waiting for matching to complete */
            return;
        }
        if (this->m_mission == BlockQueue::Mission::AttackTargets) {
            /* waiting for launching / exploding to complete */
            return;
        }
        if (this->m_mission == BlockQueue::Mission::Defense) {
            // while on defense, hide blocks that are dead
            this->hideBlocksWithNoHealth();
            return;
        }
    }
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
            m_engine->showBlock(uuid);
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


      //      m_engine->showBlock(blk->m_uuid);
        }
    }

    // up down left right ready for all battlefield blocks
    // inform the game engine that we are ready

    //this->m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(true, true, false));


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
                        blk->m_mission = BlockCPP::Mission::Matched;
                        blk->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        above->m_mission = BlockCPP::Mission::Matched;
                        above->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        below->m_mission = BlockCPP::Mission::Matched;
                        below->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                    }
                }
            }



            if ((left != nullptr) && (right != nullptr)) {
                if (left->m_color == right->m_color) {
                    if (left->m_color == blk->m_color) {
                        blk->m_mission = BlockCPP::Mission::Matched;
                        blk->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        left->m_mission = BlockCPP::Mission::Matched;
                        left->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                        right->m_mission = BlockCPP::Mission::Matched;
                        right->m_missionStatus = BlockCPP::MissionStatus::NotStarted;
                    }
                }
            }
            if (blk->m_mission != BlockCPP::Mission::Matched) {
                blk->m_mission = BlockCPP::HoldFire;
            }
            blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
        }
    }


    //this->m_missionStatus = BlockQueue::MissionStatus::Complete;



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
    for (int i=0; i<19; i++) {
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
    int i;
    if (m_standbyBlocks.keys().length() == 0) {
        i = 0;
    } else {
     i = m_standbyBlocks.keys().last();
    }
    while (m_standbyBlocks.keys().contains(i)) {
        i++;
    }
    if (m_standbyBlocks.values().contains(uuid)) { return; }
    this->m_standbyBlocks[i] = uuid;
    BlockCPP* blk = this->getBlockFromUuid(uuid);
    if (blk != nullptr) {
        blk->m_mission = BlockCPP::Mission::Standby;
        m_engine->hideBlock(blk->m_uuid);
    }

}



void BlockQueue::startIdentifyTargetsMission()
{
    bool hasAttackers = false;
    bool mustReset = false;
    for (int i=0; i<6; i++) {
        BlockCPP* blk = getBlockFromUuid(this->m_battlefieldBlocks.value(i));
        if (blk != nullptr) {
            if (blk->m_mission == BlockCPP::Mission::Matched) {

                hasAttackers = true;

                if (this->m_battlefieldBlocks.values().contains(blk->m_uuid)) {
                    int key = m_battlefieldBlocks.key(blk->m_uuid);
                    //m_battlefieldBlocks.remove(key);
                }
                blk->targetIdentified = false;
                blk->m_missionStatus = BlockCPP::MissionStatus::Started;
                mutexLocked = false;
                launchedBlocksThisMission = true;
                m_engine->reportMatchingBlockNeedTarget(blk->m_uuid, blk->m_row, blk->m_column, blk->m_health);
               // QTimer::singleShot(100 * (6 - blk->m_row) + (50) , [this, blk]() {  m_engine->startLaunchAnimation(blk->m_uuid); } );
              //  QTimer::singleShot(200 * (6) + (50) , [this]() {  this->mutexLocked = false; this->m_missionStatus = BlockQueue::MissionStatus::Complete; } );
               // this->m_standbyBlocks[this->getNextAvailableIdForStandby()] = blk->m_uuid;
                //m_engine->startLaunchAnimation(blk->m_uuid);


            }

            if (blk->m_mission == BlockCPP::Mission::HoldFire) {
                blk->m_missionStatus = BlockCPP::MissionStatus::Complete;
            }
        }

    }
    foundAttackers = hasAttackers;

  //  this->m_missionStatus = BlockQueue::MissionStatus::Complete;
}

void BlockQueue::startAttackMission()
{
   // this->m_missionStatus = BlockQueue::MissionStatus::Started;
    bool stillgoing = false;
    foreach (QString uuid, this->m_battlefieldBlocks.values()) {
     BlockCPP* blk = this->getBlockFromUuid(uuid);
     if (blk != nullptr) {
      if (blk->m_mission == BlockCPP::Matched) {
          blk->m_mission = BlockCPP::Attacking;
          blk->m_missionStatus = BlockCPP::MissionStatus::Started;
          QTimer::singleShot(100 * (6 - blk->m_row) + (50) , [this, blk]() {  m_engine->startLaunchAnimation(blk->m_uuid); } );
      }
     }


    }
    if (!stillgoing) {
        this->m_missionStatus = BlockQueue::MissionStatus::Complete; mutexLocked = false;
    } else {
        this->m_missionStatus = BlockQueue::MissionStatus::Started; mutexLocked = false;
    }





    //this->m_missionStatus = BlockQueue::MissionStatus::Complete;
}

void BlockQueue::startMoveRanksForwardMission()
{

    if (!m_engine->isOffense) { this->m_missionStatus = BlockQueue::MissionStatus::Complete; }
    if (m_column == 3) {
        //qDebug() << "Moving blocks forward in column 3";

    }
    QList<int> bfk;
    bfk << this->m_battlefieldBlocks.keys();
    foreach (int i, bfk) {
        QString uuid = this->m_battlefieldBlocks.value(i);
        BlockCPP* blk = this->getBlockFromUuid(uuid);
        m_engine->hideBlock(uuid);
        if (blk != nullptr) {
            if (blk->m_mission == BlockCPP::Mission::Attacking) {
                blk->m_mission = BlockCPP::Standby;
                blk->m_missionStatus = BlockCPP::MissionStatus::Started;
                blk->m_row = -20;
                m_battlefieldBlocks.remove(i);
                m_standbyBlocks[getNextAvailableIdForStandby()] = uuid;
            }




        }
    }

    organizeStandbyQueue();

    if (hasBlanks()) {
       // organizeBattlefieldQueue();
        qDebug() << "MOVE BLOCKS FORWARD BEFORE PROCESSING" << this->m_battlefieldBlocks.keys() << this->m_battlefieldBlocks.values();
        /* BlockProcessor* processor = new BlockProcessor(this);
        processor->setHashTable(m_battlefieldBlocks);
        processor->reIndexHashTableToFront();
        this->m_battlefieldBlocks.clear();
        this->m_battlefieldBlocks.insert(processor->getHashTable()); */
          organizeBattlefieldQueue();
        qDebug() << "MOVE BLOCKS FORWARD RESULT" << this->m_battlefieldBlocks.keys() << this->m_battlefieldBlocks.values();


        m_engine->didMoveForward = true;
        if (hasBlanks()) {
            this->m_missionStatus = BlockQueue::MissionStatus::Failed;
        } else {
            this->m_missionStatus = BlockQueue::MissionStatus::Complete;
        }
    } else {

        this->m_missionStatus = BlockQueue::MissionStatus::Complete;
    }
    /*int battlefieldBlockCount = 0;
    int movementOffset = 0;
    bool foundBlank = false;
    bool isCompact = true;
    for(int i=0; i<6; i++) {
        if (this->isBattlefieldRowEmpty(i)) {
            if (m_column == 3) {
                //   qDebug() << "row " << i << "is empty";

            }
           // this->m_battlefieldBlocks.remove(i);
        foundBlank = true;

            m_engine->shouldRefillThisLoop = true;

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
    */
}

void BlockQueue::hideBlocksWithNoHealth()
{

    for (int i=0; i<6; i++) {
        BlockCPP* blk = m_engine->getBlockByUuid(this->m_battlefieldBlocks.value(i));
        if (blk != nullptr) {
            if (blk->m_health <= 0) {
               // this->m_battlefieldBlocks.remove(i);
                m_engine->hideBlock(blk->m_uuid);
                this->m_standbyBlocks[this->getNextAvailableIdForStandby()] = blk->m_uuid;
                blk->m_mission = BlockCPP::Standby;
                m_engine->reportBlockPosition(blk->m_uuid, 20, blk->m_column);
            }
            if (blk->m_mission == BlockCPP::Dead) {
                if (!blk->m_hidden) { m_engine->hideBlock(blk->m_uuid);  }
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
       this->setQueueMission(BlockQueue::Mission::PrepareStandby);
}



void BlockQueue::startDefenseMission()
{


    hideBlocksWithNoHealth();
    this->organizeStandbyQueue();
    foreach (QString uuid, this->m_standbyBlocks.values()) {
       BlockCPP* blk = this->getBlockFromUuid(uuid);
       if (blk != nullptr) {
           m_engine->hideBlock(blk->m_uuid);
           blk->m_row = 20;
       }

    }
    this->organizeBattlefieldQueue();
        this->m_standbyNextAssignmentIndex = 0;
        QList<QString> uuids;
        BlockProcessor* processor = new BlockProcessor(this);
        processor->setFromTable(this->m_standbyBlocks);
        processor->setToTable(this->m_battlefieldBlocks);
        while (this->m_battlefieldBlocks.keys().length() < 6) {
            processor->transferItemFirstToFront();
            m_battlefieldBlocks.clear();
            m_battlefieldBlocks.insert(processor->getToTable());

            this->m_standbyBlocks.clear();
            this->m_standbyBlocks.insert(processor->getFromTable());
            //this->organizeStandbyQueue();
        }

        this->organizeBattlefieldQueue();
        foreach (int key, this->m_battlefieldBlocks.keys()) {
            BlockCPP* blk = this->getBlockFromUuid(m_battlefieldBlocks.value(key));
            if (blk != nullptr) {
                blk->m_row = key;
                m_engine->reportBlockPosition(blk->m_uuid, blk->m_row, m_column);
                m_engine->showBlock(blk->m_uuid);
            }
        }
      //  this->m_engine->handleReportedBattlefieldStatus(m_column, this->serializeBattlefield(true, true, true));

        foreach (QString uuid, uuids) {

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
