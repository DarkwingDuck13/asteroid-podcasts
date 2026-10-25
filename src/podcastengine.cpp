/*
 * =====================================================================
 * Part of the AsteroidOS Custom Software Suite
 * Architecture, Engine & UI Engineering by Gemini (Google)
 * Co-Developed & Tested on-device by DarkwingDuck13
 *
 * Platform: AsteroidOS (Linux / Qt6 / OpenEmbedded / TicWatch Pro)
 * =====================================================================
 */

#include "podcastengine.h"
#include <QDir>
#include <QFile>
#include <QFileInfoList>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QXmlStreamReader>
#include <QUrlQuery>
#include <QRegularExpression>
#include <QProcess>
#include <QDateTime>
#include <QDebug>

PodcastEngine::PodcastEngine(QObject *parent) : QObject(parent) {
    m_net = new QNetworkAccessManager(this);
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_player->setAudioOutput(m_audioOutput);
    m_audioOutput->setVolume(1.0);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, &PodcastEngine::onPlaybackStateChanged);
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, &PodcastEngine::onMediaStatusChanged);
    connect(m_player, &QMediaPlayer::positionChanged, this, &PodcastEngine::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &PodcastEngine::durationChanged);

    m_storagePath = QDir::homePath() + "/podcasts";
    QDir().mkpath(m_storagePath);

    m_saveTimer = new QTimer(this);
    connect(m_saveTimer, &QTimer::timeout, this, &PodcastEngine::autoSaveState);

    loadSubscriptions();
    refreshDownloads();
    loadLastState();
    refreshVolume();
}

PodcastEngine::~PodcastEngine() {
    saveCurrentState();
    saveSubscriptions();
    releaseWakeLock();
}

void PodcastEngine::acquireWakeLock() {
    QFile file("/sys/power/wake_lock");
    if (file.open(QIODevice::WriteOnly)) {
        file.write("asteroid-podcasts");
        file.close();
    }
    QProcess::startDetached("sh", QStringList() << "-c" << "echo asteroid-podcasts > /sys/power/wake_lock 2>/dev/null; dbus-send --system --type=method_call --dest=com.nokia.mce /com/nokia/mce/request com.nokia.mce.request.req_display_blanking_pause 2>/dev/null || true");
}

void PodcastEngine::releaseWakeLock() {
    QFile file("/sys/power/wake_unlock");
    if (file.open(QIODevice::WriteOnly)) {
        file.write("asteroid-podcasts");
        file.close();
    }
    QProcess::startDetached("sh", QStringList() << "-c" << "echo asteroid-podcasts > /sys/power/wake_unlock 2>/dev/null || true");
}

void PodcastEngine::onPlaybackStateChanged(QMediaPlayer::PlaybackState state) {
    if (state == QMediaPlayer::PlayingState) {
        acquireWakeLock();
        m_saveTimer->start(5000);
    } else {
        releaseWakeLock();
        m_saveTimer->stop();
        saveCurrentState();
    }
    emit playingChanged();
}

void PodcastEngine::onMediaStatusChanged(QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::LoadedMedia && m_resumeSeekPos > 0) {
        m_player->setPosition(m_resumeSeekPos);
        m_resumeSeekPos = 0;
    }
}

void PodcastEngine::autoSaveState() {
    if (isPlaying()) {
        saveCurrentState();
    }
}

void PodcastEngine::saveCurrentState() {
    if (m_currentFilePath.isEmpty()) return;

    QJsonObject obj;
    obj["showTitle"] = m_currentShowTitle;
    obj["epTitle"] = m_currentTrackTitle;
    obj["filePath"] = m_currentFilePath;
    obj["position"] = static_cast<qint64>(m_player->position());
    obj["duration"] = static_cast<qint64>(m_player->duration());

    QFile file(m_storagePath + "/state.json");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(obj).toJson());
    }
}

