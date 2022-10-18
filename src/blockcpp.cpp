#include "blockcpp.h"
#include "blockqueue.h"
BlockCPP::BlockCPP(QObject *parent, QString uuid)
    : QObject{parent}
{
m_uuid = uuid;
this->m_row = 0;
this->m_column = 0;
this->m_uuid = "";
this->m_uuidColumnLeft = "";
this->m_uuidColumnRight = "";
this->m_uuidRowAbove = "";
this->m_uuidRowBelow = "";
this->m_health = 5;
this->m_hidden = true;

targetIdentified = false;


}

void BlockCPP::sendUpdatePositionSignal()
{
    emit this->positionChanged(this->m_uuid, this->m_row, this->m_column);
}
