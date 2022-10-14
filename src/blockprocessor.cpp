#include "blockprocessor.h"

BlockProcessor::BlockProcessor(QObject *parent)
    : QObject{parent}
{

}

void BlockProcessor::setHashTable(QHash<int, QString> table)
{
    this->m_hashTable.insert(table);
}

void BlockProcessor::setProcessorHashId(int hashId)
{
    this->m_processorHashId = hashId;
}

void BlockProcessor::reIndexHashTableToFront()
{
int i = 0;
QList<int> keys = this->m_hashTable.keys();
int totalEntries = keys.length();
QHash<int, QString> newHash;
newHash.reserve(totalEntries * 6);
int u = 0;
while (i < totalEntries) {
    if (keys.contains(u)) {
        QString oldVal = this->m_hashTable.value(u);
        newHash[i] = oldVal;
        i++;
    }
    u++;
}
this->m_hashTable.clear();
this->m_hashTable.insert(newHash);



}

QHash<int, QString> BlockProcessor::getHashTable()
{
return this->m_hashTable;
}
