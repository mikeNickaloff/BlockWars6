#ifndef IRCSOCKET_H
#define IRCSOCKET_H
#include <QTcpSocket>
#include <QStringList>
#include <QQueue>

class IRCSocket : public QObject{

    Q_PROPERTY(QString currentChannel READ getCurrentChannel WRITE setCurrentChannel)
    Q_OBJECT
    public:
        enum State {
            NotConnected,
            HandshakeInProgress,
            Connected
        };

        IRCSocket();
       Q_INVOKABLE void connectToServer(const QString &address, quint16 port, const QString &nick);
         Q_INVOKABLE bool sendData(const QString &data);
         Q_INVOKABLE bool sendPrivateMessage(const QString &channel, const QString &msg);
         Q_INVOKABLE void joinChannel(QString channel, QString password = QString());
         Q_INVOKABLE void leave(QString channel, QString message = QString());
         Q_INVOKABLE void quit(QString message = QString());
        int whoQuery(const QString &queryString);
         Q_INVOKABLE QString nickname() const { return mNickname; }
        Q_INVOKABLE QString compress(QString i_str);
        Q_INVOKABLE QString uncompress(QString i_str);
        Q_INVOKABLE QString getNicknameFromUserHost(QString userhost);
        Q_INVOKABLE QString  getOpponentNickname();
        Q_INVOKABLE void sendMessageToCurrentChannel(QString message);
        Q_INVOKABLE QString gameCommandMessage(QString cmd, QString message);
        Q_INVOKABLE QVariant makeJSONDocument(QString doc);
signals:
        void error(QAbstractSocket::SocketError socketError);
        void connected();
        void handshakeComplete();
        void privateMessage(QString sender, QString channel, QString msg);
        void channelMode(QString sender, QString channel, QString flags, QString params);
        void userMode(QString sender, QString flags);
        void userJoin(QString user, QString channel);
        void userQuit(QString user, QString msg);
        void userLeave(QString user, QString channel, QString msg);
        void whoQueryResult(int id, QStringList result);
        void gameMessageReceived(QString command, QString message);
    private slots:
        void socketConnected();
        void readyRead();
        void socketError(QAbstractSocket::SocketError socketError);
    private:
        QString popResponse();
        void handleRawResponse(QString r);
        void handleMessage(QString r);
        void sendNickname();
        void sendUser();
        void sendPong();
        void handleServerMessage(QString r);
        void handlePrivateMessage(const QString &sender, QString r);
        void handleMode(const QString &sender, QString m);
        void handleJoin(const QString &sender, QString m);
        void handleQuit(const QString &sender, QString m);
        void handleLeave(const QString &sender, QString m);
        void handleWhoReply(const QString &reply);
        void handleEndOfWho();
        QString getCurrentChannel();
        void setCurrentChannel(QString channel);
        QTcpSocket mSocket;
        QStringList mResponseBuffer;
        State mState;
        QString mNickname;
        QString mUsername;
        QString mHostName;
        QString mServerName;
        QString mRealName;
        QString mIRCServerAddress;
        QQueue<int> mWhoQueryQueue;
        int mWhoQueryQueueIdCounter;
        QStringList mWhoQueryResult;
        QString mCurrentChannel;

        int mHandshakeCounter;
        QHash<QString, QString> m_multipart_messages;
        QQueue<QPair<QString,QString>> m_messageQueue;
        bool m_waiting_for_message_ok;
};

#endif // IRCSOCKET_H
