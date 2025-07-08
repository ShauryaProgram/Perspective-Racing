import Foundation

struct NMEAParser {
    // MARK: - Public Interface
    
    enum NMEAData {
        case rmc(RMCData)
        case gga(GGAData)
        case vtg(VTGData)
        case gll(GLLData)
        case dbt(DBTData)
        case hdt(HDTData)
        case mwv(MWVData)
    }

    static func parse(_ sentence: String) -> NMEAData? {
        guard validateChecksum(sentence) else {
            print("[Parser] Invalid checksum for: \(sentence)")
            return nil
        }
        
        let components = sentence.split(separator: "*")
        let fields = String(components[0]).split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
        
        guard !fields.isEmpty else {
            print("[Parser] Empty fields for: \(sentence)")
            return nil
        }
        
        let sentenceType = String(fields[0].dropFirst())
        
        switch sentenceType {
        case "GPRMC", "GNRMC": return parseRMC(fields: fields)
        case "GPGGA", "GNGGA": return parseGGA(fields: fields)
        case "GPVTG", "GNVTG": return parseVTG(fields: fields)
        case "GPGLL", "GNGLL": return parseGLL(fields: fields)
        case "SDDBT", "DBT": return parseDBT(fields: fields)
        case "HCHDG", "HDG": return parseHDT(fields: fields)
        case "WIMWV", "MWV": return parseMWV(fields: fields)
        default:
            print("[Parser] Unhandled sentence type: \(sentenceType)")
            return nil
        }
    }
    
    // MARK: - Data Structures
    
    struct RMCData {
        let time: String?
        let status: String
        let latitude: Double?
        let longitude: Double?
        let speedOverGround: Double?
        let courseOverGround: Double?
        let date: String?
        let magneticVariation: Double?
        let magneticVariationDirection: String?
        let mode: String?
        let navigationalStatus: String?
    }
    
    struct GGAData {
        let time: String?
        let latitude: Double?
        let longitude: Double?
        let fixQuality: String
        let satellites: Int?
        let hdop: Double?
        let altitude: Double?
        let altitudeUnits: String?
        let geoidSeparation: Double?
        let geoidSeparationUnits: String?
        let ageOfDGPS: String?
        let dgpsStationID: String?
    }
    
    struct VTGData {
        let trueTrack: Double?
        let trueTrackUnits: String?
        let magneticTrack: Double?
        let magneticTrackUnits: String?
        let speedKnots: Double?
        let speedKnotsUnits: String?
        let speedKmh: Double?
        let speedKmhUnits: String?
        let mode: String?
    }

    struct GLLData {
        let latitude: Double?
        let longitude: Double?
        let time: String?
        let status: String
        let mode: String?
    }
    
    struct DBTData {
        let depthMeters: Double?
        let depthFeet: Double?
        let depthFathoms: Double?
        let offset: Double?
        let offsetUnits: String?
    }
    
    struct HDTData {
        let heading: Double?
        let magneticDeviation: Double?
        let magneticDeviationDirection: String?
        let magneticVariation: Double?
        let magneticVariationDirection: String?
    }

    struct MWVData {
        let windAngle: Double?
        let reference: String?
        let windSpeed: Double?
        let units: String?
        let status: String?
    }

    // MARK: - Private Parsing Logic

    private static func validateChecksum(_ sentence: String) -> Bool {
        guard sentence.first == "$", let starIndex = sentence.lastIndex(of: "*") else { return false }
        
        let checksumContent = sentence[sentence.index(after: sentence.startIndex)..<starIndex]
        let providedChecksumString = String(sentence[sentence.index(after: starIndex)...])
        
        guard let providedChecksum = UInt8(providedChecksumString, radix: 16) else { return false }
        
        let calculatedChecksum = checksumContent.utf8.reduce(0, ^)
        
        return providedChecksum == calculatedChecksum
    }

    private static func parseRMC(fields: [String]) -> NMEAData? {
        guard fields.count >= 12 else { return nil }
        let status = fields[2] == "A" ? "Active" : "Void"
        let mode = fields.count > 12 ? fields[12] : nil
        let navigationalStatus = fields.count > 13 ? fields[13] : nil
        
        return .rmc(RMCData(
            time: fields[1].isEmpty ? nil : fields[1],
            status: status,
            latitude: parseNMEACoordinate(value: fields[3], indicator: fields[4]),
            longitude: parseNMEACoordinate(value: fields[5], indicator: fields[6]),
            speedOverGround: Double(fields[7]),
            courseOverGround: Double(fields[8]),
            date: fields[9].isEmpty ? nil : fields[9],
            magneticVariation: fields[10].isEmpty ? nil : Double(fields[10]),
            magneticVariationDirection: fields[11].isEmpty ? nil : fields[11],
            mode: mode,
            navigationalStatus: navigationalStatus
        ))
    }

