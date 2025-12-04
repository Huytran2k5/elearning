import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AdminSystemService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create student account (Auth + Firestore + Email)
  Future<void> createStudentAccount(
      {required String email,
      required String name,
      required String studentCode}) async {
    FirebaseApp? secondaryApp;
    try {
      // Initialize secondary app to create user without logging out Admin
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      // Create user on secondary app's Auth
      UserCredential cred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
              email: email, password: "123456"); // Default password

      String uid = cred.user!.uid;

      // Save info to Firestore (Use Admin's main instance)
      await FirebaseFirestore.instance
          .collection(AppConstants.collUsers)
          .doc(uid)
          .set({
        'id': uid,
        'email': email,
        'displayName': name,
        'studentCode': studentCode,
        'role': AppConstants.roleStudent,
        'createdAt': FieldValue.serverTimestamp(),
        'avatarUrl': '', // Empty initially
      });

      // Send notification email via Firestore (Trigger Email Extension)
      await _sendWelcomeEmailViaFirestore(email, name, "123456");
    } catch (e) {
      rethrow;
    }
    // Don't delete secondaryApp to reuse for next user in loop
  }

  // Send welcome email via Firestore Trigger
  Future<void> _sendWelcomeEmailViaFirestore(
      String email, String name, String password) async {
    try {
      await _db.collection('mail').add({
        'to': [email],
        'message': {
          'subject': 'Welcome New Student - E-Learning Account',
          'text': '''
Hello $name,

Your learning account has been successfully created on the E-Learning system.

Login Information:
---------------------------------------
Email: $email
Password: $password
---------------------------------------

Please log in to the application and change your password immediately to secure your account.

Best regards,
Training & Student Affairs Department.
''',
          'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1565C0; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin-top: 20px; }
    .credentials { background-color: white; padding: 15px; border-left: 4px solid #1565C0; margin: 20px 0; }
    .footer { text-align: center; margin-top: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🎓 IT E-Learning System</h1>
    </div>
    <div class="content">
      <h2>Welcome, $name!</h2>
      <p>Your learning account has been successfully created on the E-Learning system.</p>
      
      <div class="credentials">
        <strong>Login Information:</strong><br>
        📧 Email: <strong>$email</strong><br>
        🔑 Password: <strong>$password</strong>
      </div>
      
      <p>⚠️ <strong>Important:</strong> Please log in to the application and change your password immediately to secure your account.</p>
      
      <p>Best regards,<br>Training & Student Affairs Department</p>
    </div>
    <div class="footer">
      <p>This is an automated email from IT E-Learning System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
'''
        },
      });
    } catch (e) {
    }
  }

  // Send assignment notification via Firestore Trigger (Bulk send)
  Future<void> sendAssignmentNotification(List<String> recipients,
      String courseName, String assignmentTitle, DateTime dueAt) async {
    if (recipients.isEmpty) return;

    try {
      final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dueAt);

      await _db.collection('mail').add({
        'to': recipients,
        'message': {
          'subject': 'New Assignment Notification: $assignmentTitle',
          'text': '''
Dear Students,

The instructor has assigned a new assignment in the course "$courseName".

---------------------------------------
Title: $assignmentTitle
Due Date: $formattedDate
---------------------------------------

Please access the application to view assignment details and submit on time.

Best wishes for your studies!
''',
          'html': '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #1565C0; color: white; padding: 20px; text-align: center; }
    .content { background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin-top: 20px; }
    .assignment-box { background-color: white; padding: 15px; border-left: 4px solid #FF6F00; margin: 20px 0; }
    .footer { text-align: center; margin-top: 20px; color: #777; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📚 New Assignment</h1>
    </div>
    <div class="content">
      <h2>Dear Students,</h2>
      <p>The instructor has assigned a new assignment in the course "<strong>$courseName</strong>".</p>
      
      <div class="assignment-box">
        <strong>📝 Title:</strong> $assignmentTitle<br>
        <strong>⏰ Due Date:</strong> <span style="color: #D32F2F;">$formattedDate</span>
      </div>
      
      <p>Please access the application to view assignment details and submit on time.</p>
      
      <p>Best wishes for your studies!</p>
    </div>
    <div class="footer">
      <p>This is an automated email from IT E-Learning System. Please do not reply.</p>
    </div>
  </div>
</body>
</html>
'''
        },
      });
    } catch (e) {
    }
  }
}
