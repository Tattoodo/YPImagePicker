import UIKit
import AVFoundation

/// A video view that contains video layer, supports play, pause and other actions.
/// Supports xib initialization.
public class TTDVideoView: UIView {
    public let playImageView = UIImageView(image: nil)
    
    internal let playerView = UIView()
    internal let playerLayer = AVPlayerLayer()
    internal var previewImageView = UIImageView()
    
    public var player: AVPlayer {
        guard playerLayer.player != nil else {
            return AVPlayer()
        }
        playImageView.image = TTDConfig.icons.playImage
        return playerLayer.player!
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    internal func setup() {
        let singleTapGR = UITapGestureRecognizer(target: self,
                                                 action: #selector(singleTap))
        singleTapGR.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGR)
        
        // Loop playback
        addReachEndObserver()
    
        playerView.alpha = 0
        playImageView.alpha = 0.8
        playerLayer.videoGravity = .resizeAspect
        previewImageView.contentMode = .scaleAspectFit

        [previewImageView, playerView, playImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),

            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            playImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: centerYAnchor)

        ])

        playerView.layer.addSublayer(playerLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = playerView.bounds
    }
    
    @objc internal func singleTap() {
        pauseUnpause()
    }
    
    @objc public func playerItemDidReachEnd(_ note: Notification) {
        player.actionAtItemEnd = .none
        player.seek(to: CMTime.zero)
        player.play()
    }
}

// MARK: - Video handling
extension TTDVideoView {
    /// The main load video method
    public func loadVideo<T>(_ item: T) {
        var player: AVPlayer
        
        switch item.self {
        case let video as TTDMediaVideo:
            player = AVPlayer(url: video.url)
        case let url as URL:
            player = AVPlayer(url: url)
        case let playerItem as AVPlayerItem:
            player = AVPlayer(playerItem: playerItem)
        default:
            return
        }
        
        playerLayer.player = player
        playerView.alpha = 1
        setNeedsLayout()
    }
    
    /// Convenience func to pause or unpause video dependely of state
    public func pauseUnpause() {
        (player.rate == 0.0) ? play() : pause()
    }

    /// Mute or unmute the video
    public func muteUnmute() {
        player.isMuted = !player.isMuted
    }
    
    public func play() {
        player.play()
        showPlayImage(show: false)
        addReachEndObserver()
    }
    
    public func pause() {
        player.pause()
        showPlayImage(show: true)
    }
    
    public func stop() {
        player.pause()
        player.seek(to: CMTime.zero)
        showPlayImage(show: true)
        removeReachEndObserver()
    }
    
    public func deallocate() {
        playerLayer.player = nil
        playImageView.image = nil
    }
}

// MARK: - Other API
extension TTDVideoView {
    public func setPreviewImage(_ image: UIImage) {
        previewImageView.image = image
    }
    
    /// Shows or hide the play image over the view.
    public func showPlayImage(show: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.playImageView.alpha = show ? 0.8 : 0
        }
    }
    
    public func addReachEndObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    /// Removes the observer for AVPlayerItemDidPlayToEndTime. Could be needed to implement own observer
    public func removeReachEndObserver() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }
}
