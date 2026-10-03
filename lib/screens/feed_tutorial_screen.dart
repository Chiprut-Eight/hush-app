import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final GlobalKey saveButtonKey = GlobalKey();

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
        textContent: "Closed secret.",
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
        type: "text",
        textContent: "Welcome to Hushhh! 🎉",
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

    Future.delayed(const Duration(milliseconds: 800), _showTutorial);
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
              builder: (context, controller) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70), // Push text much further down from the target
                  Text(
                    isHe ? 'כאשר אתה קרוב מספיק, הקש על ה-Hushhh כדי לחשוף את התוכן.' : 'When you are close enough, tap the Hushhh to reveal the content.',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "Target 2",
          keyTarget: saveButtonKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHe ? 'שמרו Hushhh שאהבתם או שתרצו לחזור אליהם בעתיד, תוכלו לגשת אליהם מהפרופיל האישי וממסך בקרבתך.' : 'Save Hushhhes you love or want to revisit later. You can access them from your profile and the nearby screen.',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tutorialCoachMark?.skip(),
                    style: ElevatedButton.styleFrom(backgroundColor: HushColors.gradientBlue, foregroundColor: Colors.white),
                    child: Text(isHe ? 'הבנתי' : 'Got it'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      colorShadow: HushColors.bgPrimary,
      hideSkip: true,
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
      FirebaseFirestore.instance
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
      translatedMocks[0] = Secret(id: translatedMocks[0].id, creatorId: translatedMocks[0].creatorId, creatorName: translatedMocks[0].creatorName, creatorTierLevel: translatedMocks[0].creatorTierLevel, creatorTierColor: translatedMocks[0].creatorTierColor, type: translatedMocks[0].type, textContent: 'סוד נעול לדוגמה.', likes: translatedMocks[0].likes, commentCount: translatedMocks[0].commentCount, lat: translatedMocks[0].lat, lng: translatedMocks[0].lng, createdAt: translatedMocks[0].createdAt);
      translatedMocks[1] = Secret(id: translatedMocks[1].id, creatorId: translatedMocks[1].creatorId, creatorName: translatedMocks[1].creatorName, creatorTierLevel: translatedMocks[1].creatorTierLevel, creatorTierColor: translatedMocks[1].creatorTierColor, type: translatedMocks[1].type, textContent: 'ברוכים הבאים ל-Hushhh! 🎉', likes: translatedMocks[1].likes, commentCount: translatedMocks[1].commentCount, lat: translatedMocks[1].lat, lng: translatedMocks[1].lng, createdAt: translatedMocks[1].createdAt);
      translatedMocks[2] = Secret(id: translatedMocks[2].id, creatorId: translatedMocks[2].creatorId, creatorName: translatedMocks[2].creatorName, creatorTierLevel: translatedMocks[2].creatorTierLevel, creatorTierColor: translatedMocks[2].creatorTierColor, type: translatedMocks[2].type, isGroup: translatedMocks[2].isGroup, requiredUsers: translatedMocks[2].requiredUsers, textContent: 'סוד קבוצתי! דורש 3 אנשים סביבך.', likes: translatedMocks[2].likes, commentCount: translatedMocks[2].commentCount, lat: translatedMocks[2].lat, lng: translatedMocks[2].lng, createdAt: translatedMocks[2].createdAt);
    }

    return Scaffold(
      backgroundColor: HushColors.bgPrimary,
      appBar: AppBar(
        title: Text(isHe ? 'הדרכה' : 'Tutorial'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _finishTutorial,
            child: Text(isHe ? 'דלג' : 'Skip', style: const TextStyle(color: HushColors.textAccent)),
          ),
        ],
      ),
      body: AbsorbPointer( // Prevent actual clicks during tutorial, but allow hit testing
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                key: card1Key, 
                child: SecretCard(
                  secret: translatedMocks[0], 
                  mockReveal: false, 
                  bypassDistance: true,
                )
              ),
              const SizedBox(height: 16),
              SecretCard(
                secret: translatedMocks[1], 
                mockReveal: true, 
                bypassDistance: true,
                saveButtonKey: saveButtonKey,
              ),
              const SizedBox(height: 16),
              SecretCard(secret: translatedMocks[2], mockReveal: true, bypassDistance: true),
            ],
          ),
        ),
      ),
    );
  }
}
