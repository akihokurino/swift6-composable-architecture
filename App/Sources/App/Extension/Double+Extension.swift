import CoreMedia

extension Double {
    var cmTime: CMTime {
        return CMTime(seconds: self, preferredTimescale: Int32(NSEC_PER_SEC))
    }

    func formatSecondsToTimeString() -> String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
