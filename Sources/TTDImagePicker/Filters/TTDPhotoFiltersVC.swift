import UIKit

public protocol IsMediaFilterVC: class {
    var didSave: ((TTDMediaItem) -> Void)? { get set }
    var didCancel: (() -> Void)? { get set }
}

open class TTDPhotoFiltersVC: UIViewController, IsMediaFilterVC, UIGestureRecognizerDelegate {
    
    required public init(inputPhoto: TTDMediaPhoto, isFromSelectionVC: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.inputPhoto = inputPhoto
        self.isFromSelectionVC = isFromSelectionVC
    }
    
    public var inputPhoto: TTDMediaPhoto!
    public var isFromSelectionVC = false

    public var didSave: ((TTDMediaItem) -> Void)?
    public var didCancel: (() -> Void)?


    fileprivate let filters: [TTDFilter] = TTDConfig.filters

    fileprivate var selectedFilter: TTDFilter?
    
    fileprivate var filteredThumbnailImagesArray: [UIImage] = []
    fileprivate var thumbnailImageForFiltering: CIImage? // Small image for creating filters thumbnails
    fileprivate var currentlySelectedImageThumbnail: UIImage? // Used for comparing with original image when tapped

    fileprivate var v = TTDFiltersView()

    override open var prefersStatusBarHidden: Bool { return TTDConfig.hidesStatusBar }
    override open func loadView() { view = v }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Life Cycle ♻️

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup of main image an thumbnail images
        v.imageView.image = inputPhoto.image
        thumbnailImageForFiltering = thumbFromImage(inputPhoto.image)
        DispatchQueue.global().async {
            self.filteredThumbnailImagesArray = self.filters.map { filter -> UIImage in
                if let applier = filter.applier,
                    let thumbnailImage = self.thumbnailImageForFiltering,
                    let outputImage = applier(thumbnailImage) {
                    return outputImage.toUIImage()
                } else {
                    return self.inputPhoto.originalImage
                }
            }
            DispatchQueue.main.async {
                self.v.collectionView.reloadData()
                self.v.collectionView.selectItem(at: IndexPath(row: 0, section: 0),
                                            animated: false,
                                            scrollPosition: UICollectionView.ScrollPosition.bottom)
                self.v.filtersLoader.stopAnimating()
            }
        }
        
        // Setup of Collection View
        v.collectionView.register(TTDFilterCollectionViewCell.self, forCellWithReuseIdentifier: "FilterCell")
        v.collectionView.dataSource = self
        v.collectionView.delegate = self

        view.backgroundColor = TTDConfig.colors.filterBackgroundColor
        
        // Setup of Navigation Bar
        title = TTDConfig.wordings.filter
        if isFromSelectionVC {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: TTDConfig.wordings.cancel,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(cancel))
        }
        setupRightBarButton()
        
        TTDHelper.changeBackButtonIcon(self)
        TTDHelper.changeBackButtonTitle(self)
        
        // Touch preview to see original image.
        let touchDownGR = UILongPressGestureRecognizer(target: self,
                                                       action: #selector(handleTouchDown))
        touchDownGR.minimumPressDuration = 0
        touchDownGR.delegate = self
        v.imageView.addGestureRecognizer(touchDownGR)
        v.imageView.isUserInteractionEnabled = true
    }
    
    // MARK: Setup - ⚙️
    fileprivate func setupRightBarButton() {
        let rightBarButtonTitle = isFromSelectionVC ? TTDConfig.wordings.done : TTDConfig.wordings.next
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: rightBarButtonTitle,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = TTDConfig.colors.tintColor
    }
    
    // MARK: - Methods 🏓

    @objc
    fileprivate func handleTouchDown(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            v.imageView.image = inputPhoto.originalImage
        case .ended:
            v.imageView.image = currentlySelectedImageThumbnail ?? inputPhoto.originalImage
        default: ()
        }
    }
    
    fileprivate func thumbFromImage(_ img: UIImage) -> CIImage {
        let k = img.size.width / img.size.height
        let scale = UIScreen.main.scale
        let thumbnailHeight: CGFloat = 300 * scale
        let thumbnailWidth = thumbnailHeight * k
        let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)
        UIGraphicsBeginImageContext(thumbnailSize)
        img.draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
        let smallImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return smallImage!.toCIImage()!
    }
    
    // MARK: - Actions 🥂

    @objc
    func cancel() {
        didCancel?()
    }
    
    @objc
    func save() {
        guard let didSave = didSave else { return print("Don't have saveCallback") }
        self.navigationItem.rightBarButtonItem = TTDLoaders.defaultLoader

        DispatchQueue.global().async {
            if let f = self.selectedFilter,
                let applier = f.applier,
                let ciImage = self.inputPhoto.originalImage.toCIImage(),
                let modifiedFullSizeImage = applier(ciImage) {
                self.inputPhoto.modifiedImage = modifiedFullSizeImage.toUIImage()
            } else {
                self.inputPhoto.modifiedImage = nil
            }
            DispatchQueue.main.async {
                didSave(TTDMediaItem.photo(p: self.inputPhoto))
                self.setupRightBarButton()
            }
        }
    }
}

extension TTDPhotoFiltersVC: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredThumbnailImagesArray.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let filter = filters[indexPath.row]
        let image = filteredThumbnailImagesArray[indexPath.row]
        if let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "FilterCell",
                                 for: indexPath) as? TTDFilterCollectionViewCell {
            cell.name.text = filter.name
            cell.imageView.image = image
            return cell
        }
        return UICollectionViewCell()
    }
}

extension TTDPhotoFiltersVC: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedFilter = filters[indexPath.row]
        currentlySelectedImageThumbnail = filteredThumbnailImagesArray[indexPath.row]
        self.v.imageView.image = currentlySelectedImageThumbnail
    }
}
