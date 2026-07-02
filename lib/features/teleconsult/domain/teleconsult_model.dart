class TeleconsultSession {
  const TeleconsultSession({
    required this.id,
    required this.channelName,
    required this.status,
    this.feeKobo = 0,
    this.paid = false,
  });

  final int id;
  final String channelName;
  final String status;
  final int feeKobo;
  final bool paid;

  factory TeleconsultSession.fromJson(Map<String, dynamic> j) {
    return TeleconsultSession(
      id:          (j['id'] as num?)?.toInt() ?? 0,
      channelName: j['channelName'] as String? ?? 'demo-consult-1',
      status:      j['status'] as String? ?? 'PENDING',
      feeKobo:     (j['feeKobo'] as num?)?.toInt() ?? 0,
      paid:        j['paid'] as bool? ?? false,
    );
  }
}