import 'package:flutter/material.dart';

import 'services/firebase_services.dart';
import 'app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseServices.initialize();
  runApp(const DangRoadApp());
}

class DangRoadApp extends StatelessWidget {
  const DangRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '댕로드',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans KR',
        scaffoldBackgroundColor: const Color(0xFFFFF8F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00652C),
          surface: const Color(0xFFFFF8F5),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.area,
    required this.description,
    required this.distance,
    required this.safety,
    required this.shade,
    required this.surface,
    required this.tag,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String area;
  final String description;
  final String distance;
  final int safety;
  final int shade;
  final String surface;
  final String tag;
  final IconData icon;
  final Color color;
}

const courses = [
  Course(
    id: 'stream',
    title: '범어천 수변 그늘 산책길',
    area: '범어동 · 완만한 평지길',
    description: '차량 통행 완전 분리 · 시원한 물소리와 흙길 데크',
    distance: '2.1 km',
    safety: 88,
    shade: 85,
    surface: '마사토 60%',
    tag: '검증 완료',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF00652C),
  ),
  Course(
    id: 'park',
    title: '범어공원 나지막한 솔숲길',
    area: '범어동 야산 둘레길',
    description: '완만한 마사토 흙길 · 관절 무리 없는 솔방울 트레일',
    distance: '2.8 km',
    safety: 84,
    shade: 90,
    surface: '마사토 85%',
    tag: '솔숲 그늘',
    icon: Icons.park_outlined,
    color: Color(0xFF005C85),
  ),
  Course(
    id: 'river',
    title: '신천 둔치 잔디 보행로',
    area: '신천 둔치 하류 방면',
    description: '자전거 도로 완전 분리 · 드넓은 천연 잔디존',
    distance: '4.2 km',
    safety: 76,
    shade: 50,
    surface: '잔디 70%',
    tag: '탁 트인 수변',
    icon: Icons.grass_outlined,
    color: Color(0xFF7B6F50),
  ),
  Course(
    id: 'park2',
    title: '야시골공원 반려견 숲길',
    area: '범어4동 숨은 명소',
    description: '인적 드문 힐링 코스 · 겁 많은 아이도 편안한 환경',
    distance: '1.5 km',
    safety: 82,
    shade: 75,
    surface: '흙길 50%',
    tag: '동네 아지트',
    icon: Icons.forest_outlined,
    color: Color(0xFF006C4B),
  ),
];

class CourseExplorerPage extends StatefulWidget {
  const CourseExplorerPage({super.key});

  @override
  State<CourseExplorerPage> createState() => _CourseExplorerPageState();
}

class _CourseExplorerPageState extends State<CourseExplorerPage> {
  String selectedId = courses.first.id;
  String activeFilter = '전체';
  bool isSaved = false;
  bool isBriefingExpanded = true;
  bool showFacilities = true;

