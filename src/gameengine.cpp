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
GameEngine::GameEngine(QObject *parent, QString orientation)
    : QObject{parent}
{
    m_orientation = orientation;
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
    this->numberLaunched = 0;
    this->launchTimer = new QTimer(this);
    this->connect(launchTimer, SIGNAL(timeout()), this, SLOT(launchNext()));
    this->matchTimer = new QTimer(this);
    this->connect(matchTimer, SIGNAL(timeout()), this, SLOT(matchNextRow()));


}

QVariantList GameEngine::getBlocksByColumn(int column)
{
    QQueue<QString> stack = this->m_stacks.value(column);
    QQueue<QString> newStack;
    QVariantList uuids;
    while (!stack.isEmpty()) {
        uuids <<stack.dequeue();
    }

    return uuids;

}

QVariantList GameEngine::getStack(int column)
{
//    qDebug() << "getStack(" << column << "returned" << getBlocksByColumn(column) << "from stack" << this->m_stacks.value(column);
    return getBlocksByColumn(column);
}

QVariantList GameEngine::getQueue(int column)
{
    QQueue<QString> queue = this->m_queues.value(column);

    QVariantList queueUuids;
    while (!queue.isEmpty()) {
        queueUuids << queue.dequeue();
    }
    return queueUuids;


}

QVariantList GameEngine::getMatchingBlocks()
{

}

QStringList GameEngine::getStackRow(int row_num)
{
    QStringList rv;
    for (int i=0; i<6; i++) {
        QStringList col = getStackColumn(i);
        if (col.length() > row_num) {
            rv << col.at(row_num);
        } else {

            qDebug() << "getStackRow() failure -- couldnt find row number" << row_num << "from column" << i;

            /*QQueue<QString> queue = m_queues.value(i, QQueue<QString>());
            if (!queue.isEmpty()) {
                rv << queue.dequeue();
            } else {
                rv << "";
            } */
            rv << "";
        }
    }
    return rv;
}

