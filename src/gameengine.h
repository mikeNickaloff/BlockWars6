#ifndef GAMEENGINE_H
#define GAMEENGINE_H

#include <QObject>
#include <QQuickItem>
#include <QQueue>
#include <QStack>
#include <QTimer>
class BlockCPP;
class BlockQueue;
class GameEngine : public QObject
{
    Q_OBJECT
public:
    explicit GameEngine(QObject *parent = nullptr, QString orientation = "none");
    QHash<qint64, QQueue<QString> > m_queues;
    BlockCPP* new_block;
    QHash<QString, BlockCPP*> m_blocks;
    QHash<qint64, QQueue<QString> > m_stacks;
    QHash<QString, qint64> m_afterLaunchColumns;
    QQueue<QString> m_preLaunch;
    QQueue<QString> m_postLaunch;
    QString m_orientation;
    Q_INVOKABLE QString orientation() { return m_orientation; }
    Q_INVOKABLE QVariantList getBlocksByColumn(int column);
    Q_INVOKABLE QVariantList getStack(int column);
    Q_INVOKABLE QVariantList getQueue(int column);
    Q_INVOKABLE QVariantList getMatchingBlocks();
    QStringList getStackRow(int row_num);
    QStringList getStackColumn(int col_num);
    BlockCPP* getBlockByUuid(QString uuid);
    QList<BlockCPP*> getBlocksFromUuids(QStringList uuids);
    QStringList getColorsByUuids(QStringList uuids);
    Q_INVOKABLE bool isBlockInLaunchQueues(QString uuid);
    Q_INVOKABLE QQueue<QString> filterUuidFromStack(QString uuid, QQueue<QString> stack, bool compactResults);
    Q_INVOKABLE QQueue<QString> filterUuidFromQueue(QString uuid, QQueue<QString> queue);
    Q_INVOKABLE QQueue<QString> insertUuidIntoStack(QString uuid, int position, QQueue<QString> stack);
    Q_INVOKABLE qint64 getUuidPositionInStack(QString uuid, QQueue<QString> stack);
    bool matcherRunning;
    QTimer* launchTimer;
    QTimer* matchTimer;
    QList<QString> m_matchList;
    int current_matcher_row;
    int numberLaunched;
    bool gotMatchThisRound;
    BlockQueue* m_newBlockQueue;
    QHash<int, BlockQueue*> m_blockQueues;
    Q_INVOKABLE int getBlockRow(QString uuid);
    Q_INVOKABLE int getBlockColumn(QString uuid);

    BlockQueue* getBlockQueue(int column);

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

public slots:
    Q_INVOKABLE void setOrientation(QString orientation) { m_orientation = orientation; }
    Q_INVOKABLE void createBlockCPP(QString uuid, QString color, int column, int row, int health);
    Q_INVOKABLE void removeBlock(QString uuid, int column);
    Q_INVOKABLE void swapBlocks(QString uuid1, QString uuid2);
    Q_INVOKABLE void launchBlock(QString uuid);
    Q_INVOKABLE void completeLaunch(QString uuid, int column);
    Q_INVOKABLE bool compactBlocks(qint64 column);
    Q_INVOKABLE void checkMatches();
    QList<QString> checkUuidsForMatches(QList<QString> uuids);
    Q_INVOKABLE bool FindMatches(int row_or_column, bool is_row);
    Q_INVOKABLE void runTimedMatchLauncher();
    Q_INVOKABLE bool dropColumnDown(int startingRow, int column);
    void checkAndReportMatcherStatus();
    Q_INVOKABLE void launchNext();
    Q_INVOKABLE void slot_beginLauchSequence(QStringList uuids);
    Q_INVOKABLE void matchNextRow();

    void setBlockRow(QString uuid, int row, bool updateStack);
    void setBlockColumn(QString uuid, int column, bool updateStack);
    void updateStacksFromBlocksProps();
    void updateBlockPropsFromStacks();

    Q_INVOKABLE void setBlockColor(QString uuid, QString color);
    void handleRelayRequestUuidAtPosition(int req_column, int req_position, QString req_uuid);
    void handleRelayRespondUuidAtPosition(int res_column, int res_position, QString res_uuid);
    void createBlockQueue(int column);
    void associateBlockWithBlockQueue(int column, BlockCPP* block);
};

#endif // GAMEENGINE_H
