import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoyaltyOrderEntry {
  final String orderDocId;
  final String orderId;
  final double paidAmount;
  final DateTime date;

  LoyaltyOrderEntry({
    required this.orderDocId,
    required this.orderId,
    required this.paidAmount,
    required this.date,
  });

  factory LoyaltyOrderEntry.fromMap(Map<String, dynamic> m) {
    final rawDate = m['dateIso'] ?? m['date'];
    DateTime dt = DateTime.now();
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is String) {
      dt = DateTime.tryParse(rawDate) ?? DateTime.now();
    }
    return LoyaltyOrderEntry(
      orderDocId: '${m['orderDocId'] ?? ''}',
      orderId: '${m['orderId'] ?? ''}',
      paidAmount: (m['paidAmount'] as num?)?.toDouble() ?? 0.0,
      date: dt,
    );
  }
}

class LoyaltyRewardRecord {
  final int round;
  final DateTime unlockedAt;
  final double totalSpent;
  final double creditEarned;
  final String status;
  final List<LoyaltyOrderEntry> orders;

  LoyaltyRewardRecord({
    required this.round,
    required this.unlockedAt,
    required this.totalSpent,
    required this.creditEarned,
    required this.status,
    required this.orders,
  });

  factory LoyaltyRewardRecord.fromMap(Map<String, dynamic> m) {
    final rawDate = m['unlockedAtIso'] ?? m['unlockedAt'];
    DateTime dt = DateTime.now();
    if (rawDate is Timestamp) {
      dt = rawDate.toDate();
    } else if (rawDate is String) {
      dt = DateTime.tryParse(rawDate) ?? DateTime.now();
    }
    final list = ((m['orders'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => LoyaltyOrderEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return LoyaltyRewardRecord(
      round: (m['round'] as num?)?.toInt() ?? 1,
      unlockedAt: dt,
      totalSpent: (m['totalSpent'] as num?)?.toDouble() ?? 0.0,
      creditEarned: (m['creditEarned'] as num?)?.toDouble() ?? 0.0,
      status: '${m['status'] ?? 'available'}',
      orders: list,
    );
  }
}

/// Real-time Loyalty Card provider streaming `users/{uid}.loyalty`.
class LoyaltyProvider extends ChangeNotifier {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  String? _uid;
  bool _loaded = false;
  String _cardNumber = '0000';
  int _activeRound = 1;
  int _currentCount = 0;
  double _currentTotalPaid = 0.0;
  double _availableCredit = 0.0;
  double _totalCreditEarned = 0.0;
  int _lifetimeQualifyingOrders = 0;
  List<LoyaltyOrderEntry> _currentRoundOrders = const [];
  List<LoyaltyRewardRecord> _rewardHistory = const [];
  LoyaltyRewardRecord? _lastUnlockedReward;
  int _celebratedRound = 0;
  bool _useCreditInCheckout = false;

  bool get loaded => _loaded;
  bool get isSignedIn => _uid != null && _uid!.isNotEmpty;
  String get cardNumber => _cardNumber;
  int get activeRound => _activeRound;
  int get currentCount => _currentCount;
  double get currentTotalPaid => _currentTotalPaid;
  double get availableCredit => _availableCredit;
  double get totalCreditEarned => _totalCreditEarned;
  int get lifetimeQualifyingOrders => _lifetimeQualifyingOrders;
  List<LoyaltyOrderEntry> get currentRoundOrders => _currentRoundOrders;
  List<LoyaltyRewardRecord> get rewardHistory => _rewardHistory;
  LoyaltyRewardRecord? get lastUnlockedReward => _lastUnlockedReward;

  /// Every £1 spent adds 20p (1/5 of cumulative round spend so far).
  double get nextRewardBuilding => ((_currentTotalPaid / 5.0) * 100).roundToDouble() / 100.0;
  double get averageOrderSoFar => _currentCount > 0 ? (_currentTotalPaid / _currentCount) : 0.0;
  int get ordersRemaining => math.max(0, 5 - _currentCount);

  bool get hasUncelebratedReward =>
      _lastUnlockedReward != null &&
      _lastUnlockedReward!.creditEarned > 0 &&
      _lastUnlockedReward!.round > _celebratedRound &&
      _availableCredit > 0;

  bool get useCreditInCheckout => _useCreditInCheckout && _availableCredit > 0;

  void setUseCreditInCheckout(bool value) {
    final next = value && _availableCredit > 0;
    if (_useCreditInCheckout != next) {
      _useCreditInCheckout = next;
      notifyListeners();
    }
  }

  static String _cardNumberForUid(String uid) {
    if (uid.isEmpty) return '0000';
    int hash = 0;
    for (final code in uid.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return ((hash % 9000) + 1000).toString().padLeft(4, '0');
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _celebratedRound = prefs.getInt('loyalty_celebrated_round') ?? 0;
    } catch (_) {}

    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _bindUser(user?.uid);
    });
    _bindUser(FirebaseAuth.instance.currentUser?.uid);
  }

  void _bindUser(String? uid) {
    if (_uid == uid && _userSub != null) return;
    _userSub?.cancel();
    _uid = uid;

    if (uid == null || uid.isEmpty) {
      _loaded = true;
      _cardNumber = '0000';
      _activeRound = 1;
      _currentCount = 0;
      _currentTotalPaid = 0.0;
      _availableCredit = 0.0;
      _totalCreditEarned = 0.0;
      _lifetimeQualifyingOrders = 0;
      _currentRoundOrders = const [];
      _rewardHistory = const [];
      _lastUnlockedReward = null;
      _useCreditInCheckout = false;
      notifyListeners();
      return;
    }

    _cardNumber = _cardNumberForUid(uid);
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data() ?? const {};
      final l = data['loyalty'];
      if (l is Map) {
        final m = Map<String, dynamic>.from(l);
        _cardNumber = (m['cardNumber'] ?? '').toString().isNotEmpty
            ? m['cardNumber'].toString()
            : _cardNumberForUid(uid);
        _activeRound = (m['activeRound'] as num?)?.toInt() ?? 1;
        _currentRoundOrders = ((m['currentRoundOrders'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => LoyaltyOrderEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _currentCount = (m['currentCount'] as num?)?.toInt() ?? _currentRoundOrders.length;
        _currentTotalPaid = (m['currentTotalPaid'] as num?)?.toDouble() ??
            _currentRoundOrders.fold(0.0, (s, e) => s + e.paidAmount);
        _availableCredit = (m['availableCredit'] as num?)?.toDouble() ?? 0.0;
        _totalCreditEarned = (m['totalCreditEarned'] as num?)?.toDouble() ?? 0.0;
        _lifetimeQualifyingOrders = (m['lifetimeQualifyingOrders'] as num?)?.toInt() ?? _currentCount;
        _rewardHistory = ((m['rewardHistory'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => LoyaltyRewardRecord.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _lastUnlockedReward = (m['lastUnlockedReward'] is Map)
            ? LoyaltyRewardRecord.fromMap(Map<String, dynamic>.from(m['lastUnlockedReward']))
            : null;
        if (_availableCredit <= 0) _useCreditInCheckout = false;
      } else {
        _cardNumber = _cardNumberForUid(uid);
        _activeRound = 1;
        _currentCount = 0;
        _currentTotalPaid = 0.0;
        _availableCredit = 0.0;
        _totalCreditEarned = 0.0;
        _lifetimeQualifyingOrders = 0;
        _currentRoundOrders = const [];
        _rewardHistory = const [];
        _lastUnlockedReward = null;
      }
      _loaded = true;
      notifyListeners();
    }, onError: (_) {
      _loaded = true;
      notifyListeners();
    });
  }

  Future<void> markRewardCelebrated(int round) async {
    if (round > _celebratedRound) {
      _celebratedRound = round;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('loyalty_celebrated_round', round);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
