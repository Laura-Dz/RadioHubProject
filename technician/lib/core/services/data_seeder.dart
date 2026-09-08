import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/technician/program_model.dart';
import '../models/technician/session_model.dart';
import '../models/technician/host_model.dart';
import '../models/technician/media_model.dart';
import '../models/technician/metrics_model.dart';

class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();

  Future<void> seedAllData() async {
    print('🔄 Starting data seeding...');

    await _seedHosts();
    await _seedPrograms();
    await _seedSessions();
    await _seedMediaItems();
    await _seedLiveMetrics();
    await _seedListenerCollections();

    print('✅ Seeding completed!');
  }

  Future<List<String>> _seedHosts() async {
    final now = DateTime.now();
    final hosts = [
      Host(
        id: 'host_1',
        name: 'Sarah Johnson',
        email: 'sarah@radiohub.com',
        phone: '+1234567890',
        bio: 'Morning show host with 10 years of experience.',
        photoUrl: 'https://picsum.photos/seed/sarah/200/200',
        programIds: ['prog_1', 'prog_2'],
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Host(
        id: 'host_2',
        name: 'Mike Chen',
        email: 'mike@radiohub.com',
        phone: '+1987654321',
        bio: 'Tech enthusiast and host of Tech Talk.',
        photoUrl: 'https://picsum.photos/seed/mike/200/200',
        programIds: ['prog_3'],
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Host(
        id: 'host_3',
        name: 'Emma Wilson',
        email: 'emma@radiohub.com',
        phone: '+1122334455',
        bio: 'Music lover and DJ.',
        photoUrl: 'https://picsum.photos/seed/emma/200/200',
        programIds: ['prog_4'],
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      Host(
        id: 'host_4',
        name: 'James Brown',
        email: 'james@radiohub.com',
        phone: '+1555666777',
        bio: 'Sports commentator and analyst.',
        photoUrl: 'https://picsum.photos/seed/james/200/200',
        programIds: ['prog_5'],
        createdAt: now.subtract(const Duration(days: 24)),
      ),
      Host(
        id: 'host_5',
        name: 'Lisa Thompson',
        email: 'lisa@radiohub.com',
        phone: '+1444333222',
        bio: 'Classical music expert and pianist.',
        photoUrl: 'https://picsum.photos/seed/lisa/200/200',
        programIds: ['prog_6'],
        createdAt: now.subtract(const Duration(days: 22)),
      ),
    ];

    final ids = <String>[];
    for (final host in hosts) {
      await _firestore.collection('hosts').doc(host.id).set(host.toFirestore());
      ids.add(host.id);
      print('   ✅ Seeded host: ${host.name}');
    }
    return ids;
  }

  Future<List<String>> _seedPrograms() async {
    final programs = [
      Program(
        id: 'prog_1',
        name: 'Morning Drive',
        description: 'Start your day with energy, news, and great music.',
        imageUrl: 'https://picsum.photos/seed/prog1/400/400',
        category: 'talk',
        hosts: ['host_1'],
        coHosts: [],
        defaultDuration: const Duration(hours: 2),
        metadata: {'slot': '08:00-10:00'},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Program(
        id: 'prog_2',
        name: 'Morning Prayer',
        description: 'A moment of reflection and prayer to start the day.',
        imageUrl: 'https://picsum.photos/seed/prog2/400/400',
        category: 'religious',
        hosts: ['host_1'],
        coHosts: [],
        defaultDuration: const Duration(minutes: 30),
        metadata: {'slot': '06:00-07:00'},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Program(
        id: 'prog_3',
        name: 'Tech Talk',
        description: 'Latest in technology, AI, and gadgets.',
        imageUrl: 'https://picsum.photos/seed/prog3/400/400',
        category: 'education',
        hosts: ['host_2'],
        coHosts: [],
        defaultDuration: const Duration(hours: 1),
        metadata: {'slot': '10:00-11:00'},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Program(
        id: 'prog_4',
        name: 'Music Mix',
        description: 'Your daily dose of hit music across genres.',
        imageUrl: 'https://picsum.photos/seed/prog4/400/400',
        category: 'music',
        hosts: ['host_3'],
        coHosts: [],
        defaultDuration: const Duration(hours: 1),
        metadata: {'slot': '12:00-13:00'},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Program(
        id: 'prog_5',
        name: 'Sports Central',
        description: 'Live sports news and analysis.',
        imageUrl: 'https://picsum.photos/seed/prog5/400/400',
        category: 'sports',
        hosts: ['host_4'],
        coHosts: [],
        defaultDuration: const Duration(hours: 1),
        metadata: {'slot': '14:00-15:00'},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Program(
        id: 'prog_6',
        name: 'Classical Hour',
        description: 'Timeless pieces from the masters.',
        imageUrl: 'https://picsum.photos/seed/prog6/400/400',
        category: 'music',
        hosts: ['host_5'],
        coHosts: [],
        defaultDuration: const Duration(hours: 1),
        metadata: {'slot': '16:00-17:00'},
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];

    final ids = <String>[];
    for (final program in programs) {
      await _firestore.collection('programs').doc(program.id).set(program.toFirestore());
      ids.add(program.id);
      print('   ✅ Seeded program: ${program.name}');
    }
    return ids;
  }

  Future<void> _seedSessions() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final daysToSeed = 14;

    final programSnapshots = await _firestore.collection('programs').where('isActive', isEqualTo: true).get();
    final programs = programSnapshots.docs
        .map((doc) => Program.fromFirestore(doc.data(), doc.id))
        .toList();

    final hostMap = {
      'host_1': 'Sarah Johnson',
      'host_2': 'Mike Chen',
      'host_3': 'Emma Wilson',
      'host_4': 'James Brown',
      'host_5': 'Lisa Thompson',
    };

    for (int i = 0; i < daysToSeed; i++) {
      final date = startDate.add(Duration(days: i));
      final weekday = date.weekday;

      for (final program in programs) {
        final slot = program.metadata['slot'] as String?;
        if (slot == null) continue;

        final parts = slot.split('-');
        final startHour = int.parse(parts[0].split(':').first);
        final endHour = int.parse(parts[1].split(':').first);

        final startTime = DateTime(date.year, date.month, date.day, startHour);
        final endTime = DateTime(date.year, date.month, date.day, endHour);

        final hostId = program.hosts.isNotEmpty ? program.hosts.first : null;
        final hostName = hostId != null ? hostMap[hostId] : null;

        final isLive = date == DateTime(now.year, now.month, now.day) &&
            startTime.isBefore(now) &&
            endTime.isAfter(now);
        final isEnded = date == DateTime(now.year, now.month, now.day) &&
            endTime.isBefore(now);

        final session = Session(
          id: 'session_${program.id}_${date.toIso8601String().split('T').first}',
          programId: program.id,
          programName: program.name,
          date: date,
          startTime: startTime,
          endTime: endTime,
          hostId: hostId,
          hostName: hostName,
          thematic: 'Regular ${program.name}',
          description: program.description,
          status: isLive
              ? SessionStatus.live
              : isEnded
                  ? SessionStatus.ended
                  : SessionStatus.scheduled,
          createdAt: now,
        );

        await _firestore.collection('sessions').doc(session.id).set(session.toFirestore());
        print('   ✅ Seeded session: ${session.programName} on ${date.toIso8601String().split('T').first}');
      }
    }
  }

  Future<void> _seedMediaItems() async {
    final mediaItems = [
      MediaItem(
        id: 'media_1',
        title: 'Intro Jingle',
        description: 'Morning show intro jingle.',
        mediaType: 'audio',
        url: 'https://example.com/jingle.mp3',
        thumbnailUrl: 'https://picsum.photos/seed/jingle/400/400',
        duration: const Duration(seconds: 15),
        fileSizeBytes: 256000,
        tags: ['intro', 'morning'],
        programId: 'prog_1',
        uploadedBy: 'host_1',
        uploadedAt: DateTime.now().subtract(const Duration(days: 10)),
        playCount: 120,
      ),
      MediaItem(
        id: 'media_2',
        title: 'Ad - Coffee Shop',
        description: 'Coffee shop advertisement.',
        mediaType: 'audio',
        url: 'https://example.com/ad_coffee.mp3',
        thumbnailUrl: 'https://picsum.photos/seed/adcoffee/400/400',
        duration: const Duration(seconds: 30),
        fileSizeBytes: 512000,
        tags: ['ad', 'coffee'],
        programId: 'prog_1',
        uploadedBy: 'host_1',
        uploadedAt: DateTime.now().subtract(const Duration(days: 8)),
        playCount: 45,
      ),
      MediaItem(
        id: 'media_3',
        title: 'Tech Talk Theme',
        description: 'Tech Talk opening theme.',
        mediaType: 'audio',
        url: 'https://example.com/tech_theme.mp3',
        thumbnailUrl: 'https://picsum.photos/seed/tech/400/400',
        duration: const Duration(seconds: 10),
        fileSizeBytes: 180000,
        tags: ['tech', 'theme'],
        programId: 'prog_3',
        uploadedBy: 'host_2',
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        playCount: 80,
      ),
      MediaItem(
        id: 'media_4',
        title: 'Sports Intro',
        description: 'Sports Central intro.',
        mediaType: 'audio',
        url: 'https://example.com/sports_intro.mp3',
        thumbnailUrl: 'https://picsum.photos/seed/sports/400/400',
        duration: const Duration(seconds: 12),
        fileSizeBytes: 200000,
        tags: ['sports', 'intro'],
        programId: 'prog_5',
        uploadedBy: 'host_4',
        uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
        playCount: 60,
      ),
      MediaItem(
        id: 'media_5',
        title: 'Classical Piano Piece',
        description: 'Relaxing piano piece for classical hour.',
        mediaType: 'audio',
        url: 'https://example.com/piano.mp3',
        thumbnailUrl: 'https://picsum.photos/seed/piano/400/400',
        duration: const Duration(seconds: 180),
        fileSizeBytes: 2800000,
        tags: ['classical', 'piano'],
        programId: 'prog_6',
        uploadedBy: 'host_5',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        playCount: 30,
      ),
    ];

    for (final item in mediaItems) {
      await _firestore.collection('media').doc(item.id).set(item.toFirestore());
      print('   ✅ Seeded media: ${item.title}');
    }
  }

  Future<void> _seedLiveMetrics() async {
    final sessionsSnapshot = await _firestore
        .collection('sessions')
        .where('status', isEqualTo: 'live')
        .limit(3)
        .get();

    for (final doc in sessionsSnapshot.docs) {
      final metrics = LiveMetrics(
        sessionId: doc.id,
        currentListeners: 50 + (doc.id.hashCode % 200),
        peakListeners: 80 + (doc.id.hashCode % 300),
        totalComments: 10 + (doc.id.hashCode % 50),
        totalCalls: 5 + (doc.id.hashCode % 20),
        waitingCalls: doc.id.hashCode % 3,
        acceptedCalls: 3 + (doc.id.hashCode % 10),
        rejectedCalls: doc.id.hashCode % 2,
        avgListenDurationSeconds: 120 + (doc.id.hashCode % 300).toDouble(),
        listenersByRegion: {
          'US': 30 + (doc.id.hashCode % 50),
          'EU': 10 + (doc.id.hashCode % 20),
          'AS': 5 + (doc.id.hashCode % 10),
        },
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('live_metrics').doc(doc.id).set(metrics.toFirestore());
      print('   ✅ Seeded metrics for session: ${doc.id}');
    }
  }

  Future<void> _seedListenerCollections() async {
    await _seedRadios();
    await _seedShows();
    await _seedScheduleItems();
    await _seedUsers();
    await _seedFlashPrograms();
    await _seedAnnouncementRequests();
    await _seedLiveComments();
  }

  Future<void> _seedRadios() async {
    final radios = [
      {
        'name': 'Radio Stream FM',
        'description': 'The best radio experience with news, music, and talk shows.',
        'logoUrl': 'https://picsum.photos/seed/radio1/200/200',
        'coverImageUrl': 'https://picsum.photos/seed/radio1_cover/800/400',
        'bannerImageUrl': 'https://picsum.photos/seed/radio1_banner/1200/400',
        'category': 'general',
        'hosts': ['Sarah Johnson', 'Mike Chen'],
        'followerCount': 1500,
        'isFollowed': false,
        'isLive': true,
        'listenerCount': 342,
        'rating': 4.7,
        'tags': ['music', 'news', 'talk'],
        'location': 'New York, USA',
        'foundedDate': DateTime(2015, 1, 1),
        'website': 'https://radiostreamfm.example.com',
        'contactEmail': 'hello@radiostreamfm.example.com',
        'phoneNumber': '+1-555-0100',
        'settings': {'volumeNormalization': true, 'autoNext': true},
        'socialLinks': ['https://twitter.com/radiostreamfm', 'https://facebook.com/radiostreamfm'],
        'isVerified': true,
        'lastActive': DateTime.now(),
      },
      {
        'name': 'Jazz & Blues Station',
        'description': 'Smooth jazz and classic blues 24/7.',
        'logoUrl': 'https://picsum.photos/seed/radio2/200/200',
        'coverImageUrl': 'https://picsum.photos/seed/radio2_cover/800/400',
        'bannerImageUrl': 'https://picsum.photos/seed/radio2_banner/1200/400',
        'category': 'music',
        'hosts': ['Emma Wilson', 'Lisa Thompson'],
        'followerCount': 890,
        'isFollowed': false,
        'isLive': false,
        'listenerCount': 0,
        'rating': 4.9,
        'tags': ['jazz', 'blues', 'relax'],
        'location': 'New Orleans, USA',
        'foundedDate': DateTime(2010, 6, 15),
        'website': 'https://jazzblues.example.com',
        'contactEmail': 'hello@jazzblues.example.com',
        'phoneNumber': '+1-555-0101',
        'settings': {'volumeNormalization': false, 'autoNext': false},
        'socialLinks': ['https://twitter.com/jazzblues'],
        'isVerified': true,
        'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'name': 'Tech Talk Radio',
        'description': 'All about technology, gadgets, and innovation.',
        'logoUrl': 'https://picsum.photos/seed/radio3/200/200',
        'coverImageUrl': 'https://picsum.photos/seed/radio3_cover/800/400',
        'bannerImageUrl': 'https://picsum.photos/seed/radio3_banner/1200/400',
        'category': 'education',
        'hosts': ['Mike Chen'],
        'followerCount': 2100,
        'isFollowed': true,
        'isLive': true,
        'listenerCount': 128,
        'rating': 4.8,
        'tags': ['tech', 'gadgets', 'innovation'],
        'location': 'San Francisco, USA',
        'foundedDate': DateTime(2018, 3, 20),
        'website': 'https://techtalk.example.com',
        'contactEmail': 'hello@techtalk.example.com',
        'phoneNumber': '+1-555-0102',
        'settings': {'volumeNormalization': true, 'autoNext': true},
        'socialLinks': ['https://twitter.com/techtalk', 'https://youtube.com/techtalk'],
        'isVerified': true,
        'lastActive': DateTime.now(),
      },
      {
        'name': 'Sports Central',
        'description': 'Live sports coverage, interviews, and analysis.',
        'logoUrl': 'https://picsum.photos/seed/radio4/200/200',
        'coverImageUrl': 'https://picsum.photos/seed/radio4_cover/800/400',
        'bannerImageUrl': 'https://picsum.photos/seed/radio4_banner/1200/400',
        'category': 'sports',
        'hosts': ['James Brown'],
        'followerCount': 3200,
        'isFollowed': false,
        'isLive': false,
        'listenerCount': 0,
        'rating': 4.6,
        'tags': ['sports', 'football', 'basketball'],
        'location': 'Chicago, USA',
        'foundedDate': DateTime(2012, 8, 10),
        'website': 'https://sportscentral.example.com',
        'contactEmail': 'hello@sportscentral.example.com',
        'phoneNumber': '+1-555-0103',
        'settings': {'volumeNormalization': false, 'autoNext': true},
        'socialLinks': ['https://twitter.com/sportscentral'],
        'isVerified': true,
        'lastActive': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'name': 'Classical Vibes',
        'description': 'Timeless classical music for relaxation and focus.',
        'logoUrl': 'https://picsum.photos/seed/radio5/200/200',
        'coverImageUrl': 'https://picsum.photos/seed/radio5_cover/800/400',
        'bannerImageUrl': 'https://picsum.photos/seed/radio5_banner/1200/400',
        'category': 'music',
        'hosts': ['Lisa Thompson'],
        'followerCount': 670,
        'isFollowed': false,
        'isLive': false,
        'listenerCount': 0,
        'rating': 4.9,
        'tags': ['classical', 'piano', 'orchestra'],
        'location': 'Vienna, Austria',
        'foundedDate': DateTime(2008, 12, 5),
        'website': 'https://classicalvibes.example.com',
        'contactEmail': 'hello@classicalvibes.example.com',
        'phoneNumber': '+43-555-0104',
        'settings': {'volumeNormalization': true, 'autoNext': false},
        'socialLinks': ['https://twitter.com/classicalvibes'],
        'isVerified': true,
        'lastActive': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    for (final radio in radios) {
      await _firestore.collection('radios').add(radio);
      print('   ✅ Seeded radio: ${radio['name']}');
    }
  }

  Future<void> _seedShows() async {
    final shows = [
      {
        'title': 'Morning Drive',
        'host': 'Sarah Johnson',
        'imageUrl': 'https://picsum.photos/seed/show1/400/400',
        'category': 'talk',
        'status': 'live',
        'startTime': DateTime.now().subtract(const Duration(minutes: 30)),
        'endTime': DateTime.now().add(const Duration(hours: 1, minutes: 30)),
        'listenerCount': 342,
        'episodeCount': 120,
        'rating': 4.7,
        'isFollowed': true,
        'tags': ['morning', 'news', 'music'],
        'description': 'Start your day with energy, news, and great music.',
      },
      {
        'title': 'Tech Talk',
        'host': 'Mike Chen',
        'imageUrl': 'https://picsum.photos/seed/show3/400/400',
        'category': 'education',
        'status': 'live',
        'startTime': DateTime.now().subtract(const Duration(minutes: 15)),
        'endTime': DateTime.now().add(const Duration(minutes: 45)),
        'listenerCount': 128,
        'episodeCount': 85,
        'rating': 4.8,
        'isFollowed': false,
        'tags': ['tech', 'ai', 'gadgets'],
        'description': 'Latest in technology, AI, and gadgets.',
      },
      {
        'title': 'Jazz Lounge',
        'host': 'Emma Wilson',
        'imageUrl': 'https://picsum.photos/seed/show4/400/400',
        'category': 'music',
        'status': 'upcoming',
        'startTime': DateTime.now().add(const Duration(hours: 2)),
        'endTime': DateTime.now().add(const Duration(hours: 4)),
        'listenerCount': 0,
        'episodeCount': 200,
        'rating': 4.9,
        'isFollowed': true,
        'tags': ['jazz', 'blues', 'lounge'],
        'description': 'Smooth jazz and classic blues.',
      },
      {
        'title': 'Sports Center',
        'host': 'James Brown',
        'imageUrl': 'https://picsum.photos/seed/show5/400/400',
        'category': 'sports',
        'status': 'ended',
        'startTime': DateTime.now().subtract(const Duration(hours: 3)),
        'endTime': DateTime.now().subtract(const Duration(hours: 1)),
        'listenerCount': 560,
        'episodeCount': 300,
        'rating': 4.6,
        'isFollowed': false,
        'tags': ['sports', 'football', 'basketball'],
        'description': 'Live sports news and analysis.',
      },
    ];

    for (final show in shows) {
      await _firestore.collection('shows').add(show);
      print('   ✅ Seeded show: ${show['title']}');
    }
  }

  Future<void> _seedScheduleItems() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final items = [
      {
        'title': 'Morning Drive',
        'host': 'Sarah Johnson',
        'guest': null,
        'guestTitle': null,
        'guestBio': null,
        'guestImageUrl': null,
        'startTime': DateTime(today.year, today.month, today.day, 8, 0),
        'endTime': DateTime(today.year, today.month, today.day, 10, 0),
        'type': 'regular',
        'description': 'Start your day with energy, news, and great music.',
        'imageUrl': 'https://picsum.photos/seed/schedule1/400/400',
        'listenerCount': 342,
        'isLive': true,
        'isInteractive': true,
        'channelId': 'radio_1',
        'channelName': 'Radio Stream FM',
        'flashId': null,
        'tags': ['morning', 'news'],
        'recordingUrl': null,
      },
      {
        'title': 'Tech Talk',
        'host': 'Mike Chen',
        'guest': 'AI Researcher',
        'guestTitle': 'Dr. Jane Smith',
        'guestBio': 'Leading AI researcher at Tech Institute.',
        'guestImageUrl': 'https://picsum.photos/seed/guest1/200/200',
        'startTime': DateTime(today.year, today.month, today.day, 10, 0),
        'endTime': DateTime(today.year, today.month, today.day, 11, 0),
        'type': 'special',
        'description': 'Latest in technology, AI, and gadgets with special guest.',
        'imageUrl': 'https://picsum.photos/seed/schedule3/400/400',
        'listenerCount': 128,
        'isLive': true,
        'isInteractive': true,
        'channelId': 'radio_3',
        'channelName': 'Tech Talk Radio',
        'flashId': null,
        'tags': ['tech', 'ai'],
        'recordingUrl': null,
      },
      {
        'title': 'Sports Center',
        'host': 'James Brown',
        'guest': null,
        'guestTitle': null,
        'guestBio': null,
        'guestImageUrl': null,
        'startTime': DateTime(today.year, today.month, today.day, 14, 0),
        'endTime': DateTime(today.year, today.month, today.day, 15, 0),
        'type': 'regular',
        'description': 'Live sports news and analysis.',
        'imageUrl': 'https://picsum.photos/seed/schedule5/400/400',
        'listenerCount': 0,
        'isLive': false,
        'isInteractive': false,
        'channelId': 'radio_4',
        'channelName': 'Sports Central',
        'flashId': null,
        'tags': ['sports'],
        'recordingUrl': null,
      },
    ];

    for (final item in items) {
      await _firestore.collection('schedule_items').add(item);
      print('   ✅ Seeded schedule item: ${item['title']}');
    }
  }

  Future<void> _seedUsers() async {
    final users = [
      {
        'email': 'alice@example.com',
        'displayName': 'Alice Wonder',
        'phoneNumber': '+1111111111',
        'role': 'listener',
        'subscription': 'premium',
        'preferences': {'notifications': true, 'theme': 'dark'},
        'createdAt': DateTime.now().subtract(const Duration(days: 60)),
        'lastLogin': DateTime.now().subtract(const Duration(hours: 2)),
        'isGuest': false,
        'isVerified': true,
      },
      {
        'email': 'bob@example.com',
        'displayName': 'Bob Builder',
        'phoneNumber': '+1222222222',
        'role': 'listener',
        'subscription': 'free',
        'preferences': {'notifications': false, 'theme': 'light'},
        'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        'lastLogin': DateTime.now().subtract(const Duration(days: 1)),
        'isGuest': false,
        'isVerified': true,
      },
      {
        'email': 'charlie@example.com',
        'displayName': 'Charlie Brown',
        'phoneNumber': '+1333333333',
        'role': 'listener',
        'subscription': 'free',
        'preferences': {'notifications': true, 'theme': 'system'},
        'createdAt': DateTime.now().subtract(const Duration(days: 15)),
        'lastLogin': DateTime.now().subtract(const Duration(hours: 5)),
        'isGuest': false,
        'isVerified': false,
      },
      {
        'email': 'diana@example.com',
        'displayName': 'Diana Prince',
        'phoneNumber': '+1444444444',
        'role': 'listener',
        'subscription': 'premium',
        'preferences': {'notifications': true, 'theme': 'dark'},
        'createdAt': DateTime.now().subtract(const Duration(days: 90)),
        'lastLogin': DateTime.now().subtract(const Duration(minutes: 30)),
        'isGuest': false,
        'isVerified': true,
      },
      {
        'email': 'guest_temp@temp.com',
        'displayName': 'Guest User',
        'phoneNumber': null,
        'role': 'listener',
        'subscription': null,
        'preferences': {},
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
        'lastLogin': DateTime.now().subtract(const Duration(minutes: 10)),
        'isGuest': true,
        'isVerified': false,
      },
    ];

    for (final user in users) {
      await _firestore.collection('users').add(user);
      print('   ✅ Seeded user: ${user['displayName']}');
    }
  }

  Future<void> _seedFlashPrograms() async {
    final flashes = [
      {
        'title': 'Breaking News: Market Update',
        'description': 'Major stock market updates and analysis.',
        'type': 'breakingNews',
        'status': 'pending',
        'broadcastTime': DateTime.now().add(const Duration(hours: 1)),
        'durationSeconds': 120,
        'host': 'Sarah Johnson',
        'isActive': false,
        'interruptedShow': false,
        'interruptedShowId': null,
        'recordingUrl': null,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
        'expiresAt': DateTime.now().add(const Duration(hours: 2)),
      },
      {
        'title': 'Weather Alert: Storm Warning',
        'description': 'Severe weather warning for the metro area.',
        'type': 'weatherAlert',
        'status': 'pending',
        'broadcastTime': DateTime.now().add(const Duration(minutes: 45)),
        'durationSeconds': 60,
        'host': 'Mike Chen',
        'isActive': false,
        'interruptedShow': false,
        'interruptedShowId': null,
        'recordingUrl': null,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
        'expiresAt': DateTime.now().add(const Duration(hours: 1)),
      },
    ];

    for (final flash in flashes) {
      await _firestore.collection('flash_programs').add(flash);
      print('   ✅ Seeded flash: ${flash['title']}');
    }
  }

  Future<void> _seedAnnouncementRequests() async {
    final requests = [
      {
        'radioId': 'radio_1',
        'userId': 'user_1',
        'userName': 'Alice Wonder',
        'message': 'Happy Birthday to my mom!',
        'category': 'birthday',
        'durationSeconds': 30,
        'price': 5.0,
        'status': 'pending',
        'scheduledTime': DateTime.now().add(const Duration(hours: 2)),
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
        'processedAt': null,
        'rejectionReason': null,
      },
      {
        'radioId': 'radio_1',
        'userId': 'user_2',
        'userName': 'Bob Builder',
        'message': 'Shout out to the construction team!',
        'category': 'promotional',
        'durationSeconds': 45,
        'price': 8.0,
        'status': 'approved',
        'scheduledTime': DateTime.now().add(const Duration(hours: 3)),
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'processedAt': DateTime.now().subtract(const Duration(minutes: 30)),
        'rejectionReason': null,
      },
    ];

    for (final request in requests) {
      await _firestore.collection('announcement_requests').add(request);
      print('   ✅ Seeded announcement request: ${request['message']}');
    }
  }

  Future<void> _seedLiveComments() async {
    final comments = [
      {'userId': 'user_1', 'userName': 'Alice Wonder', 'message': 'Great show!', 'timestamp': DateTime.now().millisecondsSinceEpoch},
      {'userId': 'user_2', 'userName': 'Bob Builder', 'message': 'Love this track', 'timestamp': DateTime.now().millisecondsSinceEpoch - 5000},
      {'userId': 'user_3', 'userName': 'Charlie Brown', 'message': 'Can you play more jazz?', 'timestamp': DateTime.now().millisecondsSinceEpoch - 12000},
      {'userId': 'user_1', 'userName': 'Alice Wonder', 'message': 'Hello from NY!', 'timestamp': DateTime.now().millisecondsSinceEpoch - 25000},
    ];

    for (final comment in comments) {
      await _rtdb.child('live_comments').push().set(comment);
    }
    print('   ✅ Seeded live comments');
  }
}
