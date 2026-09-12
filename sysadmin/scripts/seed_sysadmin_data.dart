import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final seeder = SeedSysAdminData();
  await seeder.seedAllData();
}

class SeedSysAdminData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Main seeding function
  Future<void> seedAllData() async {
    debugPrint('🔥 Starting sysadmin data seeding...');

    try {
      // 1. Create SysAdmin account
      await _createSysAdminAccount();

      // 2. Seed Radios
      await _seedRadios();

      // 3. Seed RadioAdmins
      await _seedRadioAdmins();

      // 4. Seed Hosts & Technicians
      await _seedUsers();

      // 5. Seed Shows/Sessions
      await _seedShows();

      // 6. Seed Transactions
      await _seedTransactions();

      // 7. Seed Announcements
      await _seedAnnouncements();

      // 8. Seed Analytics
      await _seedAnalytics();

      // 9. Seed System Activity
      await _seedSystemActivity();

      debugPrint('✅ SysAdmin data seeding completed successfully!');
    } catch (e) {
      debugPrint('❌ Error seeding data: $e');
    }
  }

  // ===== 1. CREATE SYSADMIN ACCOUNT =====

  Future<void> _createSysAdminAccount() async {
    try {
      // Check if account exists in Firestore
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'lauradz@example.com')
          .get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint('✅ SysAdmin account already exists in users collection');
        return;
      }

      // Create or sign in Firebase Auth user
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: 'lauradz@example.com',
          password: 'laura123',
        );
      } catch (e) {
        // If user already exists in Auth, sign in instead
        userCredential = await _auth.signInWithEmailAndPassword(
          email: 'lauradz@example.com',
          password: 'laura123',
        );
      }

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': 'lauradz@example.com',
        'displayName': 'Laura DZ',
        'role': 'sysadmin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ SysAdmin account created: lauradz@example.com');
    } catch (e) {
      debugPrint('⚠️ SysAdmin account creation notice: $e');
    }
  }

  // ===== 2. SEED RADIOS =====

  Future<void> _seedRadios() async {
    final radios = [
      {
        'id': 'radio_morning_drive',
        'name': 'Morning Drive FM',
        'broadcastLink': 'http://shoutcast.morningdrive.com:8000/stream',
        'contractCopy': 'Contract for Morning Drive FM - Valid until Dec 2025',
        'logoUrl': 'https://picsum.photos/seed/morning/200/200',
        'category': 'Music',
        'isActive': true,
        'listenerCount': 2456,
        'hostsCount': 3,
        'techniciansCount': 1,
        'status': 'live',
        'createdAt': DateTime.now().subtract(const Duration(days: 180)),
      },
      {
        'id': 'radio_tech_talk',
        'name': 'Tech Talk Radio',
        'broadcastLink': 'http://shoutcast.techtalk.com:8000/stream',
        'contractCopy': 'Contract for Tech Talk Radio - Valid until Jan 2026',
        'logoUrl': 'https://picsum.photos/seed/tech/200/200',
        'category': 'Talk',
        'isActive': true,
        'listenerCount': 1234,
        'hostsCount': 2,
        'techniciansCount': 2,
        'status': 'live',
        'createdAt': DateTime.now().subtract(const Duration(days: 120)),
      },
      {
        'id': 'radio_music_mix',
        'name': 'Music Mix Radio',
        'broadcastLink': 'http://shoutcast.musicmix.com:8000/stream',
        'contractCopy': 'Contract for Music Mix Radio - Valid until Mar 2025',
        'logoUrl': 'https://picsum.photos/seed/music/200/200',
        'category': 'Music',
        'isActive': true,
        'listenerCount': 876,
        'hostsCount': 1,
        'techniciansCount': 1,
        'status': 'recorded',
        'createdAt': DateTime.now().subtract(const Duration(days: 90)),
      },
      {
        'id': 'radio_news_hour',
        'name': 'News Hour Radio',
        'broadcastLink': 'http://shoutcast.newshour.com:8000/stream',
        'contractCopy': 'Contract for News Hour Radio - Valid until Jun 2025',
        'logoUrl': 'https://picsum.photos/seed/news/200/200',
        'category': 'News',
        'isActive': true,
        'listenerCount': 543,
        'hostsCount': 2,
        'techniciansCount': 1,
        'status': 'recorded',
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
      },
      {
        'id': 'radio_sports_zone',
        'name': 'Sports Zone Radio',
        'broadcastLink': 'http://shoutcast.sportszone.com:8000/stream',
        'contractCopy': 'Contract for Sports Zone Radio - Valid until Dec 2024',
        'logoUrl': 'https://picsum.photos/seed/sports/200/200',
        'category': 'Sports',
        'isActive': false,
        'listenerCount': 0,
        'hostsCount': 0,
        'techniciansCount': 0,
        'status': 'inactive',
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
      },
    ];

    for (final radioData in radios) {
      final docId = radioData['id'] as String;
      await _firestore.collection('radios').doc(docId).set({
        'name': radioData['name'],
        'broadcastLink': radioData['broadcastLink'],
        'contractCopy': radioData['contractCopy'],
        'logoUrl': radioData['logoUrl'],
        'category': radioData['category'] ?? 'General',
        'isActive': radioData['isActive'],
        'listenerCount': radioData['listenerCount'],
        'hostsCount': radioData['hostsCount'] ?? 0,
        'techniciansCount': radioData['techniciansCount'] ?? 0,
        'status': radioData['status'],
        'createdAt': Timestamp.fromDate(radioData['createdAt'] as DateTime),
        'radioAdminId': 'radio_admin_$docId',
        'radioAdminEmail': 'admin@$docId.com',
        'radioAdminName': 'Admin ${radioData['name']}',
        'radioAdminPhone': '+1 234 567 890',
        'settings': {},
      });
      debugPrint('✅ Radio seeded: ${radioData['name']}');
    }
  }

  // ===== 3. SEED RADIOADMINS =====

  Future<void> _seedRadioAdmins() async {
    final admins = [
      {'id': 'radio_admin_radio_morning_drive', 'radioId': 'radio_morning_drive', 'name': 'John Davis', 'email': 'john@morningdrive.com'},
      {'id': 'radio_admin_radio_tech_talk', 'radioId': 'radio_tech_talk', 'name': 'Mike Chen', 'email': 'mike@techtalk.com'},
      {'id': 'radio_admin_radio_music_mix', 'radioId': 'radio_music_mix', 'name': 'DJ Flow', 'email': 'dj@musicmix.com'},
      {'id': 'radio_admin_radio_news_hour', 'radioId': 'radio_news_hour', 'name': 'James Brown', 'email': 'james@newshour.com'},
    ];

    for (final admin in admins) {
      try {
        UserCredential? userCredential;
        try {
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: admin['email']!,
            password: 'admin123',
          );
        } catch (_) {
          // Already created in auth
        }

        final uid = userCredential?.user?.uid ?? admin['id']!;

        await _firestore.collection('users').doc(uid).set({
          'email': admin['email'],
          'displayName': admin['name'],
          'role': 'radio_admin',
          'radioId': admin['radioId'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('radios').doc(admin['radioId']).update({
          'radioAdminId': uid,
          'radioAdminEmail': admin['email'],
          'radioAdminName': admin['name'],
        });

        debugPrint('✅ RadioAdmin seeded: ${admin['name']}');
      } catch (e) {
        debugPrint('⚠️ RadioAdmin notice: $e');
      }
    }
  }

  // ===== 4. SEED HOSTS & TECHNICIANS =====

  Future<void> _seedUsers() async {
    final users = [
      // Hosts for Morning Drive
      {'email': 'sarah@morningdrive.com', 'name': 'Sarah Johnson', 'role': 'host', 'radioId': 'radio_morning_drive', 'radioName': 'Morning Drive FM'},
      {'email': 'mike@morningdrive.com', 'name': 'Mike Williams', 'role': 'host', 'radioId': 'radio_morning_drive', 'radioName': 'Morning Drive FM'},
      {'email': 'emma@morningdrive.com', 'name': 'Emma Chen', 'role': 'host', 'radioId': 'radio_morning_drive', 'radioName': 'Morning Drive FM'},

      // Hosts for Tech Talk
      {'email': 'alex@techtalk.com', 'name': 'Alex Rivera', 'role': 'host', 'radioId': 'radio_tech_talk', 'radioName': 'Tech Talk Radio'},
      {'email': 'lisa@techtalk.com', 'name': 'Lisa Thompson', 'role': 'host', 'radioId': 'radio_tech_talk', 'radioName': 'Tech Talk Radio'},

      // Hosts for Music Mix
      {'email': 'djflow@musicmix.com', 'name': 'DJ Flow', 'role': 'host', 'radioId': 'radio_music_mix', 'radioName': 'Music Mix Radio'},

      // Hosts for News Hour
      {'email': 'david@newshour.com', 'name': 'David Miller', 'role': 'host', 'radioId': 'radio_news_hour', 'radioName': 'News Hour Radio'},
      {'email': 'sarah@newshour.com', 'name': 'Sarah Wilson', 'role': 'host', 'radioId': 'radio_news_hour', 'radioName': 'News Hour Radio'},

      // Technicians
      {'email': 'david@morningdrive.com', 'name': 'David Brown', 'role': 'technician', 'radioId': 'radio_morning_drive', 'radioName': 'Morning Drive FM'},
      {'email': 'chris@techtalk.com', 'name': 'Chris Green', 'role': 'technician', 'radioId': 'radio_tech_talk', 'radioName': 'Tech Talk Radio'},
      {'email': 'mike@techtalk.com', 'name': 'Mike Johnson', 'role': 'technician', 'radioId': 'radio_tech_talk', 'radioName': 'Tech Talk Radio'},
      {'email': 'peter@musicmix.com', 'name': 'Peter Parker', 'role': 'technician', 'radioId': 'radio_music_mix', 'radioName': 'Music Mix Radio'},
      {'email': 'john@newshour.com', 'name': 'John Anderson', 'role': 'technician', 'radioId': 'radio_news_hour', 'radioName': 'News Hour Radio'},

      // Listeners
      {'email': 'mike@radio.com', 'name': 'Mike Brown', 'role': 'listener'},
      {'email': 'listener1@example.com', 'name': 'Alice Freeman', 'role': 'listener'},
      {'email': 'listener2@example.com', 'name': 'Bob Smith', 'role': 'listener'},
      {'email': 'listener3@example.com', 'name': 'Clara Oswald', 'role': 'listener'},
      {'email': 'listener4@example.com', 'name': 'Daniel Craig', 'role': 'listener'},
      {'email': 'listener5@example.com', 'name': 'Eva Green', 'role': 'listener'},
    ];

    for (int i = 0; i < users.length; i++) {
      final userData = users[i];
      try {
        final docId = 'user_seed_${i + 1}';
        await _firestore.collection('users').doc(docId).set({
          'email': userData['email'],
          'displayName': userData['name'],
          'role': userData['role'],
          'radioId': userData['radioId'],
          'radioName': userData['radioName'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User seeded: ${userData['name']} (${userData['role']})');
      } catch (e) {
        debugPrint('⚠️ User notice: $e');
      }
    }
  }

  // ===== 5. SEED SHOWS/SESSIONS =====

  Future<void> _seedShows() async {
    final now = DateTime.now();
    final shows = [
      // Morning Drive Shows
      {
        'id': 'show_morning_1',
        'programId': 'radio_morning_drive',
        'programName': 'Morning Drive',
        'date': DateTime(now.year, now.month, now.day),
        'startTime': DateTime(now.year, now.month, now.day, 8, 0),
        'endTime': DateTime(now.year, now.month, now.day, 10, 0),
        'hostId': 'host_morning_1',
        'hostName': 'Sarah Johnson',
        'thematic': 'Local News & Traffic',
        'status': 'live',
        'listenerCount': 2456,
        'startedAt': DateTime(now.year, now.month, now.day, 8, 0),
      },
      {
        'id': 'show_morning_2',
        'programId': 'radio_morning_drive',
        'programName': 'Morning Drive',
        'date': DateTime(now.year, now.month, now.day - 1),
        'startTime': DateTime(now.year, now.month, now.day - 1, 8, 0),
        'endTime': DateTime(now.year, now.month, now.day - 1, 10, 0),
        'hostId': 'host_morning_2',
        'hostName': 'Mike Williams',
        'thematic': 'Interview: Mayor Smith',
        'status': 'ended',
        'listenerCount': 2134,
      },

      // Tech Talk Shows
      {
        'id': 'show_tech_1',
        'programId': 'radio_tech_talk',
        'programName': 'Tech Talk',
        'date': DateTime(now.year, now.month, now.day),
        'startTime': DateTime(now.year, now.month, now.day, 10, 0),
        'endTime': DateTime(now.year, now.month, now.day, 12, 0),
        'hostId': 'host_tech_1',
        'hostName': 'Alex Rivera',
        'thematic': 'AI & Machine Learning',
        'status': 'live',
        'listenerCount': 1234,
        'guestName': 'Dr. Emily Chen',
      },
      {
        'id': 'show_tech_2',
        'programId': 'radio_tech_talk',
        'programName': 'Tech Talk',
        'date': DateTime(now.year, now.month, now.day - 1),
        'startTime': DateTime(now.year, now.month, now.day - 1, 10, 0),
        'endTime': DateTime(now.year, now.month, now.day - 1, 12, 0),
        'hostId': 'host_tech_2',
        'hostName': 'Lisa Thompson',
        'thematic': 'Blockchain & Web3',
        'status': 'ended',
        'listenerCount': 987,
      },

      // Music Mix Shows
      {
        'id': 'show_music_1',
        'programId': 'radio_music_mix',
        'programName': 'Music Mix',
        'date': DateTime(now.year, now.month, now.day),
        'startTime': DateTime(now.year, now.month, now.day, 12, 0),
        'endTime': DateTime(now.year, now.month, now.day, 15, 0),
        'hostId': 'host_music_1',
        'hostName': 'DJ Flow',
        'thematic': 'Top 40 Hits',
        'status': 'recorded',
        'listenerCount': 876,
        'recordingUrl': 'https://example.com/music_mix_1.mp3',
      },

      // News Hour Shows
      {
        'id': 'show_news_1',
        'programId': 'radio_news_hour',
        'programName': 'News Hour',
        'date': DateTime(now.year, now.month, now.day),
        'startTime': DateTime(now.year, now.month, now.day, 14, 0),
        'endTime': DateTime(now.year, now.month, now.day, 15, 0),
        'hostId': 'host_news_1',
        'hostName': 'David Miller',
        'thematic': 'Evening News Roundup',
        'status': 'scheduled',
        'listenerCount': 0,
      },
    ];

    for (final showData in shows) {
      final docId = showData['id'] as String;
      await _firestore.collection('sessions').doc(docId).set({
        'programId': showData['programId'],
        'programName': showData['programName'],
        'date': Timestamp.fromDate(showData['date'] as DateTime),
        'startTime': showData['startTime'] != null ? Timestamp.fromDate(showData['startTime'] as DateTime) : null,
        'endTime': showData['endTime'] != null ? Timestamp.fromDate(showData['endTime'] as DateTime) : null,
        'hostId': showData['hostId'],
        'hostName': showData['hostName'],
        'thematic': showData['thematic'],
        'status': showData['status'],
        'listenerCount': showData['listenerCount'] ?? 0,
        'guestName': showData['guestName'],
        'startedAt': showData['startedAt'] != null ? Timestamp.fromDate(showData['startedAt'] as DateTime) : null,
        'recordingUrl': showData['recordingUrl'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Show seeded: ${showData['programName']} - ${showData['date']}');
    }
  }

  // ===== 6. SEED TRANSACTIONS =====

  Future<void> _seedTransactions() async {
    final transactions = [
      {
        'radioId': 'radio_morning_drive',
        'radioName': 'Morning Drive FM',
        'type': 'subscription',
        'amount': 45.00,
        'status': 'paid',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'radioId': 'radio_tech_talk',
        'radioName': 'Tech Talk Radio',
        'type': 'announcement',
        'amount': 15.00,
        'status': 'validated',
        'announcementId': 'ann_1',
        'validatedAt': DateTime.now().subtract(const Duration(days: 1)),
        'pdfUrl': 'https://example.com/ann_1.pdf',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'radioId': 'radio_music_mix',
        'radioName': 'Music Mix Radio',
        'type': 'subscription',
        'amount': 30.00,
        'status': 'paid',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'radioId': 'radio_news_hour',
        'radioName': 'News Hour Radio',
        'type': 'announcement',
        'amount': 20.00,
        'status': 'pending',
        'announcementId': 'ann_2',
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'radioId': 'radio_morning_drive',
        'radioName': 'Morning Drive FM',
        'type': 'announcement',
        'amount': 25.00,
        'status': 'validated',
        'announcementId': 'ann_3',
        'validatedAt': DateTime.now().subtract(const Duration(hours: 3)),
        'pdfUrl': 'https://example.com/ann_3.pdf',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    for (int i = 0; i < transactions.length; i++) {
      final data = transactions[i];
      await _firestore.collection('transactions').doc('tx_${i + 1}').set({
        'radioId': data['radioId'],
        'radioName': data['radioName'],
        'type': data['type'],
        'amount': data['amount'],
        'status': data['status'],
        'announcementId': data['announcementId'],
        'validatedAt': data['validatedAt'] != null ? Timestamp.fromDate(data['validatedAt'] as DateTime) : null,
        'pdfUrl': data['pdfUrl'],
        'createdAt': Timestamp.fromDate(data['createdAt'] as DateTime),
      });
      debugPrint('✅ Transaction seeded: ${data['radioName']} - ${data['type']}');
    }
  }

  // ===== 7. SEED ANNOUNCEMENTS =====

  Future<void> _seedAnnouncements() async {
    final announcements = [
      {
        'id': 'ann_1',
        'radioId': 'radio_tech_talk',
        'radioName': 'Tech Talk Radio',
        'listenerId': 'listener_1',
        'listenerName': 'John Smith',
        'message': 'Happy Birthday to our loyal listener John Smith! We wish you all the best. 🎂',
        'amount': 15.00,
        'status': 'validated',
        'validatedBy': 'radio_admin_tech',
        'validatedAt': DateTime.now().subtract(const Duration(days: 1)),
        'isPrinted': true,
        'pdfUrl': 'https://example.com/ann_1.pdf',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': 'ann_2',
        'radioId': 'radio_news_hour',
        'radioName': 'News Hour Radio',
        'listenerId': 'listener_2',
        'listenerName': 'Sarah Williams',
        'message': 'We welcome Sarah Williams to our community. Great to have you! 👋',
        'amount': 20.00,
        'status': 'pending',
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': 'ann_3',
        'radioId': 'radio_morning_drive',
        'radioName': 'Morning Drive FM',
        'listenerId': 'listener_3',
        'listenerName': 'Mike Johnson',
        'message': 'Join us for the Morning Drive anniversary special next week! 🎉',
        'amount': 25.00,
        'status': 'validated',
        'validatedBy': 'radio_admin_morning',
        'validatedAt': DateTime.now().subtract(const Duration(hours: 3)),
        'isPrinted': true,
        'pdfUrl': 'https://example.com/ann_3.pdf',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    for (final data in announcements) {
      await _firestore.collection('announcements').doc(data['id'] as String).set({
        'radioId': data['radioId'],
        'radioName': data['radioName'],
        'listenerId': data['listenerId'],
        'listenerName': data['listenerName'],
        'message': data['message'],
        'amount': data['amount'],
        'status': data['status'],
        'validatedBy': data['validatedBy'],
        'validatedAt': data['validatedAt'] != null ? Timestamp.fromDate(data['validatedAt'] as DateTime) : null,
        'isPrinted': data['isPrinted'] ?? false,
        'pdfUrl': data['pdfUrl'],
        'createdAt': Timestamp.fromDate(data['createdAt'] as DateTime),
      });
      debugPrint('✅ Announcement seeded: ${data['radioName']}');
    }
  }

  // ===== 8. SEED ANALYTICS & OVERVIEW =====

  Future<void> _seedAnalytics() async {
    // User overview
    await _firestore.collection('user_overview').doc('current').set({
      'totalListeners': 2100,
      'totalHosts': 24,
      'totalTechnicians': 12,
      'totalRadioAdmins': 12,
      'userGrowth': {
        'Jan': 1800,
        'Feb': 1950,
        'Mar': 2100,
        'Apr': 2300,
        'May': 2456,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });

    // System analytics
    await _firestore.collection('system_analytics').doc('system_stats').set({
      'totalRadios': 5,
      'totalUsers': 2148,
      'totalListeners': 2100,
      'totalShows': 6,
      'engagementRate': 0.23,
      'growthRate': 0.12,
      'timestamp': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Analytics and User Overview seeded');
  }

  // ===== 9. SEED SYSTEM ACTIVITY =====

  Future<void> _seedSystemActivity() async {
    final activities = [
      {'type': 'radio_created', 'message': 'New Radio "Morning Drive FM" created by Admin'},
      {'type': 'transaction_paid', 'message': 'Subscription payment #234 - \$45.00 - Radio "Tech Talk"'},
      {'type': 'announcement_validated', 'message': 'Announcement #12 validated by RadioAdmin - PDF generated'},
      {'type': 'user_registered', 'message': 'New Listener registered: john.doe@email.com'},
      {'type': 'radio_updated', 'message': 'Broadcast link updated for Tech Talk Radio'},
      {'type': 'session_started', 'message': 'Morning Drive session started by Sarah Johnson'},
      {'type': 'user_registered', 'message': 'New user David Miller registered as Host'},
    ];

    for (int i = 0; i < activities.length; i++) {
      final data = activities[i];
      final time = DateTime.now().subtract(Duration(hours: i * 2 + 1));
      await _firestore.collection('system_activity').add({
        'type': data['type'],
        'message': data['message'],
        'timestamp': Timestamp.fromDate(time),
        'adminId': 'sysadmin_laura',
        'radioId': ['radio_morning_drive', 'radio_tech_talk', 'radio_music_mix'][i % 3],
      });
      debugPrint('✅ Activity seeded: ${data['message']}');
    }
  }
}

