#include "ircsocket.h"
#include <QString>
#include <QStringList>
#include <QDebug>
#include <QDateTime>
#include <QBuffer>
#include <QUuid>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QCryptographicHash>
#include <QTimer>
IRCSocket::IRCSocket() :
    mState(NotConnected),
    mWhoQueryQueueIdCounter(0) {
    //connect(&mSocket, static_cast<void (QTcpSocket::*)(QAbstractSocket::SocketError)>(&QAbstractSocket::error), this, &IRCSocket::socketError);
    connect(&mSocket, &QAbstractSocket::connected, this, &IRCSocket::socketConnected);
    connect(&mSocket, &QIODevice::readyRead, this, &IRCSocket::readyRead);
    m_waiting_for_message_ok = false;
    sentBytes = 0;
}

void IRCSocket::connectToServer(const QString &address, quint16 port, const QString &nick) {
    mSocket.connectToHost(address, port);
    mIRCServerAddress = address;
    mNickname = nick;
    mUsername = "IRCSocket" + QString::number(qHash(mNickname));
    mHostName = "IRCSocketDefaultHostName";
    mServerName = "IRCSocketDefaultServerName";
    mRealName = "Qt IRCSocket";
}

bool IRCSocket::sendData(const QString &data) {
   // qDebug() << " > " << data;

    QByteArray msg = data.toUtf8() + "\r\n";
    sentBytes += msg.length();
    qDebug() << "Sent " << sentBytes / 1024 << "KB";
    if (msg.length() != mSocket.write(msg)) {
        qDebug() << "Can't send data!!!";
        return false;
    }
    return true;
}

bool IRCSocket::sendPrivateMessage(const QString &channel, const QString &msg) {
    return sendData(" PRIVMSG " + channel + " :" + msg);

}

void IRCSocket::joinChannel(QString channel, QString password) {
    if (!channel.startsWith('#')) channel = '#' + channel;
    sendData("JOIN " + channel + ((password.isEmpty())? QString() : (" " + password)));
}

void IRCSocket::leave(QString channel, QString message) {
    if (!channel.startsWith('#')) channel = '#' + channel;
    sendData("PART " + channel + " :" + message);
}


void IRCSocket::socketConnected() {
    mState = HandshakeInProgress;
    mHandshakeCounter = 0;
    emit connected();
}

void IRCSocket::readyRead() {
    QByteArray data = mSocket.readAll();
    //qDebug() << " <RAW> " << data;
    QStringList newResponses;
    QString data_str = QString::fromLocal8Bit(data);
    newResponses << data_str.split("\r\n", Qt::SkipEmptyParts, Qt::CaseInsensitive);
    for (QString r : newResponses) {
     //   qDebug() << "<RAW>" << r;
        handleRawResponse(r);
    }
}

void IRCSocket::socketError(QAbstractSocket::SocketError socketError) {
    qDebug() << "Socket error " << socketError;
    emit error(socketError);
}

QString IRCSocket::popResponse() {
    if (mResponseBuffer.empty()) return QString();
    QString last = mResponseBuffer.last();
    mResponseBuffer.removeLast();
    return last;
}

void IRCSocket::handleRawResponse(QString r) {
    //qDebug() << " < " << r;
    if (r.startsWith("PING")) {
        sendPong();
        return;
    }
    switch(mState) {
        case HandshakeInProgress:
            mHandshakeCounter++;
            if (mHandshakeCounter == 1) {
                sendNickname();
                sendUser();
            }
            if (r.contains(" 437")) {
                mNickname += "_";
                sendNickname();
            }

            if (r.contains(" 396")) {
                mState = Connected;
                emit handshakeComplete();
            }
            return;
        case Connected:
            if (r.startsWith(':')) {
                handleMessage(r.remove(0, 1));
            }
            break;
        default:
            qDebug() << "WTF";
    }
}

