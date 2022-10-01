#include "blockcpp.h"

BlockCPP::BlockCPP(QObject *parent, QString uuid)
    : QObject{parent}
{
m_uuid = uuid;
}
