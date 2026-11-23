const int HACCP_TOTAL_MINUTES = 240;
const int HACCP_WARNING_MINUTES = 90;
const int HACCP_CRITICAL_MINUTES = 0;

enum HaccpState { safe, warning, critical }

class HaccpView {
  const HaccpView({
    required this.state,
    required this.label,
    required this.guidance,
    required this.color,
    required this.ratio,
    required this.minutes,
  });

  final HaccpState state;
  final String label;
  final String guidance;
  final Color color;
  final double ratio; // 0-100
  final int minutes;
}

HaccpView getHaccpView(int minutes) {
  final clamped = minutes.clamp(0, HACCP_TOTAL_MINUTES);
  HaccpState state;
  if (minutes <= HACCP_CRITICAL_MINUTES) {
    state = HaccpState.critical;
  } else if (minutes <= HACCP_WARNING_MINUTES) {
    state = HaccpState.warning;
  } else {
    state = HaccpState.safe;
  }

  switch (state) {
    case HaccpState.critical:
      return HaccpView(
        state: state,
        label: 'Kedaluwarsa',
        guidance: 'Jangan bagikan makanan. Kunci scan aktif sampai batch ditarik.',
        color: const Color(0xFFB91C1C),
        ratio: 0,
        minutes: clamped,
      );
    case HaccpState.warning:
      return HaccpView(
        state: state,
        label: 'Waspada',
        guidance: 'Segera instruksikan pembagian ke kelas sebelum jam aman habis.',
        color: const Color(0xFFB45309),
        ratio: (clamped / HACCP_TOTAL_MINUTES) * 100,
        minutes: clamped,
      );
    case HaccpState.safe:
      return HaccpView(
        state: state,
        label: 'Aman',
        guidance: 'Jam aman konsumsi masih longgar, boleh menunggu proses serah terima.',
        color: const Color(0xFF15803D),
        ratio: (clamped / HACCP_TOTAL_MINUTES) * 100,
        minutes: clamped,
      );
  }
}