void PodcastEngine::loadLastState() {
    QFile file(m_storagePath + "/state.json");
    if (file.open(QIODevice::ReadOnly)) {
        QJsonObject obj = QJsonDocument::fromJson(file.readAll()).object();
        QString path = obj["filePath"].toString();
        if (QFile::exists(path)) {
            m_currentShowTitle = obj["showTitle"].toString();
            m_currentTrackTitle = obj["epTitle"].toString();
            m_currentFilePath = path;
            m_resumeSeekPos = obj["position"].toVariant().toLongLong();

            m_player->setSource(QUrl::fromLocalFile(m_currentFilePath));
            emit currentTrackTitleChanged();
        }
    }
}

void PodcastEngine::volumeUp() {
    QProcess::startDetached("pactl", QStringList() << "set-sink-volume" << "@DEFAULT_SINK@" << "+5%");
    m_currentVolume = qMin(100, m_currentVolume + 5);
    emit volumeChanged();
    buzz(20);
}

void PodcastEngine::volumeDown() {
    QProcess::startDetached("pactl", QStringList() << "set-sink-volume" << "@DEFAULT_SINK@" << "-5%");
    m_currentVolume = qMax(0, m_currentVolume - 5);
    emit volumeChanged();
    buzz(20);
}

void PodcastEngine::refreshVolume() {
    QProcess proc;
    proc.start("sh", QStringList() << "-c" << "pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%'");
    if (proc.waitForFinished(800)) {
        QString out = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
        if (!out.isEmpty()) {
            m_currentVolume = out.toInt();
            emit volumeChanged();
        }
    }
}

void PodcastEngine::buzz(int ms) {
    QFile file("/sys/class/timed_output/vibrator/enable");
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QByteArray::number(ms));
        file.close();
    }
}

void PodcastEngine::refreshDownloads() {
    m_downloadedEpisodes.clear();
    QDir rootDir(m_storagePath);
    QStringList showDirs = rootDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QString &showDirName : showDirs) {
        QDir showDir(m_storagePath + "/" + showDirName);
        QFileInfoList files = showDir.entryInfoList(QStringList() << "*.mp3" << "*.m4a", QDir::Files, QDir::Time);

        for (const QFileInfo &fi : files) {
            QVariantMap item;
            item["showTitle"] = showDirName;
            item["epTitle"] = fi.completeBaseName();
            item["filePath"] = fi.absoluteFilePath();
            item["sizeMB"] = QString::number(fi.size() / 1024.0 / 1024.0, 'f', 1) + " MB";
            m_downloadedEpisodes.append(item);
        }
    }
    emit downloadedEpisodesChanged();
}

void PodcastEngine::search(const QString &term) {
    if (term.trimmed().isEmpty()) return;
    m_isSearching = true;
    emit searchingChanged();

    QUrl url("https://itunes.apple.com/search");
    QUrlQuery query;
    query.addQueryItem("term", term);
    query.addQueryItem("media", "podcast");
    query.addQueryItem("entity", "podcast");
    query.addQueryItem("limit", "15");
    url.setQuery(query);

    QNetworkReply *reply = m_net->get(QNetworkRequest(url));
    connect(reply, &QNetworkReply::finished, this, &PodcastEngine::onSearchFinished);
}

void PodcastEngine::onSearchFinished() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    m_searchResults.clear();
    if (reply->error() == QNetworkReply::NoError) {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray results = doc.object()["results"].toArray();
        for (const QJsonValue &val : results) {
            QJsonObject obj = val.toObject();
            QVariantMap item;
            item["title"] = obj["collectionName"].toString();
            item["artist"] = obj["artistName"].toString();
            item["feedUrl"] = obj["feedUrl"].toString();
            item["artworkUrl"] = obj["artworkUrl600"].toString().isEmpty() ? obj["artworkUrl100"].toString() : obj["artworkUrl600"].toString();
            m_searchResults.append(item);
        }
    }
    reply->deleteLater();
    m_isSearching = false;
    emit searchingChanged();
    emit searchResultsChanged();
}

void PodcastEngine::subscribe(const QString &title, const QString &feedUrl) {
    for (const QVariant &v : m_subscriptions) {
        if (v.toMap()["feedUrl"].toString() == feedUrl) return;
    }
    QVariantMap item;
    item["title"] = title;
    item["feedUrl"] = feedUrl;
    m_subscriptions.append(item);
    saveSubscriptions();
    emit subscriptionsChanged();
}

