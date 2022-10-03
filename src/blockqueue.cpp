#include "blockqueue.h"
#include "blockcpp.h"
#include <QLinkedList>
#include <QQueue>
#include <QObject>
#include "gameengine.h"

BlockQueue::BlockQueue(QObject *parent, int column, GameEngine* i_engine)
    : QObject(parent), m_engine(i_engine)
{
    m_column = column;
}

BlockCPP *BlockQueue::getBlockFromUuid(QString uuid)
{
    if (this->m_blocks.keys().contains(uuid)) {
        return m_blocks.value(uuid, nullptr);
    }
    return nullptr;
}

int BlockQueue::getPositionFromUuid(QString uuid)
{
    if (this->m_positionsByUuid.keys().contains(uuid)) {
        return m_positionsByUuid.value(uuid, -1);
    }
    return -1;
}

QString BlockQueue::getUuidAtPosition(int position)
{
    if (this->m_uuidsByPosition.keys().contains(position)) {
        return m_uuidsByPosition.value(position, "");
    }
    return "";
}

QList<QString> BlockQueue::getPlayableBlocks(bool includeEmpty)
{
    QList<QString> rv;
    int i=0;
    while (rv.count() < 6) {
        QString uuid_at_position_i = this->getUuidAtPosition(i);
            if (uuid_at_position_i == "") {
                if (includeEmpty) { rv.append(""); }
            } else {
                rv.append(uuid_at_position_i);
            }

            i++;
            if (i > this->m_uuidsByPosition.keys().length()) {
                break;
            }
    }
    return rv;
}

QStringList BlockQueue::serializeAllBlocks()
{
    QStringList rv;
    foreach (BlockCPP* blk, this->m_blocks.values()) {
        rv << blk->serialize();
    }
    return rv;
}

void BlockQueue::updateHashesFromBlockProps(BlockCPP *block)
{
    if (block != nullptr) {
        int blockRow = block->getRow();
        QString blockUuid = block->m_uuid;
        this->m_positionsByUuid[blockUuid] = blockRow;
        this->m_uuidsByPosition[blockRow] = blockUuid;
        emit this->requestUuidAtPosition(this->m_column, blockRow, blockUuid);
    }
}

void BlockQueue::associateBlockWithQueue(BlockCPP *block, QString uuid, int row )
{

    if (this->m_blocks.keys().contains(uuid)) {
        if (block != nullptr) {
            if (m_blocks.value(uuid, nullptr) == nullptr) {
                this->
                m_engine->createBlockCPP(uuid, block->m_color, block->getColumn(), block->getRow(), 5);
                BlockCPP* blk = m_engine->getBlockByUuid(uuid);
                this->m_blocks[uuid] = blk;
                block->m_uuid = uuid;
                block->m_row = row;
                this->updateHashesFromAllBlockProps();
            }
        }
        // aready associated.
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

void BlockQueue::receiveUuidAtPositionResponse(int res_column, int res_position, QString res_uuid)
{

    if (res_column == (this->m_column + 1)) {
        QString targetUuid = this->getUuidAtPosition(res_position);
        BlockCPP* targetBlock = this->getBlockFromUuid(targetUuid);
        if (targetBlock !=  nullptr) {
            targetBlock->m_uuidColumnRight = res_uuid;
            qDebug() << targetBlock->serialize();
        }
    }
    if (res_column == (this->m_column - 1)) {
        QString targetUuid = this->getUuidAtPosition(res_position);
        BlockCPP* targetBlock = this->getBlockFromUuid(targetUuid);
        if (targetBlock !=  nullptr) {
            targetBlock->m_uuidColumnLeft = res_uuid;
        }
    }

}

void BlockQueue::receiveUuidAtPositionRequest(int column, int position, QString requesting_uuid)
{
    if (qAbs(this->m_column - column) == 1) {
        this->receiveUuidAtPositionResponse(column, position, requesting_uuid);
        this->respondUuidAtPosition(this->m_column, position, this->getUuidAtPosition(position));
    }
}

void BlockQueue::bumpBlocksUp(int startingRow)
{
    for (int i=startingRow; i>0; i--) {
        QString targetUuid = this->getUuidAtPosition(i);
        if (targetUuid != "") {
            BlockCPP* blk = this->getBlockFromUuid(targetUuid);
            if (blk != nullptr) {
                blk->m_row -= 1;

                if (this->getUuidAtPosition(i - 1) == "") {
                    /* bump end */
                    break;
                }
            }
        } else {
            break;

        }
    }
    this->updateHashesFromAllBlockProps();


}

void BlockQueue::updateHashesFromAllBlockProps()
{
    qDebug() <<serializeAllBlocks();
    foreach (BlockCPP* blk, this->m_blocks.values()) {
        if (blk != nullptr) {
            this->updateHashesFromBlockProps(blk);
        }
    }
}

void BlockQueue::updateHashesAndBlocksFromQueue()
{
    QQueue<QString> stack(m_engine->m_queues.value(this->m_column));
int i = 0;
    while (!stack.isEmpty()) {
        i++;
        QString uuid = stack.dequeue();
        BlockCPP* blk = this->getBlockFromUuid(uuid);

        if (blk != nullptr) {
            blk->m_row = i;
        } else {
           blk = this->m_engine->getBlockByUuid(uuid);
            if (blk != nullptr) {
                m_engine->associateBlockWithBlockQueue(this->m_column, blk);
                blk = this->getBlockFromUuid(uuid);
                if (blk != nullptr) {
                    blk->m_row = i;
                } else {
                    qDebug() << "Block association failed to create block readable by getBlockFromUUid from queue" << this->m_column << "and uuid" << uuid;
                }
            }
        }
    }
    updateHashesFromAllBlockProps();
}
