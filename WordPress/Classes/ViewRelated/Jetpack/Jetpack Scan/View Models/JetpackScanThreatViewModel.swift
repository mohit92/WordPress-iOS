import Foundation

struct JetpackScanThreatViewModel {
    let iconImage: UIImage?
    let iconImageColor: UIColor
    let title: String
    let description: String?

    // Threat Details
    let detailIconImage: UIImage?
    let detailIconImageColor: UIColor
    let problemTitle: String
    let problemDescription: String
    let fixTitle: String?
    let fixDescription: String?
    let technicalDetailsTitle: String
    let technicalDetailsDescription: String
    let fileName: String?
    let fileNameBackgroundColor: UIColor
    let attributedFileContext: NSAttributedString?

    // Threat Detail Action
    let fixActionTitle: String?
    let ignoreActionTitle: String
    let ignoreActionMessage: String

    // Threat Detail Success
    let fixSuccessTitle: String
    let ignoreSuccessTitle: String

    // Threat Detail Error
    let fixErrorTitle: String
    let ignoreErrorTitle: String

    init(threat: JetpackScanThreat) {
        let status = threat.status

        iconImage = Self.iconImage(for: status)
        iconImageColor = Self.iconColor(for: status)
        title = Self.title(for: threat)
        description = Self.description(for: threat)

        // Threat Details
        detailIconImage = UIImage(named: "jetpack-scan-state-error")
        detailIconImageColor = .error
        problemTitle = Strings.details.titles.problem
        problemDescription = threat.description
        fixTitle = Self.fixTitle(for: threat)
        fixDescription = Self.fixDescription(for: threat)
        technicalDetailsTitle = Strings.details.titles.technicalDetails
        technicalDetailsDescription = Strings.details.descriptions.technicalDetails
        fileName = threat.fileName
        fileNameBackgroundColor = Constants.normal.backgroundColor
        attributedFileContext = Self.attributedString(for: threat.context)

        // Threat Details Action
        fixActionTitle = Self.fixActionTitle(for: threat)
        ignoreActionTitle = Strings.details.actions.titles.ignore
        ignoreActionMessage = Strings.details.actions.messages.ignore

        // Threat Detail Success
        fixSuccessTitle = Strings.details.success.fix
        ignoreSuccessTitle = Strings.details.success.ignore

        // Threat Details Error
        fixErrorTitle = Strings.details.error.fix
        ignoreErrorTitle = Strings.details.error.ignore
    }

    private static func fixTitle(for threat: JetpackScanThreat) -> String? {
        guard let status = threat.status else {
            return nil
        }

        let fixable = threat.fixable?.type != nil

        switch (status, fixable) {
        case (.fixed, _):
            return Strings.details.titles.fix.fixed
        case (.current, false):
            return Strings.details.titles.fix.notFixable
        default:
            return Strings.details.titles.fix.default
        }
    }

    private static func fixDescription(for threat: JetpackScanThreat) -> String? {
        guard let fixType = threat.fixable?.type else {
            return Strings.details.descriptions.fix.notFixable
        }

        let description: String

        switch fixType {
            case .replace:
                description = Strings.details.descriptions.fix.replace
            case .delete:
                description = Strings.details.descriptions.fix.delete
            case .update:
                description = Strings.details.descriptions.fix.update
            case .edit:
                description = Strings.details.descriptions.fix.edit
            case .rollback:
                if let target = threat.fixable?.target {
                    description = String(format: Strings.details.descriptions.fix.rollback.withTarget, target)
                } else {
                    description = Strings.details.descriptions.fix.rollback.withoutTarget
                }
            default:
                description = Strings.details.descriptions.fix.unknown
        }
        return description
    }

    private static func description(for threat: JetpackScanThreat) -> String? {
        let type = threat.type
        let description: String?

        switch type {
        case .core:
            description = Strings.description.core
        case .file:
            let signature = threat.signature
            description = String(format: Strings.description.file, signature)
        case .plugin:
            description = Strings.description.plugin
        case .theme:
            description = Strings.description.theme
        case .database:
            description = Strings.description.database
        default:
            description = Strings.description.unknown
        }

        return description
    }

    private static func title(for threat: JetpackScanThreat) -> String {
        let type = threat.type
        let title: String

        switch type {
        case .core:
            if let fileName = threat.fileName?.fileName() {
                title = String(format: Strings.titles.core.multiple, fileName)
            } else {
                title = Strings.titles.core.singular
            }

        case .file:
            if let fileName = threat.fileName?.fileName() {
                title = String(format: Strings.titles.file.multiple, fileName)
            } else {
                title = Strings.titles.file.singular
            }

        case .plugin:
            if let plugin = threat.`extension` {
                title = String(format: Strings.titles.plugin.multiple, plugin.name, plugin.version)
            } else {
                title = Strings.titles.plugin.singular
            }

        case .theme:
            if let plugin = threat.`extension` {
                title = String(format: Strings.titles.theme.multiple, plugin.name, plugin.version)
            } else {
                title = Strings.titles.theme.singular
            }

        case .database:
            if let rowCount = threat.rows?.count, rowCount > 0 {
                title = String(format: Strings.titles.database.multiple, "\(rowCount)")
            } else {
                title = Strings.titles.database.singular
            }

        default:
            title = Strings.titles.unknown
        }

        return title
    }

