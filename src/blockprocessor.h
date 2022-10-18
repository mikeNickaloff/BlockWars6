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

    void setProcessorHashId(int hashId);
    void reIndexHashTableToFront();

    void transferItemFirstToEnd();
    void transferItemLastToFront();
    void transferItemFirstToFront();
    void transferItemLastToBack();

    QHash<int, QString> getHashTable();
    QHash<int, QString> getFromTable();
    QHash<int, QString> getToTable();

    void setFromTable(QHash<int, QString> fromTable);
    void setToTable(QHash<int, QString> toTable);
    void setHashTable(QHash<int, QString> table);




private:
    QHash<int, QString> m_hashTable;
    QHash<int, QString> m_fromTable;
    QHash<int, QString> m_toTable;


};

#endif // BLOCKPROCESSOR_H
