import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hush_app/l10n/app_localizations.dart';

import '../config/theme.dart';
import '../models/secret.dart';
import '../widgets/secret_card.dart';
import '../providers/auth_provider.dart';

class FeedTutorialScreen extends StatefulWidget {
  const FeedTutorialScreen({super.key});

  @override
  State<FeedTutorialScreen> createState() => _FeedTutorialScreenState();
}

class _FeedTutorialScreenState extends State<FeedTutorialScreen> {
  TutorialCoachMark? tutorialCoachMark;
  
  final GlobalKey card1Key = GlobalKey();
  final GlobalKey card2Key = GlobalKey();
  final GlobalKey card3Key = GlobalKey();

  late List<Secret> mockSecrets;

  @override
  void initState() {
    super.initState();
    
    mockSecrets = [
      Secret(
        id: "mock_1",
        creatorId: "sys",
        creatorName: "Hushhh Team",
        creatorTierLevel: 1,
        creatorTierColor: "#4ADE80",
        type: "text",
        textContent: "Welcome to Hushhh! 🎉 Tap me to read the full secret.",
        likes: 42,
        commentCount: 5,
        lat: 0,
        lng: 0,
        createdAt: DateTime.now(),
      ),
      Secret(
        id: "mock_2",
        creatorId: "sys",
        creatorName: "Hushhh Team",
        creatorTierLevel: 3,
        creatorTierColor: "#FBBF24",
        type: "voice",
        audioDuration: 15,
        likes: 128,
        commentCount: 12,
        lat: 0,
        lng: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Secret(
        id: "mock_3",
        creatorId: "sys",
        creatorName: "Hushhh Team",
        creatorTierLevel: 5,
        creatorTierColor: "#EC4899",
        type: "text",
        isGroup: true,
        requiredUsers: 3,
        textContent: "Group secret! Needs 3 people around.",
        likes: 89,
        commentCount: 2,
        lat: 0,
        lng: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];

    Future.delayed(const Duration(milliseconds: 500), _showTutorial);
  }

  void _showTutorial() {
    if (!mounted) return;
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    
    tutorialCoachMark = TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "Target 1",
          keyTarget: card1Key,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => Text(
                isHe ? 'לחץ על הכרטיסייה כדי לפתוח האשש' : 'Tap on a card to reveal the secret',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "Target 2",
          keyTarget: card2Key,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => Text(
                isHe ? '👍 לייק = שווה ללכת | 👎 דיסלייק = אפשר לדלג.\nזה עוזר לאחרים לדעת אם שווה להגיע.' : '👍 Like = Worth it | 👎 Dislike = Skip it.',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "Target 3",
          keyTarget: card3Key,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => Text(
                isHe ? 'שמור Hushhh שאהבת - אפשר לראות אותם מהפרופיל.' : 'Save secrets you love to view them later.',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
      colorShadow: HushColors.bgPrimary,
      textSkip: isHe ? "דלג" : "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: _finishTutorial,
      onSkip: () {
        _finishTutorial();
        return true;
      },
    )..show(context: context);
  }

  void _finishTutorial() async {
    final auth = context.read<AuthProvider>();
    if (auth.firebaseUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.firebaseUser!.uid)
          .update({'hasSeenFeedTutorialV1': true});
    }
    if (mounted) {
      Navigator.of(context).pop(); // Go back to real feed
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    // Provide translated mock content
    final translatedMocks = List<Secret>.from(mockSecrets);
    if (isHe) {
      translatedMocks[0] = Secret(id: translatedMocks[0].id, creatorId: translatedMocks[0].creatorId, creatorName: translatedMocks[0].creatorName, creatorTierLevel: translatedMocks[0].creatorTierLevel, creatorTierColor: translatedMocks[0].creatorTierColor, type: translatedMocks[0].type, textContent: 'ברוכים הבאים ל-Hushhh! 🎉 לחץ כדי לקרוא.', likes: translatedMocks[0].likes, commentCount: translatedMocks[0].commentCount, lat: translatedMocks[0].lat, lng: translatedMocks[0].lng, createdAt: translatedMocks[0].createdAt);
      translatedMocks[2] = Secret(id: translatedMocks[2].id, creatorId: translatedMocks[2].creatorId, creatorName: translatedMocks[2].creatorName, creatorTierLevel: translatedMocks[2].creatorTierLevel, creatorTierColor: translatedMocks[2].creatorTierColor, type: translatedMocks[2].type, isGroup: translatedMocks[2].isGroup, requiredUsers: translatedMocks[2].requiredUsers, textContent: 'סוד קבוצתי! דורש 3 אנשים סביבך.', likes: translatedMocks[2].likes, commentCount: translatedMocks[2].commentCount, lat: translatedMocks[2].lat, lng: translatedMocks[2].lng, createdAt: translatedMocks[2].createdAt);
    }

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: Text(isHe ? 'הדרכה' : 'Tutorial'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: IgnorePointer( // Prevent actual clicks during tutorial
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(key: card1Key, child: SecretCard(secret: translatedMocks[0], )),
            const SizedBox(height: 16),
            Container(key: card2Key, child: SecretCard(secret: translatedMocks[1], )),
            const SizedBox(height: 16),
            Container(key: card3Key, child: SecretCard(secret: translatedMocks[2], )),
          ],
        ),
      ),
    );
  }
}