    private static func parseGGA(fields: [String]) -> NMEAData? {
        guard fields.count >= 15 else { return nil }
        var quality: String
        switch Int(fields[6]) {
            case 0: quality = "Invalid"
            case 1: quality = "GPS Fix"
            case 2: quality = "DGPS Fix"
            case 4: quality = "RTK Fixed"
            case 5: quality = "RTK Float"
            default: quality = "Unknown"
        }
        
        return .gga(GGAData(
            time: fields[1].isEmpty ? nil : fields[1],
            latitude: parseNMEACoordinate(value: fields[2], indicator: fields[3]),
            longitude: parseNMEACoordinate(value: fields[4], indicator: fields[5]),
            fixQuality: quality,
            satellites: Int(fields[7]),
            hdop: Double(fields[8]),
            altitude: Double(fields[9]),
            altitudeUnits: fields[10].isEmpty ? nil : fields[10],
            geoidSeparation: Double(fields[11]),
            geoidSeparationUnits: fields[12].isEmpty ? nil : fields[12],
            ageOfDGPS: fields[13].isEmpty ? nil : fields[13],
            dgpsStationID: fields[14].isEmpty ? nil : fields[14]
        ))
    }

    private static func parseVTG(fields: [String]) -> NMEAData? {
        guard fields.count >= 10 else { return nil }
        let mode = fields.count > 9 ? fields[9] : nil
        return .vtg(VTGData(
            trueTrack: Double(fields[1]),
            trueTrackUnits: fields[2].isEmpty ? nil : fields[2],
            magneticTrack: Double(fields[3]),
            magneticTrackUnits: fields[4].isEmpty ? nil : fields[4],
            speedKnots: Double(fields[5]),
            speedKnotsUnits: fields[6].isEmpty ? nil : fields[6],
            speedKmh: Double(fields[7]),
            speedKmhUnits: fields[8].isEmpty ? nil : fields[8],
            mode: mode
        ))
    }
    
    private static func parseGLL(fields: [String]) -> NMEAData? {
        guard fields.count >= 7 else { return nil }
        let status = fields[6] == "A" ? "Active" : "Void"
        let mode = fields.count > 7 ? fields[7] : nil
        
        return .gll(GLLData(
            latitude: parseNMEACoordinate(value: fields[1], indicator: fields[2]),
            longitude: parseNMEACoordinate(value: fields[3], indicator: fields[4]),
            time: fields[5].isEmpty ? nil : fields[5],
            status: status,
            mode: mode
        ))
    }
    
    private static func parseDBT(fields: [String]) -> NMEAData? {
        guard fields.count >= 5 else { return nil }
        return .dbt(DBTData(
            depthMeters: Double(fields[1]),
            depthFeet: Double(fields[3]),
            depthFathoms: Double(fields[5]),
            offset: fields.count > 6 ? Double(fields[6]) : nil,
            offsetUnits: fields.count > 7 ? fields[7] : nil
        ))
    }
    
    private static func parseHDT(fields: [String]) -> NMEAData? {
        guard fields.count >= 5 else { return nil }
        return .hdt(HDTData(
            heading: Double(fields[1]),
            magneticDeviation: fields[2].isEmpty ? nil : Double(fields[2]),
            magneticDeviationDirection: fields[3].isEmpty ? nil : fields[3],
            magneticVariation: fields[4].isEmpty ? nil : Double(fields[4]),
            magneticVariationDirection: fields[5].isEmpty ? nil : fields[5]
        ))
    }

    private static func parseMWV(fields: [String]) -> NMEAData? {
        guard fields.count >= 5 else { return nil }
        let windAngle = Double(fields[1])
        let reference = fields[2]
        let windSpeed = Double(fields[3])
        let units = fields[4]
        let status = fields.count > 5 ? fields[5] : nil
        
        return .mwv(MWVData(
            windAngle: windAngle,
            reference: reference,
            windSpeed: windSpeed,
            units: units,
            status: status
        ))
    }

    private static func parseNMEACoordinate(value: String, indicator: String) -> Double? {
        guard !value.isEmpty, let coordinate = Double(value) else { return nil }
        let degrees = floor(coordinate / 100)
        let minutes = (coordinate / 100 - degrees) * 100
        var decimalDegrees = degrees + (minutes / 60.0)
        if indicator == "S" || indicator == "W" {
            decimalDegrees *= -1
        }
        return decimalDegrees
    }
}