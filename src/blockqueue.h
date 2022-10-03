#ifndef BLOCKQUEUE_H
#define BLOCKQUEUE_H

#include <QObject>
#include <QHash>
#include <QHash>

class BlockCPP;
class GameEngine;
class BlockQueue : public QObject
{
    Q_OBJECT
public:
    explicit BlockQueue(QObject *parent  = nullptr, int column = -1, GameEngine* i_engine = nullptr);
    QHash<QString, BlockCPP*> m_blocks;
    QHash<int, QString> m_uuidsByPosition;
    QHash<QString, int> m_positionsByUuid;
    GameEngine* m_engine;
    BlockCPP* getBlockFromUuid(QString uuid);
    int getPositionFromUuid(QString uuid);
    QString getUuidAtPosition(int position);
    QList<QString> getPlayableBlocks(bool includeEmpty  = false);
    int m_column;
    QStringList serializeAllBlocks();

signals:
    void requestUuidAtPosition(int column, int position, QString requesting_uuid);
    void respondUuidAtPosition(int column, int position, QString response_uuid);
public slots:
    void updateHashesFromBlockProps(BlockCPP* block  = nullptr);
    void associateBlockWithQueue(BlockCPP *block = nullptr, QString uuid = "", int row = -1);
    void setBlockBelow(QString uuid, QString uuidBelow);
    void setBlockAbove(QString uuid, QString uuidAbove);
    void setBlockLeft(QString uuid, QString uuidLeft);
    void setBlockRight(QString uuid, QString uuidRight);
    void receiveUuidAtPositionResponse(int res_column, int res_position, QString res_uuid);
    void receiveUuidAtPositionRequest(int column, int position, QString requesting_uuid);
    void  bumpBlocksUp(int startingRow);
    void updateHashesFromAllBlockProps();
    void updateHashesAndBlocksFromQueue();
};

#endif // BLOCKQUEUE_H
