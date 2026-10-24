import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/firebase_access.dart';

class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      FirebaseAccess(builder: (context, user) => _RecordsView(user: user));
}

class _RecordsView extends StatelessWidget {
  const _RecordsView({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final profile = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final walks = profile
        .collection('walks')
        .orderBy('startedAt', descending: true)
        .snapshots();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '내 산책 기록',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SignOutButton(),
              IconButton(
                tooltip: '반려견 정보',
                onPressed: () => _editDogProfile(context, profile),
                icon: const Icon(Icons.pets),
              ),
              FilledButton.icon(
                onPressed: () => _addWalk(context, profile),
                icon: const Icon(Icons.add),
                label: const Text('기록 추가'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: walks,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _RecordMessage(
                  icon: Icons.cloud_off_outlined,
                  title: '기록을 불러오지 못했습니다',
                  detail: 'Firestore 데이터베이스와 보안 규칙을 확인해 주세요.',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data?.docs ?? [];
              if (entries.isEmpty) {
                return const _RecordMessage(
                  icon: Icons.directions_walk_outlined,
                  title: '아직 산책 기록이 없습니다',
                  detail: '산책 후 직접 기록을 추가하면 이 계정에 저장됩니다.',
                );
              }
              var totalDistance = 0.0;
              for (final entry in entries) {
                totalDistance +=
                    (entry.data()['distanceKm'] as num?)?.toDouble() ?? 0;
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _Stat(label: '산책 횟수', value: '${entries.length}회'),
                            _Stat(
                              label: '누적 거리',
                              value: '${totalDistance.toStringAsFixed(1)} km',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final document = entries[index];
                        final data = document.data();
                        final startedAt = (data['startedAt'] as Timestamp)
                            .toDate()
                            .toLocal();
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.directions_walk_outlined),
                            ),
                            title: Text(data['routeName'] as String? ?? '산책'),
                            subtitle: Text(
                              '${_formatDate(startedAt)} · '
                              '${data['minutes'] ?? 0}분 · '
                              '${(data['distanceKm'] as num? ?? 0).toStringAsFixed(1)} km'
                              '${(data['dogName'] as String?)?.isNotEmpty == true ? ' · ${data['dogName']}' : ''}',
                            ),
                            trailing: IconButton(
                              tooltip: '기록 삭제',
                              onPressed: () =>
                                  _deleteWalk(context, document.reference),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _addWalk(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> profile,
  ) async {
    final formKey = GlobalKey<FormState>();
    final route = TextEditingController();
    final distance = TextEditingController();
    final minutes = TextEditingController();
    final dogName = TextEditingController();
    final notes = TextEditingController();
    final selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('산책 기록 추가'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: route,
                    decoration: const InputDecoration(labelText: '코스 또는 장소'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '코스나 장소를 입력해 주세요.'
                        : null,
                  ),
                  TextFormField(
                    controller: dogName,
                    decoration: const InputDecoration(labelText: '반려견 이름 (선택)'),
                  ),
                  TextFormField(
                    controller: distance,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: '거리 (km, 선택)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(value);
                      return parsed == null || parsed < 0 || parsed > 200
                          ? '0~200 사이의 숫자를 입력해 주세요.'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: minutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '시간 (분, 선택)'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = int.tryParse(value);
                      return parsed == null || parsed < 0 || parsed > 1440
                          ? '0~1440 사이의 정수를 입력해 주세요.'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: notes,
                    maxLength: 300,
                    decoration: const InputDecoration(labelText: '메모 (선택)'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != true) {
      _dispose([route, distance, minutes, dogName, notes]);
      return;
    }
    try {
      await profile.collection('walks').add({
        'routeName': route.text.trim(),
        'distanceKm': double.tryParse(distance.text.trim()) ?? 0,
        'minutes': int.tryParse(minutes.text.trim()) ?? 0,
        'dogName': dogName.text.trim(),
        'notes': notes.text.trim(),
        'startedAt': Timestamp.fromDate(selectedDate.toUtc()),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) _showMessage(context, '산책 기록을 저장했습니다.');
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _firestoreMessage(error), isError: true);
      }
    } finally {
      _dispose([route, distance, minutes, dogName, notes]);
    }
  }

  Future<void> _editDogProfile(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> profile,
  ) async {
    final existing = await profile.get();
    if (!context.mounted) return;
    final data = existing.data() ?? {};
    final dogName = TextEditingController(
      text: data['dogName'] as String? ?? '',
    );
    var size = data['dogSize'] as String? ?? '소형';
    var energy = data['dogEnergy'] as int? ?? 3;
    var sociality = data['dogSociality'] as String? ?? '보통';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('반려견 정보'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dogName,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: size,
                  decoration: const InputDecoration(labelText: '체급'),
                  items: ['소형', '중형', '대형']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => size = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('에너지 레벨'),
                    Expanded(
                      child: Slider(
                        value: energy.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$energy',
                        onChanged: (value) =>
                            setDialogState(() => energy = value.round()),
                      ),
                    ),
                    Text('$energy'),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: sociality,
                  decoration: const InputDecoration(labelText: '사회성'),
                  items: ['낮음', '보통', '높음']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => sociality = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      try {
        await profile.set({
          'dogName': dogName.text.trim(),
          'dogSize': size,
          'dogEnergy': energy,
          'dogSociality': sociality,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (context.mounted) _showMessage(context, '반려견 정보를 저장했습니다.');
      } catch (error) {
        if (context.mounted) {
          _showMessage(context, _firestoreMessage(error), isError: true);
        }
      }
    }
    dogName.dispose();
  }

  Future<void> _deleteWalk(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 산책 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await reference.delete();
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _firestoreMessage(error), isError: true);
      }
    }
  }

  static void _dispose(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  static String _firestoreMessage(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firestore 보안 규칙을 배포했는지 확인해 주세요.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  static void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label),
      ],
    ),
  );
}

class _RecordMessage extends StatelessWidget {
  const _RecordMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
