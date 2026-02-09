/// 📅 GIGMATCH Booking Models
///
/// Data models for bookings between artists and venues
library;

/// Booking Status
/// Matches backend booking.schema.ts status enum
enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  depositPaid('deposit_paid'),
  paid('paid'), // Full payment received (after final payment)
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  disputed('disputed');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => BookingStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.depositPaid:
        return 'Deposit Paid';
      case BookingStatus.paid:
        return 'Fully Paid';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }
}

/// Payment Details
class BookingPayment {
  final double? depositAmount;
  final bool depositPaid;
  final DateTime? depositPaidAt;
  final double? finalAmount;
  final bool finalPaid;
  final DateTime? finalPaidAt;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;

  BookingPayment({
    this.depositAmount,
    this.depositPaid = false,
    this.depositPaidAt,
    this.finalAmount,
    this.finalPaid = false,
    this.finalPaidAt,
    this.stripePaymentIntentId,
    this.stripeChargeId,
  });

  factory BookingPayment.fromJson(Map<String, dynamic> json) {
    return BookingPayment(
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      depositPaid: json['depositPaid'] ?? false,
      depositPaidAt: json['depositPaidAt'] != null
          ? DateTime.tryParse(json['depositPaidAt'])
          : null,
      finalAmount: (json['finalAmount'] as num?)?.toDouble(),
      finalPaid: json['finalPaid'] ?? false,
      finalPaidAt: json['finalPaidAt'] != null
          ? DateTime.tryParse(json['finalPaidAt'])
          : null,
      stripePaymentIntentId: json['stripePaymentIntentId'],
      stripeChargeId: json['stripeChargeId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'depositAmount': depositAmount,
        'depositPaid': depositPaid,
        'depositPaidAt': depositPaidAt?.toIso8601String(),
        'finalAmount': finalAmount,
        'finalPaid': finalPaid,
        'finalPaidAt': finalPaidAt?.toIso8601String(),
        'stripePaymentIntentId': stripePaymentIntentId,
        'stripeChargeId': stripeChargeId,
      };
}

/// Booking Participant Info
class BookingParticipant {
  final String id;
  final String userId;
  final String name;
  final String? photo;
  final double? rating;

  BookingParticipant({
    required this.id,
    required this.userId,
    required this.name,
    this.photo,
    this.rating,
  });

  factory BookingParticipant.fromJson(Map<String, dynamic> json) {
    return BookingParticipant(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['displayName'] ?? json['name'] ?? 'Unknown',
      photo: json['profilePhoto'] ?? json['photo'],
      rating: ((json['averageRating'] as num?) ?? (json['rating'] as num?))?.toDouble(),
    );
  }
}

/// Main Booking Model
class Booking {
  final String id;
  final String artistId;
  final String venueId;
  final String artistUserId;
  final String venueUserId;
  final String? matchId;
  final String? gigId;
  final String title;
  final String? description;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final int durationMinutes;
  final int numberOfSets;
  final double agreedAmount;
  final String currency;
  final BookingPayment? payment;
  final BookingStatus status;
  final bool artistConfirmed;
  final DateTime? artistConfirmedAt;
  final bool venueConfirmed;
  final DateTime? venueConfirmedAt;
  final String? specialRequests;
  final String? additionalTerms;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final bool refundIssued;
  final double? refundAmount;
  final DateTime? completedAt;
  final bool artistMarkedComplete;
  final bool venueMarkedComplete;
  final bool artistReviewSubmitted;
  final bool venueReviewSubmitted;
  final String? contractUrl;
  final bool contractSigned;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields
  final BookingParticipant? artist;
  final BookingParticipant? venue;

  Booking({
    required this.id,
    required this.artistId,
    required this.venueId,
    required this.artistUserId,
    required this.venueUserId,
    this.matchId,
    this.gigId,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 60,
    this.numberOfSets = 1,
    required this.agreedAmount,
    this.currency = 'USD',
    this.payment,
    this.status = BookingStatus.pending,
    this.artistConfirmed = false,
    this.artistConfirmedAt,
    this.venueConfirmed = false,
    this.venueConfirmedAt,
    this.specialRequests,
    this.additionalTerms,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.refundIssued = false,
    this.refundAmount,
    this.completedAt,
    this.artistMarkedComplete = false,
    this.venueMarkedComplete = false,
    this.artistReviewSubmitted = false,
    this.venueReviewSubmitted = false,
    this.contractUrl,
    this.contractSigned = false,
    required this.createdAt,
    required this.updatedAt,
    this.artist,
    this.venue,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      artistId: _extractId(json['artist']),
      venueId: _extractId(json['venue']),
      artistUserId: _extractId(json['artistUser']),
      venueUserId: _extractId(json['venueUser']),
      matchId: _extractIdNullable(json['match']),
      gigId: _extractIdNullable(json['gig']),
      title: json['title'] ?? '',
      description: json['description'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      durationMinutes: json['durationMinutes'] ?? 60,
      numberOfSets: json['numberOfSets'] ?? 1,
      agreedAmount: (json['agreedAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'USD',
      payment: json['payment'] != null
          ? BookingPayment.fromJson(json['payment'])
          : null,
      status: BookingStatus.fromString(json['status'] ?? 'pending'),
      artistConfirmed: json['artistConfirmed'] ?? false,
      artistConfirmedAt: json['artistConfirmedAt'] != null
          ? DateTime.tryParse(json['artistConfirmedAt'])
          : null,
      venueConfirmed: json['venueConfirmed'] ?? false,
      venueConfirmedAt: json['venueConfirmedAt'] != null
          ? DateTime.tryParse(json['venueConfirmedAt'])
          : null,
      specialRequests: json['specialRequests'],
      additionalTerms: json['additionalTerms'],
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'])
          : null,
      cancelledBy: json['cancelledBy'],
      cancellationReason: json['cancellationReason'],
      refundIssued: json['refundIssued'] ?? false,
      refundAmount: (json['refundAmount'] as num?)?.toDouble(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
      artistMarkedComplete: json['artistMarkedComplete'] ?? false,
      venueMarkedComplete: json['venueMarkedComplete'] ?? false,
      artistReviewSubmitted: json['artistReviewSubmitted'] ?? false,
      venueReviewSubmitted: json['venueReviewSubmitted'] ?? false,
      contractUrl: json['contractUrl'],
      contractSigned: json['contractSigned'] ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      artist: json['artist'] is Map
          ? BookingParticipant.fromJson(json['artist'])
          : null,
      venue: json['venue'] is Map
          ? BookingParticipant.fromJson(json['venue'])
          : null,
    );
  }

  static String _extractId(dynamic value) {
    if (value is String) return value;
    if (value is Map) return value['_id'] ?? value['id'] ?? '';
    return '';
  }

  static String? _extractIdNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id'] ?? value['id'];
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'artist': artistId,
        'venue': venueId,
        'artistUser': artistUserId,
        'venueUser': venueUserId,
        'match': matchId,
        'gig': gigId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'numberOfSets': numberOfSets,
        'agreedAmount': agreedAmount,
        'currency': currency,
        'payment': payment?.toJson(),
        'status': status.value,
        'artistConfirmed': artistConfirmed,
        'venueConfirmed': venueConfirmed,
        'specialRequests': specialRequests,
        'additionalTerms': additionalTerms,
        'contractUrl': contractUrl,
        'contractSigned': contractSigned,
      };
}

/// Create Booking Request
class CreateBookingRequest {
  final String artistId;
  final String venueId;
  final String? matchId;
  final String? gigId;
  final String title;
  final String? description;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final int durationMinutes;
  final int numberOfSets;
  final double agreedAmount;
  final String currency;
  final double? depositAmount;
  final String? specialRequests;
  final String? additionalTerms;

  CreateBookingRequest({
    required this.artistId,
    required this.venueId,
    this.matchId,
    this.gigId,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 60,
    this.numberOfSets = 1,
    required this.agreedAmount,
    this.currency = 'USD',
    this.depositAmount,
    this.specialRequests,
    this.additionalTerms,
  });

  Map<String, dynamic> toJson() => {
        'artistId': artistId,
        'venueId': venueId,
        'matchId': matchId,
        'gigId': gigId,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'numberOfSets': numberOfSets,
        'agreedAmount': agreedAmount,
        'currency': currency,
        'depositAmount': depositAmount,
        'specialRequests': specialRequests,
        'additionalTerms': additionalTerms,
      };
}

/// Payment Intent Response
class PaymentIntentResponse {
  final String clientSecret;
  final String paymentIntentId;
  final double amount;
  final String currency;

  PaymentIntentResponse({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      clientSecret: json['clientSecret'] ?? '',
      paymentIntentId: json['paymentIntentId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'USD',
    );
  }
}

/// Booking Proposal (for chat messages)
class BookingProposal {
  final String title;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final int durationMinutes;
  final double amount;
  final String currency;
  final String? message;
  final String? gigId;

  BookingProposal({
    required this.title,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 60,
    required this.amount,
    this.currency = 'USD',
    this.message,
    this.gigId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'durationMinutes': durationMinutes,
        'amount': amount,
        'currency': currency,
        'message': message,
        'gigId': gigId,
      };

  factory BookingProposal.fromJson(Map<String, dynamic> json) {
    return BookingProposal(
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      durationMinutes: json['durationMinutes'] ?? 60,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'USD',
      message: json['message'],
      gigId: json['gigId'],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTRACT & PAYMENT STATUS MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Contract signing status with per-party tracking
class ContractStatus {
  final bool contractSigned;
  final bool artistSigned;
  final bool venueSigned;
  final bool bothSigned;
  final String? contractUrl;
  final DateTime? signedAt;

  ContractStatus({
    required this.contractSigned,
    required this.artistSigned,
    required this.venueSigned,
    required this.bothSigned,
    this.contractUrl,
    this.signedAt,
  });

  factory ContractStatus.fromJson(Map<String, dynamic> json) {
    return ContractStatus(
      contractSigned: json['contractSigned'] ?? false,
      artistSigned: json['artistSigned'] ?? false,
      venueSigned: json['venueSigned'] ?? false,
      bothSigned: json['bothSigned'] ?? false,
      contractUrl: json['contractUrl'],
      signedAt: json['signedAt'] != null
          ? DateTime.tryParse(json['signedAt'].toString())
          : null,
    );
  }
}

/// Detailed payment status for a booking
class PaymentStatusDetails {
  final bool depositPaid;
  final double depositAmount;
  final DateTime? depositPaidAt;
  final bool finalPaid;
  final double finalAmount;
  final DateTime? finalPaidAt;
  final String? stripeDepositId;
  final String? stripeFinalId;

  PaymentStatusDetails({
    required this.depositPaid,
    required this.depositAmount,
    this.depositPaidAt,
    required this.finalPaid,
    required this.finalAmount,
    this.finalPaidAt,
    this.stripeDepositId,
    this.stripeFinalId,
  });

  factory PaymentStatusDetails.fromJson(Map<String, dynamic> json) {
    return PaymentStatusDetails(
      depositPaid: json['depositPaid'] ?? false,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
      depositPaidAt: json['depositPaidAt'] != null
          ? DateTime.tryParse(json['depositPaidAt'].toString())
          : null,
      finalPaid: json['finalPaid'] ?? false,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      finalPaidAt: json['finalPaidAt'] != null
          ? DateTime.tryParse(json['finalPaidAt'].toString())
          : null,
      stripeDepositId: json['stripeDepositId'],
      stripeFinalId: json['stripeFinalId'],
    );
  }

  double get totalPaid {
    double total = 0;
    if (depositPaid) {
      total += depositAmount;
    }
    if (finalPaid) {
      total += finalAmount;
    }
    return total;
  }

  double get totalDue => depositAmount + finalAmount;

  double get remainingBalance => totalDue - totalPaid;
}

/// Payment type for initiating payments
enum PaymentType {
  deposit('deposit'),
  finalPayment('final');

  final String value;
  const PaymentType(this.value);
}