void IRCSocket::handleMessage(QString r) {
    int senderEndIndex = r.indexOf(' ');
    if (senderEndIndex == -1) { qDebug() << "Invalid message"; return; }
    QString sender = r.left(senderEndIndex);

    r = r.remove(0, senderEndIndex + 1);

    if (r.startsWith("PRIVMSG")) {
        handlePrivateMessage(sender, r.remove(0, 8)); return;
    }
    if (r.startsWith("MODE")) {
        handleMode(sender, r.remove(0, 5)); return;
    }
    if (r.startsWith("JOIN")) {
        qDebug() << "JOIN" << sender << r;

        handleJoin(sender, r.remove(0, 5)); return;
    }
    if (r.startsWith("QUIT")) {
        handleQuit(sender, r.remove(0, 5)); return;
    }
    if (r.startsWith("PART")) {
        handleLeave(sender, r.remove(0, 5)); return;
    }

    if (!sender.contains('!')) {
        handleServerMessage(r);
        return;
    }

}

void IRCSocket::sendNickname() {
    sendData("NICK " + mNickname);
}

void IRCSocket::sendUser() {
    sendData("USER " + mUsername + ' ' + mHostName + ' ' + mServerName + " :" + mRealName);
}

void IRCSocket::sendPong() {
    sendData("PONG " + QString::number(QDateTime::currentDateTime().toMSecsSinceEpoch()));
}

void IRCSocket::handleServerMessage(QString r) {
    if (r[0].isDigit()) {
        if (r.startsWith("352")) {
            r.remove(0, 4);
            handleWhoReply(r);
        }
        if (r.startsWith("315")) {
            r.remove(0, 4);
            handleEndOfWho();
        }
    }
}

void IRCSocket::handlePrivateMessage(const QString &sender, QString r) {
    int channelEndIndex = r.indexOf(':');
    if (channelEndIndex == -1) { qDebug() << "Invalid PRIVMSG"; return; }
    QString channel = r.left(channelEndIndex).trimmed();
    r.remove(0, channelEndIndex + 1);
    if (channel == getCurrentChannel()) {
        if (getNicknameFromUserHost(sender) == getOpponentNickname()) {
            QStringList args;
            args << r.split(" ");
            if (args.at(0) == "CHANNEL") {
                QString arg0 = args.takeFirst();
                emit this->channelMessageReceived(uncompress(args.join(" ")));
            }

            if (args.at(0) == "BEGIN-MULTIPART") {
                this->m_multipart_messages[args.at(1)] = "";
            }
            if (args.at(0) == "MULTIPART") {
                QString currentMessage = this->m_multipart_messages.value(args.at(1), "");
                QString arg0 = args.takeFirst();
                QString arg1 = args.takeFirst();
                //            args.takeLast();
                currentMessage.append(args.join(" "));
                //    qDebug() << "--+> Appending " << args.join(" ") << "to" << currentMessage;
                this->m_multipart_messages[arg1] = currentMessage;
                return;
            }
            if (args.at(0) == "END-MULTIPART") {
                //  qDebug() << "Multipart Message: "<< this->m_multipart_messages.value(args.at(1), "");
                QString tmpMsg = uncompress(this->m_multipart_messages.value(args.at(1), ""));
                QStringList tmpParts;
                tmpParts << tmpMsg.split(" ", Qt::SkipEmptyParts);
                if (tmpParts.length() > 1) {
                     QString cmd = tmpParts.takeFirst();
               emit this->gameMessageReceived(cmd,tmpParts.join(" "));
                } else {
                    if (tmpParts.length() > 0) {
                        emit this->gameMessageReceived(tmpParts.takeFirst(), "");
                    } else {

                    }
                }
                   this->sendPrivateMessage(this->getCurrentChannel(), QString("OK-MULTIPART %1").arg(args.at(1)));

                return;
            }
            if (args.at(0) == "MESSAGE") {
                QString arg0 = args.takeFirst();
                QString arg1 = args.takeFirst();
                QString currentMessage;
                currentMessage.append(args.join(" "));
                this->m_multipart_messages[arg1] = currentMessage;
                QString tmpMsg = uncompress(this->m_multipart_messages.value(arg1, ""));
                QStringList tmpParts;
                tmpParts << tmpMsg.split(" ", Qt::SkipEmptyParts);
                if (tmpParts.length() > 1) {
                    QString cmd = tmpParts.takeFirst();
               emit this->gameMessageReceived(cmd, tmpParts.join(" "));
                } else {
                    if (tmpParts.length() > 0) {
                        emit this->gameMessageReceived(tmpParts.takeFirst(), "");
                    } else {

                    }
                }

               this->sendPrivateMessage(this->getCurrentChannel(), QString("OK-MULTIPART %1").arg(arg1));
            }
            if (args.at(0) == "OK-MULTIPART") {
                m_waiting_for_message_ok = false;
                if (m_messageQueue.length() > 0) {
                    QPair<QString, QString> pair = m_messageQueue.dequeue();
                    sendMessageToCurrentChannel(pair.second);
                } else {


                }
                return;
            }
        }

    }
    emit privateMessage(sender, channel, r);
}

