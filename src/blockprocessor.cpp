#include "blockprocessor.h"
#include <QHash>
#include <QObject>
#include <QtDebug>

BlockProcessor::BlockProcessor(QObject *parent)
    : QObject{parent}
{

}

void BlockProcessor::setHashTable(QHash<int, QString> table)
{
    this->m_hashTable.clear();
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
qSort(keys.begin(), keys.end());
int u = 0;

for (int i=0; i<keys.length(); i++) {

        int key = keys.at(i);

        QString oldVal = this->m_hashTable.value(key);
        if (!newHash.values().contains(oldVal)) {
            newHash[u] = oldVal;
            u++;
        } else {

        }
    }


this->m_hashTable.clear();
this->m_hashTable.insert(newHash);



}

void BlockProcessor::transferItemFirstToEnd()
{
    if (this->m_fromTable.size() > 0) {
        QList<int> tkeys;
        tkeys << this->m_toTable.keys();
        //qSort(tkeys.begin(), tkeys.end());
        int tkey;
        if (tkeys.length() == 0) { tkey = -1; } else { tkey = tkeys.last(); }


        QList<int> fkeys;
        fkeys << this->m_fromTable.keys();
        qSort(fkeys.begin(), fkeys.end());
        int fkey = fkeys.first();

        QString fval = this->m_fromTable.value(fkey);
        this->m_toTable[tkey + 1] = fval;
        this->m_fromTable.remove(fkey);

    }
}

void BlockProcessor::transferItemLastToFront()
{
    if (this->m_fromTable.size() > 0) {
        QList<int> tkeys;
        tkeys << this->m_toTable.keys();
    //    qSort(tkeys.begin(), tkeys.end());
        QList<QString> tvals;
        tvals << this->m_toTable.values();




        QList<int> fkeys;
        fkeys << this->m_fromTable.keys();
        qSort(fkeys.begin(), fkeys.end());
        int fkey = fkeys.last();
        int tkey;
        if (tkeys.length() == 0) { tkey = -1; } else { tkey = tkeys.last(); }

        QString fval = this->m_fromTable.value(fkey);
        tvals.push_front(fval);
        tkeys.push_back(tkey + 1);
        this->m_toTable.clear();
        for (int i=0; i<tvals.length(); i++) {
            this->m_toTable[i] = tvals.at(i);
        }

    }
}

void BlockProcessor::transferItemFirstToFront()
{

        if (this->m_fromTable.size() > 0) {
            QList<int> tkeys;
            tkeys << this->m_toTable.keys();
        //    qSort(tkeys.begin(), tkeys.end());
            QList<QString> tvals;
            tvals << this->m_toTable.values();




            QList<int> fkeys;
            fkeys << this->m_fromTable.keys();
            qSort(fkeys.begin(), fkeys.end());
            int fkey = fkeys.first();
            int tkey;
            if (tkeys.length() == 0) { tkey = -1; } else { tkey = tkeys.last(); }

            QString fval = this->m_fromTable.value(fkey);
            this->m_fromTable.remove(fkey);
            tvals.push_front(fval);
            tkeys.push_back(tkey + 1);
            this->m_toTable.clear();
            for (int i=0; i<tvals.length(); i++) {
                this->m_toTable[i] = tvals.at(i);
            }

        }
}

void BlockProcessor::transferItemLastToBack()
{
    if (this->m_fromTable.size() == 0) { return; }
QList<int> fkeys;

fkeys << this->m_fromTable.keys();
QList<int> tkeys;
int tkey;
tkeys << this->m_toTable.keys();
if (this->m_toTable.size() == 0) { tkey = 0; } else { tkey = tkeys.last(); }
int fkey = fkeys.last();

tkey++;
QString fVal = m_fromTable.value(fkey);
this->m_toTable[tkey] = fVal;
m_fromTable.remove(fkey);

}

QHash<int, QString> BlockProcessor::getHashTable()
{
    return this->m_hashTable;
}

void BlockProcessor::setFromTable(QHash<int, QString> fromTable)
{
    this->m_fromTable.clear();
this->m_fromTable.insert(fromTable);
  //  qDebug() << "Block Processor Set 'From' Table" << fromTable.keys() << fromTable.values();
}

void BlockProcessor::setToTable(QHash<int, QString> toTable)
{
    this->m_toTable.clear();
    this->m_toTable.insert(toTable);
    //            qDebug() << "Block Processor Set 'To' Table" << toTable.keys() << toTable.values();
}

QHash<int, QString> BlockProcessor::getFromTable()
{
    if (this->m_fromTable.keys().length() > 0) {
        if (this->m_fromTable.keys().first() != 0) {
            this->setHashTable(this->m_fromTable);
            this->reIndexHashTableToFront();
            this->m_fromTable.clear();
            this->m_fromTable.insert(this->getHashTable());
        }
    }
       // qDebug() << "Block Processor Returned 'From' table" <<  m_fromTable.keys() << m_fromTable.values();
    return this->m_fromTable;

}

QHash<int, QString> BlockProcessor::getToTable()
{
  //  qDebug() << "Block Processor Returned 'To' table" <<  m_toTable.keys() << m_toTable.values();
       return this->m_toTable;
}