    private static func iconColor(for status: JetpackScanThreat.ThreatStatus?) -> UIColor {
        switch status {
        case .current:
            return .error
        case .fixed:
            return .success
        default:
            return .neutral(.shade20)
        }
    }

    private static func iconImage(for status: JetpackScanThreat.ThreatStatus?) -> UIImage? {
        var image: UIImage = .gridicon(.notice)

        if status == .fixed {
            if let icon = UIImage(named: "jetpack-scan-threat-fixed") {
                image = icon
            }
        }

        return image.imageWithTintColor(.white)
    }

    private static func fixActionTitle(for threat: JetpackScanThreat) -> String? {
        guard threat.fixable?.type != nil else {
            return nil
        }

        return Strings.details.actions.titles.fixable
    }

    private struct Strings {

        struct details {

            struct titles {
                static let problem = NSLocalizedString("What was the problem?", comment: "Title for the problem section in the Threat Details")
                static let technicalDetails = NSLocalizedString("The technical details", comment: "Title for the technical details section in Threat Details")

                struct fix {
                    static let `default` = NSLocalizedString("How will we fix it?", comment: "Title for the fix section in Threat Details")
                    static let fixed = NSLocalizedString("How did Jetpack fix it?", comment: "Title for the fix section in Threat Details: Threat is fixed")
                    static let notFixable = NSLocalizedString("Resolving the threat", comment: "Title for the fix section in Threat Details: Threat is not fixable")
                }
            }

            struct descriptions {
                static let technicalDetails = NSLocalizedString("Threat found in file:", comment: "Description for threat file")

                struct fix {
                    static let replace = NSLocalizedString("Jetpack Scan will replace the affected file or directory.", comment: "Description that explains how we will fix the threat")
                    static let delete = NSLocalizedString("Jetpack Scan will delete the affected file or directory.", comment: "Description that explains how we will fix the threat")
                    static let update = NSLocalizedString("Jetpack Scan will update to a newer version.", comment: "Description that explains how we will fix the threat")
                    static let edit = NSLocalizedString("Jetpack Scan will edit the affected file or directory.", comment: "Description that explains how we will fix the threat")
                    struct rollback {
                        static let withTarget = NSLocalizedString("Jetpack Scan will rollback the affected file to the version from %1$@.", comment: "Description that explains how we will fix the threat")
                        static let withoutTarget = NSLocalizedString("Jetpack Scan will rollback the affected file to an older (clean) version.", comment: "Description that explains how we will fix the threat")
                    }

                    static let unknown = NSLocalizedString("Jetpack Scan will resolve the threat.", comment: "Description that explains how we will fix the threat")

                    static let notFixable = NSLocalizedString("Jetpack Scan cannot automatically fix this threat. We suggest that you resolve the threat manually: ensure that WordPress, your theme, and all of your plugins are up to date, and remove the offending code, theme, or plugin from your site.", comment: "Description that explains that we are unable to auto fix the threat")
                }
            }

            struct actions {

                struct titles {
                    static let ignore = NSLocalizedString("Ignore threat", comment: "Title for button that will ignore the threat")
                    static let fixable = NSLocalizedString("Fix threat", comment: "Title for button that will fix the threat")
                }

                struct messages {
                    static let ignore = NSLocalizedString("You shouldn’t ignore a security unless you are absolutely sure it’s harmless. If you choose to ignore this threat, it will remain on your site \"%1$@\".", comment: "Message displayed in ignore threat alert. %1$@ is a placeholder for the blog name.")
                }
            }

            struct success {
                static let fix = NSLocalizedString("The threat was successfully fixed.", comment: "Message displayed when a threat is fixed successfully.")
                static let ignore = NSLocalizedString("Threat ignored.", comment: "Message displayed when a threat is ignored successfully.")
            }

            struct error {
                static let fix = NSLocalizedString("Error fixing threat. Please contact our support.", comment: "Error displayed when fixing a threat fails.")
                static let ignore = NSLocalizedString("Error ignoring threat. Please contact our support.", comment: "Error displayed when ignoring a threat fails.")
            }
        }


        struct titles {
            struct core {
                static let singular = NSLocalizedString("Infected core file", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Infected core file: %1$@", comment: "Title for a threat that includes the file name of the file")
            }

            struct file {
                static let singular = NSLocalizedString("A file contains a malicious code pattern", comment: "Title for a threat")
                static let multiple = NSLocalizedString("The file %1$@ contains a malicious code pattern", comment: "Title for a threat that includes the file name of the file")
            }

