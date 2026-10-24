import 'package:flutter/material.dart';

import '../services/live_data_service.dart';

class LocationPickerButton extends StatelessWidget {
  const LocationPickerButton({required this.onSelected, super.key});

  final ValueChanged<LocationSelection> onSelected;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final selection = await showDialog<LocationSelection>(
        context: context,
        builder: (context) => const _LocationSearchDialog(),
      );
      if (selection != null) onSelected(selection);
    },
    icon: const Icon(Icons.search),
    label: const Text('지역 검색'),
  );
}

class _LocationSearchDialog extends StatefulWidget {
  const _LocationSearchDialog();

  @override
  State<_LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  final _queryController = TextEditingController();
  List<LocationSelection> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.length < 2) {
      setState(() => _error = '두 글자 이상 입력해 주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _results = const [];
    });
    try {
      final results = await LiveDataService.searchLocations(query);
      if (!mounted) return;
      setState(() => _results = results);
      if (results.isEmpty) setState(() => _error = '검색 결과가 없습니다.');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('산책 지역 검색'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _queryController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '예: 대구 수성구, 서울 마포구',
              suffixIcon: IconButton(
                tooltip: '검색',
                onPressed: _loading ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
          if (_results.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(result.label),
                    subtitle: Text(
                      '${result.point.latitude.toStringAsFixed(3)}, '
                      '${result.point.longitude.toStringAsFixed(3)}',
                    ),
                    onTap: () => Navigator.pop(context, result),
                  );
                },
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );
}