  Course get selectedCourse =>
      courses.firstWhere((course) => course.id == selectedId);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 980;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F5),
        surfaceTintColor: Colors.transparent,
        titleSpacing: isDesktop ? 32 : 16,
        title: Row(
          children: [
            const Icon(Icons.pets, color: Color(0xFF00652C)),
            const SizedBox(width: 8),
            Text(
              '댕로드',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            const Text(
              '오늘 어디서 걸을까요?',
              style: TextStyle(fontSize: 14, color: Color(0xFF6F7A6E)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: '알림',
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFB8E9C1),
              child: const Icon(
                Icons.person,
                color: Color(0xFF00652C),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 16,
            12,
            isDesktop ? 32 : 16,
            24,
          ),
          child: isDesktop ? _desktopLayout() : _mobileLayout(),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: 1,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: '홈',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  label: '코스',
                ),
                NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  label: '함께 걷기',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: '내 기록',
                ),
              ],
            ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 430, child: _coursePanel()),
        const SizedBox(width: 20),
        Expanded(child: _mapPanel()),
      ],
    );
  }

  Widget _mobileLayout() {
    return ListView(
      children: [
        _coursePanel(),
        const SizedBox(height: 16),
        SizedBox(height: 560, child: _mapPanel()),
      ],
    );
  }

  Widget _coursePanel() {
    final filteredCourses = activeFilter == '전체'
        ? courses
        : courses.where((course) {
            if (activeFilter == '그늘 70%↑') return course.shade >= 70;
            if (activeFilter == '안전 80점↑') return course.safety >= 80;
            return true;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _surfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00652C),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '수성구 안심 산책길 탐색',
                      style: TextStyle(
                        color: Color(0xFF00652C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _smallBadge('초코 맞춤'),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: '대구 수성구 산책로, 공원, 둘레길 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF2EE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['전체', '그늘 70%↑', '안전 80점↑', '한적한 코스'].map((
                    filter,
                  ) {
                    final selected = activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        label: Text(filter),
                        onSelected: (_) =>
                            setState(() => activeFilter = filter),
                        selectedColor: const Color(0xFF00652C),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF3F493F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        checkmarkColor: Colors.white,
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '추천 산책로 ${filteredCourses.length}개 발견',
                    style: const TextStyle(color: Color(0xFF6F7A6E)),
                  ),
                  const Text(
                    '맞춤 추천순  ˅',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...filteredCourses.map(_courseCard),
      ],
    );
  }

  Widget _courseCard(Course course) {
    final isSelected = selectedId == course.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() {
          selectedId = course.id;
          isSaved = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF1FAF1) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF79DB8D) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? .10 : .05),
                blurRadius: isSelected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: course.color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(course.icon, color: course.color, size: 38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.area,
                            style: const TextStyle(
                              color: Color(0xFF006C4B),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          course.distance,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6F7A6E),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _metric(Icons.shield_outlined, '안전 ${course.safety}점'),
                        _metric(Icons.park_outlined, '그늘 ${course.shade}%'),
                        _metric(Icons.pets, course.surface),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapPanel() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CustomPaint(
            painter: MapPainter(selectedId: selectedId),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _weatherHud(),
              const SizedBox(height: 10),
              _mapControls(),
            ],
          ),
        ),
        if (showFacilities) ...[
          _pin(0.28, 0.45, Icons.water_drop, const Color(0xFF005C85), '급수대'),
          _pin(
            0.43,
            0.55,
            Icons.delete_outline,
            const Color(0xFF006C4B),
            '배변봉투함',
          ),
          _pin(
            0.22,
            0.32,
            Icons.chair_outlined,
            const Color(0xFF00652C),
            '그늘 쉼터',
          ),
        ],
        Positioned(left: 16, bottom: 16, child: _legend()),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Align(
            alignment: Alignment.bottomRight,
            child: _briefingCard(),
          ),
        ),
      ],
    );
  }

  Widget _weatherHud() => _surfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.pets, color: Color(0xFF006C4B)),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '아스팔트 발바닥 지수',
              style: TextStyle(fontSize: 11, color: Color(0xFF6F7A6E)),
            ),
            Text(
              '쾌적 · 24.2°C',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF006C4B),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _mapControls() => _surfaceCard(
    padding: const EdgeInsets.all(4),
    child: Column(
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.remove)),
        const Divider(height: 1),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.my_location, color: Color(0xFF00652C)),
        ),
        IconButton(
          onPressed: () => setState(() => showFacilities = !showFacilities),
          icon: Icon(
            Icons.layers_outlined,
            color: showFacilities ? const Color(0xFF00652C) : Colors.grey,
          ),
        ),
      ],
    ),
  );

  Widget _pin(
    double top,
    double left,
    IconData icon,
    Color color,
    String label,
  ) => Positioned(
    top: top * 500,
    left: left * 700,
    child: Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    ),
  );

  Widget _legend() => _surfaceCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: const Row(
      children: [
        Icon(Icons.circle, size: 9, color: Color(0xFF00652C)),
        SizedBox(width: 5),
        Text('안전 보행로', style: TextStyle(fontSize: 11)),
        SizedBox(width: 12),
        Icon(Icons.circle, size: 9, color: Color(0xFF45DFA4)),
        SizedBox(width: 5),
        Text('편의시설', style: TextStyle(fontSize: 11)),
      ],
    ),
  );

  Widget _briefingCard() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 430),
    child: _surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '현재 선택 코스',
                style: TextStyle(
                  color: Color(0xFF00652C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    setState(() => isBriefingExpanded = !isBriefingExpanded),
                icon: Icon(
                  isBriefingExpanded ? Icons.expand_more : Icons.expand_less,
                ),
              ),
            ],
          ),
          Text(
            selectedCourse.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            '${selectedCourse.area} · 왕복 45분',
            style: const TextStyle(color: Color(0xFF6F7A6E), fontSize: 12),
          ),
          if (isBriefingExpanded) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _detailMetric(
                  '안전도',
                  '${selectedCourse.safety}점',
                  Icons.shield_outlined,
                ),
                _detailMetric(
                  '그늘',
                  '${selectedCourse.shade}%',
                  Icons.park_outlined,
                ),
                _detailMetric('노면', selectedCourse.surface, Icons.gesture),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '초코 맞춤 소견: 계단 없는 완만한 평지 산책로로 적극 권장됩니다.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => isSaved = !isSaved),
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    label: Text(isSaved ? '저장됨' : '저장'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('산책 시작'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  Widget _detailMetric(String label, String value, IconData icon) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF00652C)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6F7A6E)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  Widget _metric(IconData icon, String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFF4ECE8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF00652C)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  Widget _smallBadge(String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFF4ECE8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF3F493F),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .05),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class MapPainter extends CustomPainter {
  const MapPainter({required this.selectedId});

  final String selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEAF2E8);
    canvas.drawRect(Offset.zero & size, background);

    final park = Paint()
      ..color = const Color(0xFFB8E9C1).withValues(alpha: .42);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .05,
        size.height * .12,
        size.width * .40,
        size.height * .30,
      ),
      park,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .55,
        size.height * .52,
        size.width * .38,
        size.height * .30,
      ),
      park,
    );

    final river = Paint()
      ..color = const Color(0xFF89CEFF).withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .035
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(0, size.height * .08)
      ..quadraticBezierTo(
        size.width * .27,
        size.height * .22,
        size.width * .50,
        size.height * .42,
      )
      ..quadraticBezierTo(
        size.width * .75,
        size.height * .65,
        size.width,
        size.height * .90,
      );
    canvas.drawPath(riverPath, river);

    final roads = Paint()
      ..color = const Color(0xFFBECABC).withValues(alpha: .65)
      ..strokeWidth = 4;
    canvas.drawLine(
      Offset(0, size.height * .48),
      Offset(size.width, size.height * .48),
      roads,
    );
    canvas.drawLine(
      Offset(size.width * .48, 0),
      Offset(size.width * .48, size.height),
      roads,
    );

    final route = Paint()
      ..color = const Color(0xFF00652C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (selectedId == 'park') {
      path.moveTo(size.width * .18, size.height * .18);
      path.quadraticBezierTo(
        size.width * .32,
        size.height * .08,
        size.width * .38,
        size.height * .25,
      );
      path.quadraticBezierTo(
        size.width * .25,
        size.height * .35,
        size.width * .14,
        size.height * .25,
      );
    } else if (selectedId == 'river') {
      path.moveTo(size.width * .05, size.height * .78);
      path.quadraticBezierTo(
        size.width * .33,
        size.height * .62,
        size.width * .72,
        size.height * .76,
      );
    } else {
      path.moveTo(size.width * .24, size.height * .20);
      path.quadraticBezierTo(
        size.width * .42,
        size.height * .32,
        size.width * .58,
        size.height * .52,
      );
      path.quadraticBezierTo(
        size.width * .70,
        size.height * .62,
        size.width * .80,
        size.height * .78,
      );
    }
    canvas.drawPath(path, route);
    canvas.drawCircle(
      path.getBounds().topLeft,
      6,
      Paint()..color = const Color(0xFF00652C),
    );
    canvas.drawCircle(
      path.getBounds().bottomRight,
      7,
      Paint()..color = const Color(0xFFBA1A1A),
    );
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) =>
      oldDelegate.selectedId != selectedId;
}
