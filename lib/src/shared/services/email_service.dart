import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  /// Sends email via Google Apps Script.
  Future<Map<String, dynamic>> sendGoogleEmail({
    required dynamic recipientEmails,
    required String subject,
    required String htmlBody,
  }) async {
    final googleScriptUrl = dotenv.env['GOOGLE_SCRIPT_URL'];
    final emailToken = dotenv.env['EMAIL_TOKEN'];
    final senderName = dotenv.env['EMAIL_NAME'];

    debugPrint("--- EmailService: Attempting to send email ---");

    if (googleScriptUrl == null || emailToken == null) {
      return {'success': false, 'message': 'Environment variables not loaded.'};
    }

    String formattedRecipients = recipientEmails is List<String> 
        ? recipientEmails.join(',') 
        : recipientEmails.toString();

    final Map<String, dynamic> payload = {
      "token": emailToken,
      "to": formattedRecipients,
      "subject": subject,
      "body": htmlBody,
      "name": senderName ?? "Ali Grandson Spare Parts",
      "attachments": []
    };

    try {
      // Use a manual request to handle redirects (Google Script returns 302)
      var request = http.Request('POST', Uri.parse(googleScriptUrl))
        ..headers.addAll({'Content-Type': 'application/json'})
        ..body = jsonEncode(payload)
        ..followRedirects = true;

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Response Status Code: ${response.statusCode}");

      // If redirected (302) but not followed automatically or still results in HTML,
      // we check for success indicators.
      if (response.statusCode == 200 && response.body.contains("Success")) {
        debugPrint("Email sent successfully!");
        return {
          'success': true,
          'message': 'Email sent successfully',
          'recipients': formattedRecipients,
        };
      } else if (response.statusCode == 302) {
        // If we still get a 302, it means the email was likely sent but we couldn't follow.
        // Since you confirmed emails are arriving, we treat 302 as a success fallback.
        debugPrint("Note: Received 302 Redirect. Script executed successfully.");
        return {
          'success': true,
          'message': 'Email sent (redirected)',
          'recipients': formattedRecipients,
        };
      } else {
        debugPrint("Failed to send email. Status: ${response.statusCode}, Body: ${response.body}");
        return {'success': false, 'message': 'Server returned ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint("Network Error: ${e.toString()}");
      return {'success': false, 'message': 'Network Error: ${e.toString()}'};
    }
  }
}
