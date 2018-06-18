import Foundation
import UIKit
import Gridicons
import WordPressShared
import SVProgressHUD
import WordPressFlux

class AppSettingsViewController: UITableViewController {
    enum Sections: Int {
        case media
        case other
    }

    fileprivate var handler: ImmuTableViewHandler!
    fileprivate static let aztecEditorFooterHeight = CGFloat(34.0)

    // MARK: - Initialization

    override init(style: UITableViewStyle) {
        super.init(style: style)
        navigationItem.title = NSLocalizedString("App Settings", comment: "App Settings Title")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required convenience init() {
        self.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImmuTable.registerRows([
            DestructiveButtonRow.self,
            TextRow.self,
            ImageSizingRow.self,
            SwitchRow.self,
            NavigationItemRow.self
            ], tableView: self.tableView)

        handler = ImmuTableViewHandler(takeOver: self)
        reloadViewModel()

        WPStyleGuide.configureColors(for: view, andTableView: tableView)
        WPStyleGuide.configureAutomaticHeightRows(for: tableView)

        addAccountSettingsChangedObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMediaCacheSize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerUserActivity()
    }

    private func addAccountSettingsChangedObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(accountSettingsDidChange(_:)), name: NSNotification.Name.AccountSettingsChanged, object: nil)
    }

    @objc
    private func accountSettingsDidChange(_ notification: Notification) {
        reloadViewModel()
    }

    // MARK: - Model mapping

    fileprivate func reloadViewModel() {
        handler.viewModel = tableViewModel()
    }

    func tableViewModel() -> ImmuTable {
        let mediaHeader = NSLocalizedString("Media", comment: "Title label for the media settings section in the app settings")
        let imageSizingRow = ImageSizingRow(
            title: NSLocalizedString("Max Image Upload Size", comment: "Title for the image size settings option."),
            value: Int(MediaSettings().maxImageSizeSetting),
            onChange: imageSizeChanged())

        let videoSizingRow = NavigationItemRow(
            title: NSLocalizedString("Max Video Upload Size", comment: "Title for the video size settings option."),
            detail: MediaSettings().maxVideoSizeSetting.description,
            action: pushVideoResolutionSettings())

        let mediaCacheRow = TextRow(title: NSLocalizedString("Media Cache Size", comment: "Label for size of media cache in the app."),
                                    value: mediaCacheRowDescription)

        let mediaClearCacheRow = DestructiveButtonRow(
            title: NSLocalizedString("Clear Device Media Cache", comment: "Label for button that clears all media cache."),
            action: { [weak self] row in
                self?.clearMediaCache()
            },
            accessibilityIdentifier: "mediaClearCacheButton")

        let editorSettings = EditorSettings()
        let _ = NSLocalizedString("Editor", comment: "Title label for the editor settings section in the app settings")
        var editorRows = [ImmuTableRow]()

        let nativeEditor = CheckmarkRow(
            title: NSLocalizedString("Visual", comment: "Option to enable the Aztec editor."),
            checked: editorSettings.isEnabled(.aztec),
            action: enableEditor(.aztec)
        )
        editorRows.append(nativeEditor)

        let privacyHeader = NSLocalizedString("Privacy", comment: "Privacy settings section header")
        let mediaRemoveLocation = SwitchRow(
            title: NSLocalizedString("Remove Location From Media", comment: "Option to enable the removal of location information/gps from photos and videos"),
            value: Bool(MediaSettings().removeLocationSetting),
            onChange: mediaRemoveLocationChanged()
        )
        let privacySettings = NavigationItemRow(
            title: NSLocalizedString("Privacy Settings", comment: "Link to privacy settings page"),
            action: openPrivacySettings()
        )

        let otherHeader = NSLocalizedString("Other", comment: "Link to About section (contains info about the app)")
        let spotlightClearCacheRow = DestructiveButtonRow(
            title: NSLocalizedString("Clear Spotlight Index", comment: "Label for button that clears the spotlight index on device."),
            action: clearSpotlightCache(),
            accessibilityIdentifier: "spotlightClearCacheButton")

        let settingsRow = NavigationItemRow(
            title: NSLocalizedString("Open Device Settings", comment: "Opens iOS's Device Settings for WordPress App"),
            action: openApplicationSettings()
        )

        let aboutRow = NavigationItemRow(
            title: NSLocalizedString("About WordPress for iOS", comment: "Link to About screen for WordPress for iOS"),
            action: pushAbout()
        )

        return ImmuTable(sections: [
            ImmuTableSection(
                headerText: mediaHeader,
                rows: [
                    imageSizingRow,
                    videoSizingRow,
                    mediaCacheRow,
                    mediaClearCacheRow
                ],
                footerText: NSLocalizedString("Free up storage space on this device by clearing your temporary media files. This will not affect media on your site.", comment: "Explanatory text for clearing device media cache.")
            ),
            ImmuTableSection(
                headerText: privacyHeader,
                rows: [
                    mediaRemoveLocation,
                    privacySettings
                ]
            ),
            ImmuTableSection(
                headerText: otherHeader,
                rows: [
                    spotlightClearCacheRow,
                    settingsRow,
                    aboutRow
                ],
                footerText: nil)
            ])
    }

    // MARK: - Media cache methods

    fileprivate enum MediaCacheSettingsStatus {
        case calculatingSize
        case clearingCache
        case unknown
        case empty
    }

    fileprivate var mediaCacheRowDescription = "" {
        didSet {
            reloadViewModel()
        }
    }

    fileprivate func setMediaCacheRowDescription(allocatedSize: Int64?) {
        guard let allocatedSize = allocatedSize else {
            setMediaCacheRowDescription(status: .unknown)
            return
        }
        if allocatedSize == 0 {
            setMediaCacheRowDescription(status: .empty)
            return
        }
        mediaCacheRowDescription = ByteCountFormatter.string(fromByteCount: allocatedSize, countStyle: ByteCountFormatter.CountStyle.file)
    }

    fileprivate func setMediaCacheRowDescription(status: MediaCacheSettingsStatus) {
        switch status {
        case .clearingCache:
            mediaCacheRowDescription = NSLocalizedString("Clearing...", comment: "Label for size of media while it's being cleared.")
        case .calculatingSize:
            mediaCacheRowDescription = NSLocalizedString("Calculating...", comment: "Label for size of media while it's being calculated.")
        case .unknown:
            mediaCacheRowDescription = NSLocalizedString("Unknown", comment: "Label for size of media when it's not possible to calculate it.")
        case .empty:
            mediaCacheRowDescription = NSLocalizedString("Empty", comment: "Label for size of media when the cache is empty.")
        }
    }

    fileprivate func updateMediaCacheSize() {
        setMediaCacheRowDescription(status: .calculatingSize)
        MediaFileManager.calculateSizeOfMediaCacheDirectory { [weak self] (allocatedSize) in
            self?.setMediaCacheRowDescription(allocatedSize: allocatedSize)
        }
    }

    fileprivate func clearMediaCache() {
        setMediaCacheRowDescription(status: .clearingCache)
        MediaFileManager.clearAllMediaCacheFiles(onCompletion: { [weak self] in
            self?.updateMediaCacheSize()
            }, onError: { [weak self] (error) in
                self?.updateMediaCacheSize()
        })
    }

    // MARK: - Actions

    @objc func imageSizeChanged() -> (Int) -> Void {
        return { value in
            MediaSettings().maxImageSizeSetting = value
            ShareExtensionService.configureShareExtensionMaximumMediaDimension(value)

            var properties = [String: AnyObject]()
            properties["enabled"] = (value != Int.max) as AnyObject
            properties["value"] = value as Int as AnyObject
            WPAnalytics.track(.appSettingsImageOptimizationChanged, withProperties: properties)
        }
    }

    func pushVideoResolutionSettings() -> ImmuTableAction {
        return { [weak self] row in
            let values = [MediaSettings.VideoResolution.size640x480,
                          MediaSettings.VideoResolution.size1280x720,
                          MediaSettings.VideoResolution.size1920x1080,
                          MediaSettings.VideoResolution.size3840x2160,
                          MediaSettings.VideoResolution.sizeOriginal]

            let titles = values.map({ (settings: MediaSettings.VideoResolution) -> String in
                settings.description
            })

            let currentVideoResolution = MediaSettings().maxVideoSizeSetting

            let settingsSelectionConfiguration = [SettingsSelectionDefaultValueKey: currentVideoResolution,
                                                  SettingsSelectionTitleKey: NSLocalizedString("Resolution", comment: "The largest resolution allowed for uploading"),
                                                  SettingsSelectionTitlesKey: titles,
                                                  SettingsSelectionValuesKey: values] as [String: Any]

            let viewController = SettingsSelectionViewController(dictionary: settingsSelectionConfiguration)

            viewController?.onItemSelected = { (resolution: Any!) -> () in
                let newResolution = resolution as! MediaSettings.VideoResolution
                MediaSettings().maxVideoSizeSetting = newResolution

                var properties = [String: AnyObject]()
                properties["enabled"] = (newResolution != MediaSettings.VideoResolution.sizeOriginal) as AnyObject
                properties["value"] = newResolution.description as AnyObject
                WPAnalytics.track(.appSettingsVideoOptimizationChanged, withProperties: properties)
            }

            self?.navigationController?.pushViewController(viewController!, animated: true)
        }
    }

    @objc func mediaRemoveLocationChanged() -> (Bool) -> Void {
        return { value in
            MediaSettings().removeLocationSetting = value
            WPAnalytics.track(.appSettingsMediaRemoveLocationChanged, withProperties: ["enabled": value as AnyObject])
        }
    }

    func enableEditor(_ editor: EditorSettings.Editor) -> ImmuTableAction {
        return { [weak self] _ in
            EditorSettings().enable(editor)
            self?.reloadViewModel()
        }
    }

    func pushAbout() -> ImmuTableAction {
        return { [weak self] row in
            let controller = AboutViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func openPrivacySettings() -> ImmuTableAction {
        return { [weak self] _ in
            let controller = PrivacySettingsViewController()
            self?.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func openApplicationSettings() -> ImmuTableAction {
        return { [weak self] row in
            if let targetURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(targetURL)

            } else {
                assertionFailure("Couldn't unwrap Settings URL")
            }

            self?.tableView.deselectSelectedRowWithAnimation(true)
        }
    }

    func clearSpotlightCache() -> ImmuTableAction {
        return { [weak self] row in
            self?.tableView.deselectSelectedRowWithAnimation(true)
            SearchManager.shared.deleteAllSearchableItems()
            let notice = Notice(title: NSLocalizedString("Successfully cleared spotlight index", comment: "Notice displayed to the user after clearing the spotlight index in app settings."),
                                feedbackType: .success)
            ActionDispatcher.dispatch(NoticeAction.post(notice))
        }
    }
}

// MARK: - SearchableActivity Conformance

extension AppSettingsViewController: SearchableActivityConvertable {
    var activityType: String {
        return WPActivityType.appSettings.rawValue
    }

    var activityTitle: String {
        return NSLocalizedString("App Settings", comment: "Title of the 'App Settings' screen within the 'Me' tab - used for spotlight indexing on iOS.")
    }

    var activityKeywords: Set<String>? {
        let keyWordString = NSLocalizedString("wordpress, me, app settings, settings, cache, media, about, upload, usage, statistics",
                                              comment: "This is a comma separated list of keywords used for spotlight indexing of the 'Me' tab.")
        let keywordArray = keyWordString.arrayOfTags()

        guard !keywordArray.isEmpty else {
            return nil
        }

        return Set(keywordArray)
    }
}

// MARK: - Private ImmuTableRow Definitions

fileprivate struct ImageSizingRow: ImmuTableRow {
    typealias CellType = MediaSizeSliderCell

    static let cell: ImmuTableCell = {
        let nib = UINib(nibName: "MediaSizeSliderCell", bundle: Bundle(for: CellType.self))
        return ImmuTableCell.nib(nib, CellType.self)
    }()
    static let customHeight: Float? = CellType.height

    let title: String
    let value: Int
    let onChange: (Int) -> Void

    let action: ImmuTableAction? = nil

    func configureCell(_ cell: UITableViewCell) {
        let cell = cell as! CellType

        cell.title = title
        cell.value = value
        cell.onChange = onChange
        cell.selectionStyle = .none

        (cell.minValue, cell.maxValue) = MediaSettings().allowedImageSizeRange
    }
}
