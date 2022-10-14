#ifndef BLOCKPROCESSOR_H
#define BLOCKPROCESSOR_H

#include <QObject>
#include <QHash>
#include <QString>
#include <QLinkedList>
#include <QQueue>

class BlockProcessor : public QObject
{
    Q_OBJECT
public:
    explicit BlockProcessor(QObject *parent = nullptr);
    int m_processorHashId;
signals:
public slots:
    void setHashTable(QHash<int, QString> table);
    void setProcessorHashId(int hashId);
    void reIndexHashTableToFront();
    QHash<int, QString> getHashTable();

private:
    QHash<int, QString> m_hashTable;

};

#endif // BLOCKPROCESSOR_H