void PodcastEngine::unsubscribe(const QString &feedUrl) {
    for (int i = 0; i < m_subscriptions.size(); ++i) {
        if (m_subscriptions[i].toMap()["feedUrl"].toString() == feedUrl) {
            m_subscriptions.removeAt(i);
            saveSubscriptions();
            emit subscriptionsChanged();
            return;
        }
    }
}

void PodcastEngine::loadEpisodes(const QString &showTitle, const QString &feedUrl) {
    m_currentShowLoading = showTitle;
    m_episodes.clear();

    QString showDir = m_storagePath + "/" + sanitizeFilename(showTitle);
    QDir dir(showDir);
    QFileInfoList fileList = dir.entryInfoList(QStringList() << "*.mp3" << "*.m4a", QDir::Files, QDir::Time);

    for (const QFileInfo &fi : fileList) {
        QVariantMap ep;
        ep["title"] = fi.completeBaseName();
        ep["pubDate"] = fi.lastModified().toString("MMM d, yyyy");
        ep["audioUrl"] = QUrl::fromLocalFile(fi.absoluteFilePath()).toString();
        ep["isDownloaded"] = true;
        m_episodes.append(ep);
    }
    emit episodesChanged();

    m_isLoadingEpisodes = true;
    emit loadingEpisodesChanged();

    QNetworkReply *reply = m_net->get(QNetworkRequest(QUrl(feedUrl)));
    connect(reply, &QNetworkReply::finished, this, &PodcastEngine::onFeedFinished);
}

void PodcastEngine::onFeedFinished() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        QXmlStreamReader xml(reply->readAll());
        QVariantList freshEpisodes;
        QVariantMap currentEpisode;
        bool inItem = false;
        int count = 0;

        while (!xml.atEnd() && !xml.hasError() && count < 25) {
            QXmlStreamReader::TokenType token = xml.readNext();
            if (token == QXmlStreamReader::StartElement) {
                QString name = xml.name().toString();
                if (name == "item") {
                    inItem = true;
                    currentEpisode.clear();
                } else if (inItem) {
                    if (name == "title") {
                        currentEpisode["title"] = xml.readElementText();
                    } else if (name == "pubDate") {
                        currentEpisode["pubDate"] = xml.readElementText();
                    } else if (name == "enclosure") {
                        QXmlStreamAttributes attrs = xml.attributes();
                        currentEpisode["audioUrl"] = attrs.value("url").toString();
                    }
                }
            } else if (token == QXmlStreamReader::EndElement) {
                if (xml.name().toString() == "item" && inItem) {
                    inItem = false;
                    if (!currentEpisode["audioUrl"].toString().isEmpty()) {
                        QString filePath = episodeFilePath(m_currentShowLoading, currentEpisode["title"].toString());
                        currentEpisode["isDownloaded"] = QFile::exists(filePath);
                        freshEpisodes.append(currentEpisode);
                        count++;
                    }
                }
            }
        }

        if (!freshEpisodes.isEmpty()) {
            m_episodes = freshEpisodes;
        }
    }

    reply->deleteLater();
    m_isLoadingEpisodes = false;
    emit loadingEpisodesChanged();
    emit episodesChanged();
}

void PodcastEngine::downloadEpisode(const QString &showTitle, const QString &epTitle, const QString &audioUrl) {
    if (m_isDownloading) return;

    QString filePath = episodeFilePath(showTitle, epTitle);
    QDir().mkpath(QFileInfo(filePath).dir().path());

    m_currentDownloadFile = new QFile(filePath, this);
    if (!m_currentDownloadFile->open(QIODevice::WriteOnly)) {
        delete m_currentDownloadFile;
        m_currentDownloadFile = nullptr;
        return;
    }

    m_isDownloading = true;
    m_downloadProgress = 0;
    emit downloadingChanged();
    emit downloadProgressChanged();

    m_currentDownloadReply = m_net->get(QNetworkRequest(QUrl(audioUrl)));
    connect(m_currentDownloadReply, &QNetworkReply::downloadProgress, this, &PodcastEngine::onDownloadProgress);
    connect(m_currentDownloadReply, &QNetworkReply::readyRead, this, [this]() {
        if (m_currentDownloadFile) m_currentDownloadFile->write(m_currentDownloadReply->readAll());
    });
    connect(m_currentDownloadReply, &QNetworkReply::finished, this, &PodcastEngine::onDownloadFinished);
}