void IRCSocket::handleMode(const QString &sender, QString m) {
    if (!m.startsWith('#')) {
        emit userMode(sender, m);
        return;
    }

    int targetEndIndex = m.indexOf(' ');
    if (targetEndIndex == -1) { qDebug() << "Invalid MODE"; return; }
    QString target = m.left(targetEndIndex);
    m.remove(0, targetEndIndex + 1);

    int flagsEndIndex = m.indexOf(' ');
    if (flagsEndIndex == -1) { qDebug() << "Invalid MODE"; return; }
    QString flags = m.left(flagsEndIndex);
    m.remove(0, flagsEndIndex + 1);

    emit channelMode(sender, target, flags, m);
}

void IRCSocket::handleJoin(const QString &sender, QString m) {
    int channelStart = m.indexOf(':');
    if (channelStart == -1) { qDebug() << "Invalid join"; return; }
    m.remove(0, channelStart + 1);
    if (m.contains("game")) {
        if (this->getNicknameFromUserHost(sender) == this->nickname()) {
            this->setCurrentChannel(m);
        }
    }
    emit userJoin(sender, m);
}

void IRCSocket::sendLocalGameMessage(QString sender, QString cmd, QString message)
{
    emit this->localGameMessageReceived(sender, cmd, message);
}

void IRCSocket::handleQuit(const QString &sender, QString m) {
    int messageStart = m.indexOf(':');
    if (messageStart == -1) { qDebug() << "Invalid join"; return; }
    m.remove(0, messageStart + 1);

    emit userQuit(sender, m);
}

void IRCSocket::handleLeave(const QString &sender, QString m) {
    int channelEnd = m.indexOf(':');
    if (channelEnd == -1) { qDebug() << "Invalid join"; return; }

    QString channel = m.left(channelEnd).trimmed();
    m.remove(0, channelEnd + 1);

    emit userLeave(sender, channel, m);
}

void IRCSocket::handleWhoReply(const QString &reply) {
    mWhoQueryResult.append(reply);
}

void IRCSocket::handleEndOfWho() {
    emit whoQueryResult(mWhoQueryQueue.first(), mWhoQueryResult);
    mWhoQueryResult.clear();
    mWhoQueryQueue.removeFirst();
}

QString IRCSocket::getCurrentChannel()
{
return mCurrentChannel;
}

void IRCSocket::setCurrentChannel(QString channel)
{
mCurrentChannel = channel;
}


int IRCSocket::whoQuery(const QString &queryString) {
    mWhoQueryQueue.append(++mWhoQueryQueueIdCounter);
    sendData("WHO " + queryString);
    return mWhoQueryQueueIdCounter;
}

QString IRCSocket::compress(QString i_str)
{

    QByteArray i_ba = i_str.toLocal8Bit();
    QByteArray o_ba = qCompress(i_ba,9);
    QString o_str = QString::fromLocal8Bit(o_ba.toBase64());
    return o_str;
}

