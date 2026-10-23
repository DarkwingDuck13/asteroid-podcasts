#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QFile>

class PodcastEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList subscriptions READ subscriptions NOTIFY subscriptionsChanged)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchResultsChanged)
    Q_PROPERTY(QVariantList episodes READ episodes NOTIFY episodesChanged)
    Q_PROPERTY(bool searching READ isSearching NOTIFY searchingChanged)
    Q_PROPERTY(bool loadingEpisodes READ isLoadingEpisodes NOTIFY loadingEpisodesChanged)
    Q_PROPERTY(int downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(bool downloading READ isDownloading NOTIFY downloadingChanged)

    // Player Properties
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString currentTrackTitle READ currentTrackTitle NOTIFY currentTrackTitleChanged)

public:
    explicit PodcastEngine(QObject *parent = nullptr);
    ~PodcastEngine();

    QVariantList subscriptions() const { return m_subscriptions; }
    QVariantList searchResults() const { return m_searchResults; }
    QVariantList episodes() const { return m_episodes; }
    bool isSearching() const { return m_isSearching; }
    bool isLoadingEpisodes() const { return m_isLoadingEpisodes; }
    int downloadProgress() const { return m_downloadProgress; }
    bool isDownloading() const { return m_isDownloading; }

    bool isPlaying() const { return m_player->playbackState() == QMediaPlayer::PlayingState; }
    qint64 position() const { return m_player->position(); }
    qint64 duration() const { return m_player->duration(); }
    QString currentTrackTitle() const { return m_currentTrackTitle; }

    Q_INVOKABLE void search(const QString &term);
    Q_INVOKABLE void subscribe(const QString &title, const QString &feedUrl);
    Q_INVOKABLE void unsubscribe(const QString &feedUrl);
    Q_INVOKABLE void loadEpisodes(const QString &showTitle, const QString &feedUrl);
    Q_INVOKABLE void downloadEpisode(const QString &showTitle, const QString &epTitle, const QString &audioUrl);
    Q_INVOKABLE void deleteDownloadedEpisode(const QString &showTitle, const QString &epTitle);
    Q_INVOKABLE void buzz(int ms = 20);
    
    // Playback Controls
    Q_INVOKABLE void playEpisode(const QString &showTitle, const QString &epTitle);
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void seek(qint64 pos);
    Q_INVOKABLE void skip(int seconds);

signals:
    void subscriptionsChanged();
    void searchResultsChanged();
    void episodesChanged();
    void searchingChanged();
    void loadingEpisodesChanged();
    void downloadProgressChanged();
    void downloadingChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void currentTrackTitleChanged();

private slots:
    void onSearchFinished();
    void onFeedFinished();
    void onDownloadProgress(qint64 received, qint64 total);
    void onDownloadFinished();

private:
    QNetworkAccessManager *m_net;
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;

    QVariantList m_subscriptions;
    QVariantList m_searchResults;
    QVariantList m_episodes;

    bool m_isSearching = false;
    bool m_isLoadingEpisodes = false;
    bool m_isDownloading = false;
    int m_downloadProgress = 0;

    QString m_currentTrackTitle;
    QString m_currentShowLoading;
    QString m_storagePath;

    // Download state
    QNetworkReply *m_currentDownloadReply = nullptr;
    QFile *m_currentDownloadFile = nullptr;

    void loadSubscriptions();
    void saveSubscriptions();
    QString sanitizeFilename(const QString &name);
    QString episodeFilePath(const QString &showTitle, const QString &epTitle);
};
