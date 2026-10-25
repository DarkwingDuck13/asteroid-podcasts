/*
 * =====================================================================
 * Part of the AsteroidOS Custom Software Suite
 * Architecture, Engine & UI Engineering by Gemini (Google)
 * Co-Developed & Tested on-device by DarkwingDuck13
 *
 * Platform: AsteroidOS (Linux / Qt6 / OpenEmbedded / TicWatch Pro)
 * =====================================================================
 */

#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QFile>
#include <QTimer>
#include <QProcess>

class PodcastEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList subscriptions READ subscriptions NOTIFY subscriptionsChanged)
    Q_PROPERTY(QVariantList searchResults READ searchResults NOTIFY searchResultsChanged)
    Q_PROPERTY(QVariantList episodes READ episodes NOTIFY episodesChanged)
    Q_PROPERTY(QVariantList downloadedEpisodes READ downloadedEpisodes NOTIFY downloadedEpisodesChanged)
    Q_PROPERTY(bool searching READ isSearching NOTIFY searchingChanged)
    Q_PROPERTY(bool loadingEpisodes READ isLoadingEpisodes NOTIFY loadingEpisodesChanged)
    Q_PROPERTY(int downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(bool downloading READ isDownloading NOTIFY downloadingChanged)

    // Player & State Properties
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString currentTrackTitle READ currentTrackTitle NOTIFY currentTrackTitleChanged)
    Q_PROPERTY(int currentVolume READ currentVolume NOTIFY volumeChanged)
    
    // Live Audio Level (0.0 to 1.0)
    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY audioLevelChanged)

public:
    explicit PodcastEngine(QObject *parent = nullptr);
    ~PodcastEngine();

    QVariantList subscriptions() const { return m_subscriptions; }
    QVariantList searchResults() const { return m_searchResults; }
    QVariantList episodes() const { return m_episodes; }
    QVariantList downloadedEpisodes() const { return m_downloadedEpisodes; }
    bool isSearching() const { return m_isSearching; }
    bool isLoadingEpisodes() const { return m_isLoadingEpisodes; }
    int downloadProgress() const { return m_downloadProgress; }
    bool isDownloading() const { return m_isDownloading; }

    bool isPlaying() const { return m_player->playbackState() == QMediaPlayer::PlayingState; }
    qint64 position() const { return m_player->position(); }
    qint64 duration() const { return m_player->duration(); }
    QString currentTrackTitle() const { return m_currentTrackTitle; }
    int currentVolume() const { return m_currentVolume; }
    qreal audioLevel() const { return m_audioLevel; }

    Q_INVOKABLE void search(const QString &term);
    Q_INVOKABLE void subscribe(const QString &title, const QString &feedUrl);
    Q_INVOKABLE void unsubscribe(const QString &feedUrl);
    Q_INVOKABLE void loadEpisodes(const QString &showTitle, const QString &feedUrl);
    Q_INVOKABLE void downloadEpisode(const QString &showTitle, const QString &epTitle, const QString &audioUrl);
    Q_INVOKABLE void deleteDownloadedEpisode(const QString &showTitle, const QString &epTitle);
    Q_INVOKABLE void refreshDownloads();
    
    // Playback & Hardware Volume Controls
    Q_INVOKABLE void playEpisode(const QString &showTitle, const QString &epTitle);
    Q_INVOKABLE void playDirectFile(const QString &filePath, const QString &title, qint64 startPos = 0);
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void seek(qint64 pos);
    Q_INVOKABLE void skip(int seconds);
    Q_INVOKABLE void volumeUp();
    Q_INVOKABLE void volumeDown();

    // Visualizer Lifecycle (Stops CPU drain when screen is off or away from player)
    Q_INVOKABLE void setVisualizerActive(bool active);

    // Haptics & Power
    Q_INVOKABLE void buzz(int ms = 25);

signals:
    void subscriptionsChanged();
    void searchResultsChanged();
    void episodesChanged();
    void downloadedEpisodesChanged();
    void searchingChanged();
    void loadingEpisodesChanged();
    void downloadProgressChanged();
    void downloadingChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void currentTrackTitleChanged();
    void volumeChanged();
    void audioLevelChanged();

private slots:
    void onSearchFinished();
    void onFeedFinished();
    void onDownloadProgress(qint64 received, qint64 total);
    void onDownloadFinished();
    void onPlaybackStateChanged(QMediaPlayer::PlaybackState state);
    void onMediaStatusChanged(QMediaPlayer::MediaStatus status);
    void autoSaveState();
    void onLevelDataReady();

private:
    QNetworkAccessManager *m_net;
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    QTimer *m_saveTimer;
    QProcess *m_levelProc = nullptr;

    QVariantList m_subscriptions;
    QVariantList m_searchResults;
    QVariantList m_episodes;
    QVariantList m_downloadedEpisodes;

    bool m_isSearching = false;
    bool m_isLoadingEpisodes = false;
    bool m_isDownloading = false;
    int m_downloadProgress = 0;
    int m_currentVolume = 75;
    qreal m_audioLevel = 0.0;
    bool m_visualizerActive = true;

    QString m_currentTrackTitle;
    QString m_currentShowTitle;
    QString m_currentFilePath;
    QString m_currentShowLoading;
    QString m_storagePath;
    qint64 m_resumeSeekPos = 0;

    QNetworkReply *m_currentDownloadReply = nullptr;
    QFile *m_currentDownloadFile = nullptr;

    void loadSubscriptions();
    void saveSubscriptions();
    void loadLastState();
    void saveCurrentState();
    void acquireWakeLock();
    void releaseWakeLock();
    void refreshVolume();
    void startLevelMonitor();
    void stopLevelMonitor();
    QString sanitizeFilename(const QString &name);
    QString episodeFilePath(const QString &showTitle, const QString &epTitle);
};
