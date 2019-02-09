import Foundation

class Utilities {
    static func QRFragments(_ QRMetadata : String) -> [String] {
        return QRMetadata.components(separatedBy: "::")
    }

    static func ordinalize(_ integer : Int) -> String {
        switch integer {
        case 0:
            return "basement"
        case 1:
            return "ground"
        case 2:
            return "2nd"
        case 3:
            return "3rd"
        case 4:
            return "4th"
        case 5:
            return "5th"
        default:
            // this should never be the case
            return "hidden"
        }
    }

    static func localizeSuccessMessage(_ bldg : String, _ level : Int) -> String {
        return String(format: "You are on the %s floor of %s.", ordinalize(level), QueryBuilder.fetchBuilding(bldg)!.name)
    }

    static func currentLocationMessage(_ level : Int) -> String {
        return String(format: "You are on the %s floor.", ordinalize(level))
    }

    static func targetLocationMessage(_ level : Int) -> String {
        return String(format: "Destination is on the %s floor.", ordinalize(level))
    }
}