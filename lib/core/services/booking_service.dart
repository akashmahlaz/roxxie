/// 📅 GIGMATCH Booking Service
///
/// API service for managing bookings between artists and venues
/// Features:
/// - Create booking proposals
/// - Confirm bookings
/// - Handle payments (Stripe integration)
/// - Mark completion
/// - Get booking history
library;

import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../models/booking_models.dart';
import '../exceptions.dart';

class BookingService {
  final ApiClient _api = ApiClient();

  // ═══════════════════════════════════════════════════════════════════════
  // BOOKING CRUD
  // ═══════════════════════════════════════════════════════════════════════

  /// Create a new booking proposal
  Future<Booking> createBooking(CreateBookingRequest request) async {
    debugPrint('📅 [BookingService] Creating booking...');

    try {
      final response = await _api.post('/bookings', data: request.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ [BookingService] Booking created');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to create booking',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Create booking error: $e');
      rethrow;
    }
  }

  /// Get booking by ID
  Future<Booking> getBookingById(String bookingId) async {
    debugPrint('📅 [BookingService] Fetching booking: $bookingId');

    try {
      final response = await _api.get('/bookings/$bookingId');

      if (response.statusCode == 200) {
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Booking not found',
        response.statusCode ?? 404,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Get booking error: $e');
      rethrow;
    }
  }

  /// Get my bookings (as artist or venue)
  Future<List<Booking>> getMyBookings({
    String? status,
    bool? upcoming,
    int limit = 20,
    int skip = 0,
  }) async {
    debugPrint('📅 [BookingService] Fetching my bookings...');

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'skip': skip,
      };

      if (status != null) {
        queryParams['status'] = status;
      }
      if (upcoming != null) {
        queryParams['upcoming'] = upcoming;
      }

      final response = await _api.get(
        '/bookings/me',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['bookings'] ?? response.data;
        return data.map((json) => Booking.fromJson(json)).toList();
      }

      throw ApiException(
        'Failed to fetch bookings',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Get bookings error: $e');
      rethrow;
    }
  }

  /// Get upcoming bookings
  Future<List<Booking>> getUpcomingBookings({int limit = 10}) async {
    return getMyBookings(upcoming: true, limit: limit);
  }

  /// Get past bookings
  Future<List<Booking>> getPastBookings({int limit = 20, int skip = 0}) async {
    return getMyBookings(status: 'completed', limit: limit, skip: skip);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOOKING ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Confirm a booking (artist or venue)
  Future<Booking> confirmBooking(String bookingId) async {
    debugPrint('📅 [BookingService] Confirming booking: $bookingId');

    try {
      final response = await _api.post('/bookings/$bookingId/confirm');

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Booking confirmed');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to confirm booking',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Confirm error: $e');
      rethrow;
    }
  }

  /// Cancel a booking
  Future<Booking> cancelBooking(String bookingId, String reason) async {
    debugPrint('📅 [BookingService] Cancelling booking: $bookingId');

    try {
      final response = await _api.post(
        '/bookings/$bookingId/cancel',
        data: {'reason': reason},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Booking cancelled');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to cancel booking',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Cancel error: $e');
      rethrow;
    }
  }

  /// Mark booking as complete (artist or venue)
  Future<Booking> markComplete(String bookingId) async {
    debugPrint('📅 [BookingService] Marking complete: $bookingId');

    try {
      final response = await _api.post('/bookings/$bookingId/complete');

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Marked as complete');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to mark complete',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Mark complete error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAYMENTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Create deposit payment intent
  Future<PaymentIntentResponse> createDepositPayment(String bookingId) async {
    debugPrint('💳 [BookingService] Creating deposit payment: $bookingId');

    try {
      final response = await _api.post('/bookings/$bookingId/pay-deposit');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [BookingService] Payment intent created');
        return PaymentIntentResponse.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to create payment',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Payment error: $e');
      rethrow;
    }
  }

  /// Create final payment intent
  Future<PaymentIntentResponse> createFinalPayment(String bookingId) async {
    debugPrint('💳 [BookingService] Creating final payment: $bookingId');

    try {
      final response = await _api.post('/bookings/$bookingId/pay-final');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [BookingService] Final payment intent created');
        return PaymentIntentResponse.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to create payment',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Payment error: $e');
      rethrow;
    }
  }

  /// Confirm payment completion (webhook will handle this, but backup method)
  Future<Booking> confirmPayment(
    String bookingId,
    String paymentIntentId,
  ) async {
    debugPrint('💳 [BookingService] Confirming payment: $bookingId');

    try {
      final response = await _api.post(
        '/bookings/$bookingId/confirm-payment',
        data: {'paymentIntentId': paymentIntentId},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Payment confirmed');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to confirm payment',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Confirm payment error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONTRACT
  // ═══════════════════════════════════════════════════════════════════════

  /// Upload signed contract
  Future<Booking> uploadContract(String bookingId, String contractUrl) async {
    debugPrint('📝 [BookingService] Uploading contract: $bookingId');

    try {
      final response = await _api.post(
        '/bookings/$bookingId/contract',
        data: {'contractUrl': contractUrl},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Contract uploaded');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to upload contract',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Contract upload error: $e');
      rethrow;
    }
  }

  /// Sign contract
  Future<Booking> signContract(String bookingId) async {
    debugPrint('📝 [BookingService] Signing contract: $bookingId');

    try {
      final response = await _api.post('/bookings/$bookingId/sign-contract');

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Contract signed');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to sign contract',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Sign contract error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOOKING PROPOSALS IN CHAT
  // ═══════════════════════════════════════════════════════════════════════

  /// Send booking proposal message
  Future<Map<String, dynamic>> sendBookingProposal({
    required String matchId,
    required BookingProposal proposal,
  }) async {
    debugPrint('📅 [BookingService] Sending booking proposal in chat...');

    try {
      final response = await _api.post(
        '/messages/$matchId/proposal',
        data: proposal.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ [BookingService] Proposal sent');
        return response.data;
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to send proposal',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Send proposal error: $e');
      rethrow;
    }
  }

  /// Accept booking proposal
  Future<Booking> acceptProposal(String messageId) async {
    debugPrint('📅 [BookingService] Accepting proposal: $messageId');

    try {
      final response = await _api.post('/messages/$messageId/accept-proposal');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [BookingService] Proposal accepted, booking created');
        return Booking.fromJson(response.data);
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to accept proposal',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Accept proposal error: $e');
      rethrow;
    }
  }

  /// Decline booking proposal
  Future<void> declineProposal(String messageId, {String? reason}) async {
    debugPrint('📅 [BookingService] Declining proposal: $messageId');

    try {
      final response = await _api.post(
        '/messages/$messageId/decline-proposal',
        data: reason != null ? {'reason': reason} : null,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [BookingService] Proposal declined');
        return;
      }

      throw ApiException(
        response.data['message'] ?? 'Failed to decline proposal',
        response.statusCode ?? 500,
      );
    } catch (e) {
      debugPrint('❌ [BookingService] Decline proposal error: $e');
      rethrow;
    }
  }
}