void PodcastEngine::onDownloadProgress(qint64 received, qint64 total) {
    if (total > 0) {
        m_downloadProgress = static_cast<int>((received * 100) / total);
        emit downloadProgressChanged();
    }
}

void PodcastEngine::onDownloadFinished() {
    if (m_currentDownloadFile) {
        m_currentDownloadFile->close();
        delete m_currentDownloadFile;
        m_currentDownloadFile = nullptr;
    }
    if (m_currentDownloadReply) {
        m_currentDownloadReply->deleteLater();
        m_currentDownloadReply = nullptr;
    }

    m_isDownloading = false;
    m_downloadProgress = 100;
    emit downloadingChanged();
    emit downloadProgressChanged();

    for (int i = 0; i < m_episodes.size(); ++i) {
        QVariantMap ep = m_episodes[i].toMap();
        ep["isDownloaded"] = QFile::exists(episodeFilePath(m_currentShowLoading, ep["title"].toString()));
        m_episodes[i] = ep;
    }
    emit episodesChanged();
    refreshDownloads();
}

void PodcastEngine::deleteDownloadedEpisode(const QString &showTitle, const QString &epTitle) {
    QString filePath = episodeFilePath(showTitle, epTitle);
    QFile::remove(filePath);

    for (int i = 0; i < m_episodes.size(); ++i) {
        QVariantMap ep = m_episodes[i].toMap();
        if (ep["title"].toString() == epTitle) {
            ep["isDownloaded"] = false;
            m_episodes[i] = ep;
            emit episodesChanged();
            break;
        }
    }
    refreshDownloads();
}

void PodcastEngine::playEpisode(const QString &showTitle, const QString &epTitle) {
    m_currentShowTitle = showTitle;
    QString filePath = episodeFilePath(showTitle, epTitle);
    playDirectFile(filePath, epTitle);
}

void PodcastEngine::playDirectFile(const QString &filePath, const QString &title, qint64 startPos) {
    if (!QFile::exists(filePath)) return;

    m_currentTrackTitle = title;
    m_currentFilePath = filePath;
    m_resumeSeekPos = startPos;
    emit currentTrackTitleChanged();

    m_player->setSource(QUrl::fromLocalFile(filePath));
    m_player->play();
}

void PodcastEngine::togglePlayPause() {
    if (m_player->playbackState() == QMediaPlayer::PlayingState) {
        m_player->pause();
    } else {
        m_player->play();
    }
}

void PodcastEngine::seek(qint64 pos) {
    m_player->setPosition(pos);
}

void PodcastEngine::skip(int seconds) {
    qint64 newPos = m_player->position() + (seconds * 1000);
    newPos = qBound(0LL, newPos, m_player->duration());
    m_player->setPosition(newPos);
}

QString PodcastEngine::sanitizeFilename(const QString &name) {
    QString s = name;
    s.replace(QRegularExpression("[/\\\\:?*\"<>|]"), "_");
    return s.trimmed().left(60);
}

QString PodcastEngine::episodeFilePath(const QString &showTitle, const QString &epTitle) {
    return QString("%1/%2/%3.mp3").arg(m_storagePath, sanitizeFilename(showTitle), sanitizeFilename(epTitle));
}

void PodcastEngine::loadSubscriptions() {
    QFile file(m_storagePath + "/subscriptions.json");
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        m_subscriptions = doc.array().toVariantList();
    }
}

void PodcastEngine::saveSubscriptions() {
    QFile file(m_storagePath + "/subscriptions.json");
    if (file.open(QIODevice::WriteOnly)) {
        QJsonArray arr = QJsonArray::fromVariantList(m_subscriptions);
        file.write(QJsonDocument(arr).toJson());
    }
}