QString IRCSocket::uncompress(QString i_str)
{

    QByteArray i_ba = QByteArray::fromBase64(i_str.toLocal8Bit());
    QByteArray o_ba = qUncompress(i_ba);
    QString o_str = QString::fromLocal8Bit(o_ba);
    return o_str;
}

QString IRCSocket::getNicknameFromUserHost(QString userhost)
{
    QStringList parts;
    parts << userhost.split("!");
    if (parts.length() > 0) {
        return parts.first();
    } else {
        return "";
    }
}

QString IRCSocket::getOpponentNickname()
{
    if (this->getCurrentChannel().contains("game")) {
        QStringList parts;
        parts << this->getCurrentChannel().split("_");
        if (parts.length() > 2) {
            parts.removeFirst();
            if (parts.first() == this->nickname()) {
             parts.removeFirst();
            }
            return parts.first();
        }
    }

    return "";
}


void IRCSocket::quit(QString message) {
    sendData("QUIT :" + message);
    mSocket.close();
    mState = NotConnected;
}


void IRCSocket::sendMessageToCurrentChannel(QString _msg)
{

QString msg = compress(_msg);
     QByteArray messageContents = msg.toLocal8Bit();
    if (m_waiting_for_message_ok == false) {
        qDebug() << "Sending Message" << messageContents;
        QString messageUuid = QUuid::createUuid().toString().section("-", 2, 3);
        if (msg.length() > 150) {
            this->sendPrivateMessage(this->getCurrentChannel(), QString("BEGIN-MULTIPART %1").arg(messageUuid));

            qint64 pos = 0;
            QBuffer buffer(&messageContents);
            buffer.open(QIODevice::ReadOnly);
            while ((messageContents.length() - pos) > 150) {
                buffer.seek(pos);
                QByteArray chunk = buffer.read(150);
                pos += 150;
                this->sendPrivateMessage(this->getCurrentChannel(), QString("MULTIPART %1  %2").arg(messageUuid).arg(QString::fromLocal8Bit(chunk)));
            }
            buffer.seek(pos);
            QByteArray chunk = buffer.readAll();
            buffer.close();
            if (chunk.length() > 0) {
                this->sendPrivateMessage(this->getCurrentChannel(), QString("MULTIPART %1 %2").arg(messageUuid).arg(QString::fromLocal8Bit(chunk)));
            }
            this->sendPrivateMessage(this->getCurrentChannel(), QString("END-MULTIPART %1").arg(messageUuid));
        } else {
            this->sendPrivateMessage(this->getCurrentChannel(), QString("MESSAGE %1  %2").arg(messageUuid).arg(QString::fromLocal8Bit(messageContents)));
        }
        m_waiting_for_message_ok = true;

    } else {
        QPair<QString, QString> msgPair;
        msgPair.first = QUuid::createUuid().toString().section("-", 2, 3);
        msgPair.second = msg;
        m_messageQueue.enqueue(msgPair);

        //qDebug() << m_messageQueue;
    }
}

QString IRCSocket::gameCommandMessage(QString cmd, QString message)
{
    return QString("%1 %2").arg(cmd).arg(message);
}

QVariant IRCSocket::makeJSONDocument(QString doc)
{
    QVariantMap rv;
    QJsonDocument docu;
    docu = QJsonDocument::fromJson(doc.toLocal8Bit());
    qDebug() << docu.toJson(QJsonDocument::Compact);
    return docu.toVariant();
}

QString IRCSocket::hash(QString string)
{
QByteArray ba = string.toLocal8Bit();
QByteArray bo = QCryptographicHash::hash(ba, QCryptographicHash::Md5);
return bo.toBase64();
}

void IRCSocket::sendChannelMessage(QString message)
{
 this->sendPrivateMessage(this->getCurrentChannel(), QString("CHANNEL %1").arg(compress(message)));
}
