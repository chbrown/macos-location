import Cocoa
import CoreLocation

let newline = Data(bytes: [0x0A] as [UInt8])

/**
Write the given string to the specified FileHandle.

Writing to a FileHandle takes a bit of boilerplate, compared to print().

- parameter str: native string to write encode in utf-8.
- parameter handle: FileHandle to write to
- parameter appendNewline: whether or not to write a newline (U+000A) after the given string
*/
func prn(_ str: String, _ handle: FileHandle, _ appendNewline: Bool) {
  if let data = str.data(using:String.Encoding.utf8) {
    handle.write(data)
    if appendNewline {
      handle.write(newline)
    }
  }
}
func printOut(_ str: String, appendNewline: Bool = true) {
  // unlike print(), this will trigger immediate flushing
  prn(str, FileHandle.standardOutput, appendNewline)
}
func printErr(_ str: String, appendNewline: Bool = true) {
  prn(str, FileHandle.standardError, appendNewline)
}

//let iso8601Formatter = DateFormatter()
//iso8601Formatter.calendar = Calendar(identifier: .iso8601)
//iso8601Formatter.locale = Locale(identifier: "en_US_POSIX")
//iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
//iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
// e.g.: iso8601Formatter.string(from: location.timestamp)

func formatSeries(_ measurement: String) -> String {
  if let device = Host.current().name {
    return "\(measurement),device=\(device)"
  }
  else {
    return measurement
  }
}

let series = formatSeries("location")

func formatInfluxLineProtocol(_ location: CLLocation) -> String {
  let fields = [
    String(format: "longitude=%.07f", location.coordinate.longitude),
    String(format: "latitude=%.07f", location.coordinate.latitude),
    String(format: "altitude=%.07f", location.altitude),
    // location.verticalAccuracy is for altitude, not latitude as opposed to longitude
    String(format: "accuracy=%.01f", location.horizontalAccuracy),
    // "course=\(location.course)",
    // "speed=\(location.speed)",
  ].joined(separator: ",")
  // NSTimeInterval is a typealias for Double, and always specified in seconds
  let nanos = String(format: "%.f", location.timestamp.timeIntervalSince1970 * 1000000000.0)
  return [series, fields, nanos].joined(separator: " ")
}

class LocationListener: NSObject, CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // I haven't yet encountered a case of locations containing anything but 1 CLLocation
    for location in locations {
      let line = formatInfluxLineProtocol(location)
      printOut(line)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    printErr("Error while updating location " + error.localizedDescription)
  }
}

let authStatus = CLLocationManager.authorizationStatus()
// authStatus at this point is usually CLAuthorizationStatus.notDetermined
// but if it's .denied or .restricted, we should abort!
if authStatus == .restricted {
  printErr("CoreLocation authorization status is restricted: aborting!")
  abort()
} else if authStatus == .denied {
  printErr("CoreLocation authorization status is denied: aborting!")
  abort()
}

let locationManager = CLLocationManager()
// locationManager.desiredAccuracy = kCLLocationAccuracyBest # this is the default
// locationManager.distanceFilter = kCLDistanceFilterNone # this is the default
if let distanceFilterString = ProcessInfo.processInfo.environment["DISTANCE_FILTER"] {
  if let distanceFilterDouble = Double(distanceFilterString) {
    locationManager.distanceFilter = distanceFilterDouble
  }
}

// this will trigger a request for authorization from the user the first time the script/binary is run
if !CLLocationManager.locationServicesEnabled() {
  printErr("CoreLocation services are not enabled: aborting!")
  abort()
}

// we must store the LocationListener in a variable; otherwise it will disappear (due to GC?)
let locationListener = LocationListener()
locationManager.delegate = locationListener
// locationManager.requestLocation() is iOS-only
// startUpdatingLocation() will start triggering calls to the LocationListener instance
locationManager.startUpdatingLocation()

// start a run loop; otherwise, the program will exit immediately
RunLoop.current.run()