QStringList GameEngine::getStackColumn(int col_num)
{
    QStringList rv;
    QVariantList list;
    list << this->getStack(col_num);


    for (int i=0; i<list.count(); i++) {
        rv << list.at(i).toString();
    }
 //   qDebug() << "getStackColumn" << col_num << "got" << list << "and will return" << rv;
    return rv;

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

bool GameEngine::isBlockInLaunchQueues(QString uuid)
{
    if (this->m_postLaunch.contains(uuid)) { return true; }
    if (this->m_preLaunch.contains(uuid)) { return true; }
    return false;
}

QQueue<QString> GameEngine::filterUuidFromStack(QString uuid, QQueue<QString> stack, bool compactResults = true)
{

    QQueue<QString> newStack;
    QQueue<QString> oldStack(stack);
    QQueue<QString> returnedStack;
    while (!oldStack.isEmpty()) {
        QString val = oldStack.dequeue();
        if (val != uuid) {
            newStack.enqueue(val);
        } else {
            if (compactResults == false) {
                newStack.enqueue("");
            } else {
                continue;
            }
        }
    }

    return newStack;

}

QQueue<QString> GameEngine::filterUuidFromQueue(QString uuid, QQueue<QString> queue)
{
    QQueue<QString> oldQueue(queue);
    QQueue<QString> newQueue;
    while (!oldQueue.isEmpty()) {
        QString val = oldQueue.dequeue();
        if (val != uuid) {
            newQueue.enqueue(val);
        }
    }
    return newQueue;
}

QQueue<QString> GameEngine::insertUuidIntoStack(QString uuid, int position, QQueue<QString> stack)
{
    int currentPosition = 0;
    qDebug() << "inserting uuid" << uuid << "at position" << position << "into" << stack;
    QQueue<QString> newStack;
    QQueue<QString> oldStack;
    while (!stack.isEmpty()) {
        oldStack.enqueue(stack.dequeue());
    }
    QQueue<QString> returnedStack;
    bool didInsert = false;
    if (position < 0) {
        newStack.enqueue(uuid);
        didInsert = true;
    }
    while (!oldStack.isEmpty()) {

        if (position == currentPosition) {

            newStack.enqueue(uuid);
            didInsert = true;
        } else {
            QString val = oldStack.dequeue();
            newStack.enqueue(val);
        }
        currentPosition++;
    }

    if (position >= currentPosition) {
        if (didInsert == false) {
            newStack.enqueue(uuid);
        }
    }
    qDebug() << "After Insert Result" << newStack;
    return newStack;

}

qint64 GameEngine::getUuidPositionInStack(QString uuid, QQueue<QString> stack)
{
qDebug() << "looking for uuid position of" << uuid << "from" << stack;
    QQueue<QString> newStack;
    QQueue<QString> oldStack;
    oldStack = stack;
    int currentPosition = -1;
    QQueue<QString> returnedStack;
    while (!oldStack.isEmpty()) {
        currentPosition++;
        QString val = oldStack.dequeue();
        if (val == uuid) {
            qDebug() << "Result: " << currentPosition;
            return currentPosition;
        }

    }

    // qDebug() << "Could not find Uuid" << uuid << "in arbitrary stack" << stack.toList();
    return -1;
}

void GameEngine::createBlockCPP(QString uuid, QString color, int column, int row, int health)
{
    this->new_block = new BlockCPP(this, uuid);
    this->new_block->m_color = color;
    m_blocks[uuid] = new_block;
    if ((row > 5) || (row < 0)) {
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


}

void GameEngine::removeBlock(QString uuid, int column)
{
    qDebug() << "Received request to remove" << uuid << "from" << column;

    int blocksChecked = 0;
    int blocksRemoved = 0;
    QQueue<QString> stack = m_stacks.value(column);
    QQueue<QString> queue = m_queues.value(column);
    QQueue<QString> newQueue;
    QQueue<QString> newStack;
    while (!stack.empty()) {
        QString chkUuid = stack.dequeue();
        if (blocksChecked > 6) {
            newQueue.enqueue(chkUuid);
            continue;
        }
        if (chkUuid == uuid) {
            // do nothing intentionally as we want to remove the block from the stack


            newQueue.enqueue(chkUuid);
            blocksRemoved++;

        } else {
            newStack.enqueue(chkUuid);

        }


    }
    int numToQueue = blocksRemoved;



    for (int a=0; a<numToQueue; a++) {
        if (!newQueue.isEmpty()) {
            QString str = newQueue.dequeue();
            newStack.enqueue(str);
        }
    }
    m_stacks[column] = newStack;
    m_queues[column] = newQueue;
    emit this->signalStackUpdated(column, getStack(column));
    emit this->signalQueueUpdated(column, getQueue(column));


}

void GameEngine::swapBlocks(QString uuid1, QString uuid2)
{
    int uuid_col1 = -1;
    int uuid_col2 = -1;
    int uuid_row1 = -1;
    int uuid_row2 = -1;
    for (int i=0; i<6; i++) {
        bool modified = false;
        QQueue<QString> stack = this->m_stacks.value(i);
        int uuid1_pos = getUuidPositionInStack(uuid1, stack);
        int uuid2_pos = getUuidPositionInStack(uuid2, stack);

        if (uuid1_pos > -1) { uuid_col1 = i; uuid_row1 = uuid1_pos; }
        if (uuid2_pos > -1) { uuid_col2 = i; uuid_row2 = uuid2_pos; }


    }
    if ((uuid_col1 > -1) && (uuid_col2 > -1)) {
        QQueue<QString> newStack1;
        QQueue<QString> newStack2;
        QQueue<QString> oldStack1 =  this->filterUuidFromStack(uuid1, this->m_stacks.value(uuid_col1), true);
        QQueue<QString> oldStack2 =  this->filterUuidFromStack(uuid2, this->m_stacks.value(uuid_col2), true);
        if (uuid_col1 == uuid_col2) {
            newStack1 = insertUuidIntoStack(uuid2, uuid_row1, oldStack1);
            newStack2 = insertUuidIntoStack(uuid1, uuid_row2, newStack1);
            m_stacks[uuid_col2] = newStack2;
            emit this->signalStackUpdated(uuid_col2, getStack(uuid_col2));
        } else {
            newStack1 = insertUuidIntoStack(uuid2, uuid_row1, oldStack1);
            newStack2 = insertUuidIntoStack(uuid1, uuid_row2, oldStack2);

            m_stacks[uuid_col1] = newStack1;
            m_stacks[uuid_col2] = newStack2;
            emit this->signalStackUpdated(uuid_col1, getStack(uuid_col1));
            emit this->signalStackUpdated(uuid_col2, getStack(uuid_col2));
        }

    }


}

void GameEngine::launchBlock(QString uuid)
{

    for (int i=0; i<6; i++) {
        bool modified = false;
        QQueue<QString> stack = this->m_stacks.value(i);
        QQueue<QString> newStack;
        if (getUuidPositionInStack(uuid, stack) > -1) {
            if (uuid == "") { continue; }

            //m_preLaunch.enqueue(uuid);
            m_afterLaunchColumns[uuid] = i;
            newStack = filterUuidFromStack(uuid, stack, true);
            while (newStack.count() < 6) {
                QQueue<QString> queue = this->m_queues.value(i);
                QString val = queue.dequeue();
                newStack.enqueue(val);
                m_queues[i] = queue;
            }
            modified = true;
        }




        if (modified) {
            qDebug() << "launch block modified stack and queue" << uuid << getBlockByUuid(uuid)->m_color;

            m_stacks[i] = newStack;
            emit this->signalQueueUpdated(i, getQueue(i));
            emit this->signalStackUpdated(i, getStack(i));
            //completeLaunch(uuid);



        }

    }
}

void GameEngine::completeLaunch(QString uuid, int column)
{
    numberLaunched--;
    QQueue<QString> queue = filterUuidFromQueue(uuid, m_queues.value(column));
    qDebug() << "+++++ Launch Completed" << uuid << "from column" << column << "num launched" << numberLaunched;
    queue.enqueue(uuid);
    m_queues[column] = queue;
    emit this->signalQueueUpdated(column, getQueue(column));
    emit this->signalStackUpdated(column, getStack(column));


    if (numberLaunched <= 0) {
        launchTimer->stop();
        current_matcher_row = 0;
        qDebug() << "all blocks requeued from launch";
        bool dropped = false;
        for (int i=0; i<6; i++) {
            bool check = dropColumnDown(0, column);
            if (check) { dropped = true; }

        }

        if (gotMatchThisRound) {

            this->m_preLaunch.clear(); this->m_matchList.clear();
            emit this->signalFinishedMatchChecking(true);
        } else {
            this->m_preLaunch.clear(); this->m_matchList.clear();
            emit this->signalFinishedMatchChecking(false);
        }



    }

    //if (this->m_preLaunch.count() == 0) {


}









bool GameEngine::compactBlocks(qint64 column)
{
    bool didChange = false;
    QQueue<QString> stack = this->m_stacks.value(column);
    QQueue<QString> queue = this->m_queues.value(column);
    while (stack.length() < 6) {
        if (!queue.isEmpty()) {
            QString newUuid = queue.dequeue();
            if (newUuid != "") {
                stack.enqueue(newUuid);
                didChange = true;
            } else {

            }
        } else {
            qDebug() << "Compact failure";
            break;
        }
    }


    m_stacks[column] = stack;
    m_queues[column] = queue;
    // emit this->signalQueueUpdated(column, getQueue(column));
    // emit this->signalStackUpdated(column, getStack(column));
    return didChange;
}

void GameEngine::checkMatches()
{
    gotMatchThisRound = false;
    if (this->launchTimer->isActive()) {
        launchTimer->stop();
        // checkMatches();
        //QTimer::singleShot(50, this, SLOT(checkMatches()));
    } else {

    }
    this->current_matcher_row = 0;
    this->matchTimer->start(20);


}

QList<QString> GameEngine::checkUuidsForMatches(QList<QString> uuids)
{
    QList<QString> launchList;
    QStringList colorList;
    colorList << "red" << "green" << "blue" << "yellow";
    QStringList colors = getColorsByUuids(uuids);
    QString color_row = colors.join(",");
    foreach (QString colorListItem, colorList) {
        for (int a=0; a<6; a++) {
            QVector<QString> testList;
            testList.fill(colorListItem, a + 1);
            QString testStr = "";
            int numAdded = 0;
            foreach (QString testItem, testList) {
                testStr.append(testItem);
                numAdded++;
                if (numAdded < (a - 1)) {
                    testStr.append(",");
                }

            }

            if (color_row.indexOf(testStr) > -1) {
                QList<BlockCPP*> blocks = getBlocksFromUuids(uuids);
                QList<QString> sequential_matching_uuids;
                QList<QString> best_sequential_matching_uuids;
                int num_seq = 0;
                int best_seq = 0;
                for (int b=0; b<blocks.count(); b++) {
                    if (blocks.at(b) == nullptr) { continue; }
                    if (blocks.at(b)->m_color == colorListItem) {
                        num_seq++;
                        sequential_matching_uuids << blocks.at(b)->m_uuid;
                        if (num_seq > best_seq) {
                            best_sequential_matching_uuids = sequential_matching_uuids.toVector().toList();
                            best_seq = num_seq;

                        }
                    } else {
                        num_seq = 0;
                        sequential_matching_uuids.clear();
                    }

                }
                if (best_seq >= 3) {
                    foreach (QString t_uuid, best_sequential_matching_uuids) {
                        if (!this->m_matchList.contains(t_uuid)) {
                            m_matchList << t_uuid;
                            gotMatchThisRound = true;
                        }
                    }
                }
            }


        }
    }
    return launchList;

}

bool GameEngine::FindMatches(int row_or_column, bool is_row = false)
{

    QList<QString> matching;
    QList<QString> uuids;
    if (is_row) {
        if (row_or_column > 5) { return false; }
        uuids << this->getStackRow(row_or_column);


    } else {
        uuids << this->getStackColumn(row_or_column);
    }
    if (uuids.length() == 0) { return false; }

    matching << this->checkUuidsForMatches(uuids);
    //qDebug() << "checking" << uuids << "For matches" << "found" << matching;
    if (matching.length() > 0)  {


        foreach (QString str, matching) {
            if (!this->m_matchList.contains(str)) {
                if (!this->m_preLaunch.contains(str)) {
                    m_matchList << str;
                    qDebug() << "matchList is now" << this->m_matchList;
                }
            }
        }
        return true;

        //  qDebug() << "matcher row is" << this->current_matcher_row;



    } else {
        if ((row_or_column >= 6) && (is_row == false)) {


            // no matches after checking all columns -- start launch
            //   this->slot_beginLauchSequence(this->m_matchList);
            //  this->m_matchList.clear();
            //  matchTimer->stop();
            return false;
        }
        if (is_row == true) {
            return false;

        }
    }

    return false;
}

void GameEngine::runTimedMatchLauncher()
{
    /*   matcherRunning = true;
    bool madeChanges = false;
   for (int i=0; i<6; i++) {
       bool rowChanges = false;
       QStringList row = getStackRow(i);
       while (row.length() < 6) {

           for (int u=0; u<row.length(); u++) {

               bool rv = dropColumnDown(0, u);
               if (rv == false) {
                   continue;
               } else {
                  rowChanges = true;
                  matcherRunning = true;


               }
           }
           row.clear();
           row = getStackRow(i);

       }
       if (rowChanges) { madeChanges = true; }
   }
   if (!madeChanges) {
       bool gotMatch = this->checkMatches();
       if (!gotMatch) {
           matcherRunning = false;
           QTimer::singleShot(200, this, SLOT(checkAndReportMatcherStatus()));
         //  emit this->signalFinishedMatchChecking(false);
           //QTimer::singleShot(40, this, SLOT(runTimedMatchLauncher()));
       } else {
           matcherRunning = true;
               //emit this->signalFinishedMatchChecking(true);
           QTimer::singleShot(20, this, SLOT(runTimedMatchLauncher()));
           return;
       }

   } else {
       matcherRunning = true;
           //emit this->signalFinishedMatchChecking(true);
      runTimedMatchLauncher();

   } */
}

bool GameEngine::dropColumnDown(int startingRow, int column)
{
    bool modified = false;
    QList<QString> uuids;
    uuids << this->getStackColumn(column);
    QQueue<QString> newStack = this->filterUuidFromStack("", this->m_stacks.value(column, QQueue<QString>()), true);


    QList<QString> testUuids;
    testUuids << this->getStackColumn(column);
    while (testUuids.length() < 6) {
        QQueue<QString> queue = this->m_queues.value(column);
        if (!queue.isEmpty()) {

            QString newUuid = queue.dequeue();
            if (newUuid == "") { continue; }
            testUuids << newUuid;
            newStack.enqueue(newUuid);
            modified = true;
            m_queues[column] = queue;
        } else {
            qDebug() << "failure dropping column down for column" << column << "queue is empty";
            return false;


        }
    }
    if (modified) {
        this->m_stacks[column] = newStack;
        emit this->signalStackUpdated(column, getStack(column));
        return true;
    } else {
        return false;
    }


}

void GameEngine::checkAndReportMatcherStatus()
{
    if (matcherRunning) {
        // this->runTimedMatchLauncher();
    } else {
        // emit this->signalFinishedMatchChecking(false);
    }
}

void GameEngine::launchNext()
{
    if (!this->m_preLaunch.empty()) {
        QString str = m_preLaunch.dequeue();
        numberLaunched++;
        emit this->beginLaunchSequence(str);
        for (int i=0; i<6; i++) {
            QQueue<QString> stack = m_stacks.value(i);
            QQueue<QString> newStack = filterUuidFromStack(str, stack, true);
            this->m_stacks[i] = newStack;

            QQueue<QString> queue = m_queues.value(i);
            QQueue<QString> newQueue = filterUuidFromQueue(str, queue);
            this->m_queues[i] = newQueue;
            //  emit this->signalStackUpdated(i, getStack(i));
        }
    } else {
        qDebug() << "No more launches -- compact blocks";
        launchTimer->stop();
        matchTimer->stop();
        for (int i=0; i<6; i++) {
            this->dropColumnDown(0, i);
        }
        //emit this->signalFinishedMatchChecking(true);
        // check matches
        //     this->checkMatches();
    }
}

void GameEngine::slot_beginLauchSequence(QStringList uuids)
{
    foreach (QString uuid, uuids) {
        if (!m_preLaunch.contains(uuid)) {
            m_preLaunch.enqueue(uuid);
        }
    }

    if (!this->launchTimer->isActive()) {
       // this->numberLaunched = 0;
        this->launchTimer->start(200);
        this->matchTimer->stop();
    }
}

void GameEngine::matchNextRow()
{
  //  this->m_matchList.clear();
    if (this->current_matcher_row >= 6) {
        this->current_matcher_row = 0;
        if (this->m_matchList.count() > 0) {
            this->slot_beginLauchSequence(this->m_matchList);
            this->m_matchList.clear();
            matchTimer->stop();
        } else {
            matchTimer->stop();
            emit this->signalFinishedMatchChecking(false);
        }
    }

    bool foundMatch = this->FindMatches(current_matcher_row, true);




    qDebug() << "matchNextRow result" << foundMatch << current_matcher_row;
    this->current_matcher_row++;


    if (current_matcher_row > 5) {

    bool foundColumns = false;
    if (this->current_matcher_row >= 6) {
        for (int i=0; i<6; i++) {
            if (this->FindMatches(i, false)) {
                foundColumns = true;
            }


        }
        if (!foundColumns) {
            this->matchTimer->stop();

            this->current_matcher_row = 0;
            if (this->m_matchList.count() > 0) {
                this->slot_beginLauchSequence(this->m_matchList);
                matchTimer->stop();
            } else {
                emit this->signalFinishedMatchChecking(false);
            }
        } else {

            //              this->matchTimer->stop();
            //                this->current_matcher_row = 0;
            //emit this->signalFinishedMatchChecking(true);
            if (this->m_matchList.count() > 0) {
                this->matchTimer->stop();

                this->current_matcher_row = 0;
                this->slot_beginLauchSequence(this->m_matchList);
            } else {
                matchTimer->stop();
                emit this->signalFinishedMatchChecking(false);
            }

        }
    }
}

}


