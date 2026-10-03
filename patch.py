import re

with open('lib/services/presence_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

resumed_old = '''    if (state == AppLifecycleState.resumed) {
      _db.ref('status/').set({
        'state': 'online',
        'lastChanged': ServerValue.timestamp,
      });
    }'''

resumed_new = '''    if (state == AppLifecycleState.resumed) {
      _db.ref('status/').set({
        'state': 'online',
        'lastChanged': ServerValue.timestamp,
      });
      // Update lastActive when app is resumed
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {});
    }'''

content = content.replace(resumed_old, resumed_new)

with open('lib/services/presence_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
