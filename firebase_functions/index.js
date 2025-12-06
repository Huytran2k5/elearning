/**
 * Firebase Cloud Functions for E-Learning System
 * 
 * Chức năng:
 * - Tự động gửi email thông báo bài tập mới cho học viên
 * - Trigger: Firestore onCreate trong collection 'assignment_notifications'
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: Gửi email thông báo bài tập mới
 * 
 * Trigger: Khi có document mới trong 'assignment_notifications'
 * 
 * Flow:
 * 1. Lấy thông tin bài tập từ trigger document
 * 2. Query danh sách học viên từ enrollments (theo courseId và groupIds)
 * 3. Lấy email của học viên từ users collection
 * 4. Tạo document trong 'mail' collection để Firebase Extension gửi email
 * 5. Cập nhật status của trigger document
 */
exports.sendAssignmentNotification = functions.firestore
  .document('assignment_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;

    console.log(`📧 Processing assignment notification: ${notificationId}`);

    try {
      // 1. Cập nhật status thành 'processing'
      await snap.ref.update({ status: 'processing' });

      // 2. Lấy thông tin từ trigger document
      const {
        courseId,
        courseName,
        assignmentTitle,
        dueAt,
        targetGroupIds,
      } = notification;

      // 3. Query danh sách enrollment
      let enrollQuery = db.collection('enrollments')
        .where('courseId', '==', courseId);

      // Nếu có chỉ định nhóm cụ thể
      if (targetGroupIds && targetGroupIds.length > 0) {
        enrollQuery = enrollQuery.where('groupId', 'in', targetGroupIds);
      }

      const enrollments = await enrollQuery.get();

      if (enrollments.empty) {
        console.log('⚠️ No enrollments found for this course');
        await snap.ref.update({
          status: 'completed',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          emailsSent: 0,
          message: 'No students enrolled'
        });
        return null;
      }

      // 4. Lấy danh sách userId
      const userIds = enrollments.docs.map(doc => doc.data().userId);
      console.log(`📝 Found ${userIds.length} students`);

      // 5. Lấy email từ users collection (batch 10 users để tránh limit whereIn)
      const emails = [];
      const batchSize = 10;

      for (let i = 0; i < userIds.length; i += batchSize) {
        const batch = userIds.slice(i, i + batchSize);
        const usersSnap = await db.collection('users')
          .where(admin.firestore.FieldPath.documentId(), 'in', batch)
          .get();

        usersSnap.docs.forEach(doc => {
          const email = doc.data().email;
          if (email) emails.push(email);
        });
      }

      if (emails.length === 0) {
        console.log('⚠️ No valid emails found');
        await snap.ref.update({
          status: 'completed',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          emailsSent: 0,
          message: 'No valid emails'
        });
        return null;
      }

      console.log(`📬 Preparing to send email to ${emails.length} recipients`);

      // 6. Format dueAt
      const dueDate = dueAt.toDate();
      const formattedDate = dueDate.toLocaleString('vi-VN', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });

      // 7. Tạo document trong 'mail' collection để Firebase Extension xử lý
      await db.collection('mail').add({
        to: emails,
        message: {
          subject: `📚 Bài tập mới: ${assignmentTitle}`,
          text: `
Kính gửi các bạn học viên,

Giảng viên vừa giao bài tập mới trong khóa học "${courseName}".

---------------------------------------
📝 Tên bài tập: ${assignmentTitle}
⏰ Hạn nộp: ${formattedDate}
---------------------------------------

Vui lòng truy cập ứng dụng để xem chi tiết và nộp bài đúng hạn.

Chúc các bạn học tốt!
          `.trim(),
          html: `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f5f5f5; }
    .container { max-width: 600px; margin: 20px auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #1565C0 0%, #0D47A1 100%); color: white; padding: 30px 20px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; }
    .content { padding: 30px 20px; }
    .assignment-box { background-color: #E3F2FD; padding: 20px; border-radius: 8px; border-left: 4px solid #FF6F00; margin: 20px 0; }
    .assignment-box strong { color: #1565C0; display: inline-block; min-width: 100px; }
    .due-date { color: #D32F2F; font-weight: bold; font-size: 16px; }
    .button { display: inline-block; background-color: #FF6F00; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin-top: 20px; font-weight: bold; }
    .footer { background-color: #f9f9f9; padding: 20px; text-align: center; color: #777; font-size: 12px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📚 Bài tập mới</h1>
    </div>
    <div class="content">
      <p>Kính gửi các bạn học viên,</p>
      <p>Giảng viên vừa giao bài tập mới trong khóa học "<strong>${courseName}</strong>".</p>
      
      <div class="assignment-box">
        <div style="margin-bottom: 10px;">
          <strong>📝 Tên bài tập:</strong> ${assignmentTitle}
        </div>
        <div>
          <strong>⏰ Hạn nộp:</strong> <span class="due-date">${formattedDate}</span>
        </div>
      </div>
      
      <p>Vui lòng truy cập ứng dụng để xem chi tiết và nộp bài đúng hạn.</p>
      
      <p>Chúc các bạn học tốt! 🎓</p>
    </div>
    <div class="footer">
      <p>Đây là email tự động từ Hệ thống E-Learning. Vui lòng không trả lời email này.</p>
      <p>© 2025 IT E-Learning System</p>
    </div>
  </div>
</body>
</html>
          `.trim()
        }
      });

      console.log(`✅ Email document created successfully`);

      // 8. Cập nhật status thành 'completed'
      await snap.ref.update({
        status: 'completed',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        emailsSent: emails.length,
        message: 'Success'
      });

      console.log(`✅ Notification processed successfully: ${emails.length} emails queued`);
      return null;

    } catch (error) {
      console.error('❌ Error processing notification:', error);

      // Cập nhật status thành 'failed'
      await snap.ref.update({
        status: 'failed',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message
      });

      // Không throw error để tránh retry vô hạn
      return null;
    }
  });
