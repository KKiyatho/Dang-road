import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/firebase_access.dart';

class MeetupsPage extends StatelessWidget {
  const MeetupsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      FirebaseAccess(builder: (context, user) => _MeetupList(user: user));
}

class _MeetupList extends StatelessWidget {
  const _MeetupList({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final meetups = FirebaseFirestore.instance
        .collection('meetups')
        .where('status', isEqualTo: 'open')
        .snapshots();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '동네 산책 모임',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text('대략적인 지역과 일정만 공유합니다.'),
                  ],
                ),
              ),
              const SignOutButton(),
              FilledButton.icon(
                onPressed: () => _createMeetup(context, user),
                icon: const Icon(Icons.add),
                label: const Text('모임 만들기'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: meetups,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MeetupMessage(
                  icon: Icons.cloud_off_outlined,
                  title: '모임 데이터를 불러오지 못했습니다',
                  detail: 'Firestore가 활성화되어 있는지, 보안 규칙이 배포됐는지 확인해 주세요.',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs.toList() ?? [];
              docs.removeWhere((document) {
                final startsAt = document.data()['startsAt'] as Timestamp?;
                return startsAt == null ||
                    startsAt.toDate().isBefore(DateTime.now());
              });
              docs.sort((first, second) {
                final firstTime = first.data()['startsAt'] as Timestamp?;
                final secondTime = second.data()['startsAt'] as Timestamp?;
                return (firstTime?.millisecondsSinceEpoch ?? 0).compareTo(
                  secondTime?.millisecondsSinceEpoch ?? 0,
                );
              });
              if (docs.isEmpty) {
                return const _MeetupMessage(
                  icon: Icons.groups_2_outlined,
                  title: '아직 열린 모임이 없습니다',
                  detail: '첫 모임을 만들면 같은 지역 사용자에게 실시간으로 표시됩니다.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final document = docs[index];
                  final data = document.data();
                  final participants =
                      (data['participantIds'] as List<dynamic>? ?? [])
                          .cast<String>();
                  final joined = participants.contains(user.uid);
                  final startsAt = (data['startsAt'] as Timestamp)
                      .toDate()
                      .toLocal();
                  final capacity = data['capacity'] as int? ?? 4;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] as String? ?? '산책 모임',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Text('${participants.length}/$capacity명'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data['region'] as String? ?? '지역 미지정'} · ${_formatDate(startsAt)}',
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonal(
                              onPressed:
                                  joined || participants.length >= capacity
                                  ? null
                                  : () => _joinMeetup(
                                      context,
                                      document.reference,
                                      user,
                                    ),
                              child: Text(joined ? '참여 중' : '참여하기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createMeetup(BuildContext context, User user) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController();
    final region = TextEditingController(text: '대구 수성구');
    DateTime startsAt = DateTime.now().add(const Duration(hours: 2));
    var capacity = 4;

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('산책 모임 만들기'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: '모임 이름'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '모임 이름을 입력해 주세요.'
                        : null,
                  ),
                  TextFormField(
                    controller: region,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: '대략적인 지역',
                      helperText: '정확한 주소나 실시간 위치는 입력하지 마세요.',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '지역을 입력해 주세요.'
                        : null,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('예정 시간'),
                    subtitle: Text(_formatDate(startsAt)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startsAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startsAt),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        startsAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: capacity,
                    decoration: const InputDecoration(labelText: '최대 참여 인원'),
                    items: [2, 3, 4, 5, 6, 7, 8]
                        .map(
                          (teamCount) => DropdownMenuItem(
                            value: teamCount,
                            child: Text('$teamCount명'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => capacity = value);
                    },
                  ),
                ],
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
              child: const Text('만들기'),
            ),
          ],
        ),
      ),
    );

    if (created != true) return;
    try {
      await FirebaseFirestore.instance.collection('meetups').add({
        'creatorId': user.uid,
        'title': title.text.trim(),
        'region': region.text.trim(),
        'startsAt': Timestamp.fromDate(startsAt.toUtc()),
        'capacity': capacity,
        'participantIds': [user.uid],
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) _showMessage(context, '모임을 등록했습니다.');
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _firestoreMessage(error), isError: true);
      }
    } finally {
      title.dispose();
      region.dispose();
    }
  }

  Future<void> _joinMeetup(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    User user,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) throw Exception('모임이 이미 종료되었습니다.');
        final data = snapshot.data()!;
        final participants = (data['participantIds'] as List<dynamic>? ?? [])
            .cast<String>();
        final capacity = data['capacity'] as int? ?? 0;
        if (data['status'] != 'open' || participants.length >= capacity) {
          throw Exception('모임 정원이 찼거나 종료되었습니다.');
        }
        if (!participants.contains(user.uid)) {
          transaction.update(reference, {
            'participantIds': FieldValue.arrayUnion([user.uid]),
          });
        }
      });
      if (context.mounted) _showMessage(context, '모임 참여가 완료됐습니다.');
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, _firestoreMessage(error), isError: true);
      }
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

class _MeetupMessage extends StatelessWidget {
  const _MeetupMessage({
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
