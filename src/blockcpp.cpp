#include "blockcpp.h"

BlockCPP::BlockCPP(QObject *parent, QString uuid)
    : QObject{parent}
{
m_uuid = uuid;
this->m_row = 0;
this->m_column = 0;

}

void BlockCPP::sendUpdatePositionSignal()
{
    emit this->positionChanged(this->m_uuid, this->m_row, this->m_column);
}