            struct plugin {
                static let singular = NSLocalizedString("Vulnerable Plugin", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Vulnerable Plugin: %1$@ (version %2$@)", comment: "Title for a threat that includes the file name of the plugin and the affected version")
            }

            struct theme {
                static let singular = NSLocalizedString("Vulnerable Theme", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Vulnerable Theme %1$@ (version %2$@)", comment: "Title for a threat that includes the file name of the theme and the affected version")
            }

            struct database {
                static let singular = NSLocalizedString("Database threat", comment: "Title for a threat")
                static let multiple = NSLocalizedString("Database %1$d threats", comment: "Title for a threat that includes the number of database rows affected")
            }

            static let unknown = NSLocalizedString("Threat Found", comment: "Title for a threat")
        }

        struct description {
            static let core = NSLocalizedString("Vulnerability found in WordPress", comment: "Summary description for a threat")
            static let file = NSLocalizedString("Threat found %1$@", comment: "Summary description for a threat that includes the threat signature")
            static let plugin = NSLocalizedString("Vulnerability found in plugin", comment: "Summary description for a threat")
            static let theme = NSLocalizedString("Vulnerability found in theme", comment: "Summary description for a threat")
            static let database: String? = nil
            static let unknown = NSLocalizedString("Miscellaneous vulnerability", comment: "Summary description for a threat")
        }
    }
}

extension JetpackScanThreatViewModel {

    private static func attributedString(for context: JetpackThreatContext?) -> NSAttributedString? {
        guard let context = context else {
            return nil
        }

        let lineFont = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        let numberFont = UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        let attrString = NSMutableAttributedString()

        let biggestLen = String(context.lines.last?.lineNumber ?? 0).count

        let longestLine = context.lines.sorted { $0.contents.count > $1.contents.count}.first!
        let longestLen = longestLine.contents.count

        let paragraph = NSMutableParagraphStyle()

        for line in context.lines {

            // Number attributed string

            var numberStr = String(line.lineNumber)
            let numberPadding = "".padding(toLength: biggestLen - numberStr.count,
                                           withPad: Constants.noBreakSpace, startingAt: 0)
            numberStr = numberPadding + numberStr
            let numberAttr = NSMutableAttributedString(string: numberStr)

            // Contents attributed string

            let contents = line.contents
            let contentsPadding = "".padding(toLength: longestLen - contents.count,
                                             withPad: Constants.noBreakSpace, startingAt: 0)

            let padding = " "
            let contentsStr = String(format: "%@\n", padding + contents + contentsPadding)
            let contentsAttr = NSMutableAttributedString(string: contentsStr, attributes: [
                NSAttributedString.Key.font: lineFont,
                NSAttributedString.Key.foregroundColor: Constants.normal.textColor,
                NSAttributedString.Key.backgroundColor: Constants.normal.backgroundColor,
                NSAttributedString.Key.paragraphStyle: paragraph,
            ])

            var numberBackgroundColor = Constants.normal.numberBackgroundColor

            // Highlight logic

            if let highlights = line.highlights {

                numberBackgroundColor = Constants.highlighted.numberBackgroundColor

                contentsAttr.addAttribute(.backgroundColor,
                                          value: numberBackgroundColor,
                                          range: NSRange(location: 0, length: contentsAttr.length))

                for highlight in highlights {
                    let location = highlight.location
                    let length = highlight.length + padding.count
                    let range = NSRange(location: location, length: length)

                    contentsAttr.addAttributes([
                        NSAttributedString.Key.font: lineFont,
                        NSAttributedString.Key.foregroundColor: Constants.highlighted.textColor,
                        NSAttributedString.Key.backgroundColor: Constants.highlighted.backgroundColor,
                        NSAttributedString.Key.paragraphStyle: paragraph
                    ], range: range)
                }
            }

            numberAttr.setAttributes([
                NSAttributedString.Key.font: numberFont,
                NSAttributedString.Key.foregroundColor: Constants.normal.numberTextColor,
                NSAttributedString.Key.backgroundColor: numberBackgroundColor,
            ], range: NSRange(location: 0, length: numberStr.count))

            attrString.append(numberAttr)
            attrString.append(NSAttributedString(string: ""))
            attrString.append(contentsAttr)
        }

        return attrString
    }

    private struct Constants {

        static let noBreakSpace = "\u{00a0}"

        struct normal {
            static let textColor = UIColor(rgb: 0x2C3337)
            static let backgroundColor = UIColor(rgb: 0xF6F7F7)
            static let numberTextColor = UIColor(rgb: 0x646970)
            static let numberBackgroundColor = UIColor(rgb: 0xC3C4C7)
        }

        struct highlighted {
            static let textColor = UIColor.white
            static let backgroundColor = UIColor(rgb: 0xD63638)
            static let numberBackgroundColor = UIColor(rgb: 0xF1DADA)
        }
    }
}

private extension String {
    func fileName() -> String {
        return (self as NSString).lastPathComponent
    }
}

private extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
