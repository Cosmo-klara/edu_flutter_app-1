import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class CollegePage extends StatefulWidget {
  const CollegePage({super.key});

  @override
  State<CollegePage> createState() => _CollegePageState();
}

class _CollegePageState extends State<CollegePage> {
  final ApiClient _client = ApiClient();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _collegeKeywordController = TextEditingController();
  Future<List<SchoolEnrollmentRecord>>? _recordsFuture;
  Future<List<CollegeSummary>>? _collegeFuture;
  String? _token;
  bool _initialized = false;
  String? _selectedCollegeProvince;
  bool _only985 = false;

  static const List<String> _provinces = [
    '北京市',
    '天津市',
    '河北省',
    '山西省',
    '内蒙古自治区',
    '辽宁省',
    '吉林省',
    '黑龙江省',
    '上海市',
    '江苏省',
    '浙江省',
    '安徽省',
    '福建省',
    '江西省',
    '山东省',
    '河南省',
    '湖北省',
    '湖南省',
    '广东省',
    '广西壮族自治区',
    '海南省',
    '重庆市',
    '四川省',
    '贵州省',
    '云南省',
    '西藏自治区',
    '陕西省',
    '甘肃省',
    '青海省',
    '宁夏回族自治区',
    '新疆维吾尔自治区',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final scope = AuthScope.of(context);
    _token = scope.session.token;
    _schoolController.text = scope.session.user.schoolName ?? '';
    _recordsFuture = _fetchRecords();
    _collegeFuture = _fetchColleges();
    _initialized = true;
  }

  Future<List<SchoolEnrollmentRecord>> _fetchRecords() async {
    final schoolName = _schoolController.text.trim();
    if (_token == null || _token!.isEmpty || schoolName.isEmpty) {
      return const [];
    }
    final query = {'schoolName': schoolName};
    final yearText = _yearController.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      if (year != null) query['graduationYear'] = year.toString();
    }
    final response = await _client.get(
      '/school-enrollment',
      headers: {'Authorization': 'Bearer $_token'},
      query: query,
    );
    final rows = response['data'] as List? ?? const [];
    return rows.map((e) => SchoolEnrollmentRecord.fromJson(e)).toList();
  }

  Future<List<CollegeSummary>> _fetchColleges() async {
    final query = <String, String>{'pageSize': '20'};
    final keyword = _collegeKeywordController.text.trim();
    if (keyword.isNotEmpty) query['q'] = keyword;
    if (_selectedCollegeProvince != null && _selectedCollegeProvince!.isNotEmpty) {
      query['province'] = _selectedCollegeProvince!;
    }
    if (_only985) query['is985'] = '1';
    final response = await _client.get('/colleges', query: query);
    var rows = response['data'] as List? ?? const [];
    if (rows.isEmpty && query.containsKey('province')) {
      final fallbackQuery = Map<String, String>.from(query)..remove('province');
      final fallbackResp = await _client.get('/colleges', query: fallbackQuery);
      final normalizedTarget = _normalizeProvince(_selectedCollegeProvince!);
      rows = (fallbackResp['data'] as List? ?? const []).where((row) {
        final province = row['PROVINCE']?.toString() ?? '';
        return _normalizeProvince(province) == normalizedTarget;
      }).toList();
    }
    return rows.map((e) => CollegeSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  String _normalizeProvince(String input) {
    var result = input.trim();
    const suffixes = ['特别行政区', '维吾尔自治区', '壮族自治区', '回族自治区', '自治区', '省', '市'];
    for (final suffix in suffixes) {
      if (result.endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length);
        break;
      }
    }
    return result;
  }

  void _onSearchColleges() {
    setState(() {
      _collegeFuture = _fetchColleges();
    });
  }

  Future<void> _openCollegeDetail(CollegeSummary summary) async {
    try {
      final detail = await _client.get('/colleges/${summary.collegeCode}');
      if (!mounted) return;
      final data = detail['data'] as Map<String, dynamic>? ?? {};
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(summary.collegeName),
          content: Text(
            '所在地：${data['PROVINCE'] ?? '-'}\n'
            '城市：${data['CITY_NAME'] ?? '-'}\n'
            '985：${summary.is985 ? '是' : '否'}\n'
            '211：${summary.is211 ? '是' : '否'}\n'
            '双一流：${summary.isDoubleFirstClass ? '是' : '否'}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('关闭')),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('院校详情加载失败')));
    }
  }

  void _onSearch() {
    setState(() {
      _recordsFuture = _fetchRecords();
    });
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _yearController.dispose();
    _collegeKeywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: '全国院校库',
            subtitle: '来源：院校基础数据',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedCollegeProvince,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('全部省份', overflow: TextOverflow.ellipsis),
                          ),
                          ..._provinces.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p,
                              child: Text(p, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCollegeProvince = value;
                            _collegeFuture = _fetchColleges();
                          });
                        },
                        decoration: const InputDecoration(labelText: '省份'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _collegeKeywordController,
                        decoration: const InputDecoration(labelText: '关键词', hintText: '输入院校名称'),
                        onSubmitted: (_) => _onSearchColleges(),
                      ),
                    ),
                  ],
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('仅展示 985 院校'),
                  value: _only985,
                  onChanged: (value) {
                    setState(() {
                      _only985 = value;
                      _collegeFuture = _fetchColleges();
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _collegeFuture = _fetchColleges();
                          });
                        },
                        child: const Text('检索院校'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCollegeProvince = null;
                            _collegeKeywordController.clear();
                            _only985 = false;
                            _collegeFuture = _fetchColleges();
                          });
                        },
                        child: const Text('重置条件'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<CollegeSummary>>(
                  future: _collegeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('院校数据加载失败：${snapshot.error}');
                    }
                    final colleges = snapshot.data ?? const [];
                    if (colleges.isEmpty) {
                      return const Text('暂无院校记录，请调整筛选条件。');
                    }
                    return Column(
                      children: [
                        for (final college in colleges)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCollegeCard(
                              context: context,
                              title: college.collegeName,
                              subtitle: '院校代码：${college.collegeCode}',
                              statusLine: [
                                if (college.is985) '985',
                                if (college.is211) '211',
                                if (college.isDoubleFirstClass) '双一流',
                              ].join(' · '),
                              stats: [
                                _buildStatChip(context, Icons.place_rounded, '省份', college.province),
                                if (college.cityName != null && college.cityName!.isNotEmpty)
                                  _buildStatChip(context, Icons.location_city_rounded, '城市', college.cityName!),
                              ],
                              onTap: () => _openCollegeDetail(college),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '院校筛选',
            subtitle: '快速定位目标院校',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _schoolController,
                        decoration: const InputDecoration(
                          labelText: '学校名称',
                          hintText: '输入学校名称（必填）',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '毕业年份',
                          hintText: '例如 2024',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _recordsFuture = _fetchRecords();
                          });
                        },
                        child: const Text('立即筛选'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _yearController.clear();
                            _recordsFuture = _fetchRecords();
                          });
                        },
                        child: const Text('重置条件'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '院校列表',
            subtitle: '基于招生数据',
            child: FutureBuilder<List<SchoolEnrollmentRecord>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('院校数据加载失败：${snapshot.error}');
                }
                final records = snapshot.data ?? const [];
                if (records.isEmpty) {
                  return const Text('暂无记录，请调整筛选条件。');
                }
                return Column(
                  children: [
                    for (final record in records)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCollegeCard(
                          context: context,
                          title: record.collegeName,
                          subtitle: '毕业年份：${record.graduationYear ?? '-'}',
                          statusLine: '招生 ${record.admissionCountLabel}',
                          stats: [
                            _buildStatChip(context, Icons.emoji_events_rounded, '最低排名', record.minRankLabel),
                            _buildStatChip(context, Icons.timeline_rounded, '计划人数', record.admissionCountLabel),
                            _buildStatChip(context, Icons.grade_rounded, '最低分', record.minScoreLabel),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '我的对比列表',
            subtitle: '2 组对比草案',
            child: Row(
              children: [
                Expanded(
                  child: _CompareCard(
                    title: '师范类院校',
                    subtitle: '华东师范大学 vs. 南京师范大学',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompareCard(
                    title: '综合类院校',
                    subtitle: '浙江大学 vs. 上海交通大学',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Widget> stats,
    String? statusLine,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final card = Ink(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F8FF), Color(0xFFE9EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A2C5BF0)),
        boxShadow: const [BoxShadow(color: Color(0x142C5BF0), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF273266),
                        ),
                      ),
                      if (statusLine != null && statusLine.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0x1A2C5BF0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLine,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C5BF0),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF5B668F)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stats,
            ),
            if (onTap != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('查看详情'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2C5BF0)),
          const SizedBox(width: 6),
          Text(
            '$label：',
            style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF4C5B8F)),
          ),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1F2A56)),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769))),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: FilledButton.tonal(onPressed: onTap, child: const Text('查看详情')),
            ),
          ],
        ),
      ),
    );
  }
}

class CollegeSummary {
  const CollegeSummary({
    required this.collegeCode,
    required this.collegeName,
    required this.province,
    this.cityName,
    required this.is985,
    required this.is211,
    required this.isDoubleFirstClass,
  });

  final int collegeCode;
  final String collegeName;
  final String province;
  final String? cityName;
  final bool is985;
  final bool is211;
  final bool isDoubleFirstClass;

  factory CollegeSummary.fromJson(Map<String, dynamic> json) {
    return CollegeSummary(
      collegeCode: int.tryParse(json['COLLEGE_CODE']?.toString() ?? '') ?? 0,
      collegeName: json['COLLEGE_NAME']?.toString() ?? '-',
      province: json['PROVINCE']?.toString() ?? '-',
      cityName: json['CITY_NAME']?.toString(),
      is985: _toBool(json['IS_985']),
      is211: _toBool(json['IS_211']),
      isDoubleFirstClass: _toBool(json['IS_DFC'] ?? json['IS_DOUBLE_FIRST_CLASS']),
    );
  }

  static bool _toBool(Object? value) {
    if (value == null) return false;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}

class SchoolEnrollmentRecord {
  const SchoolEnrollmentRecord({
    required this.collegeName,
    this.graduationYear,
    this.admissionCount,
    this.minScore,
    this.minRank,
  });

  final String collegeName;
  final int? graduationYear;
  final int? admissionCount;
  final int? minScore;
  final int? minRank;

  factory SchoolEnrollmentRecord.fromJson(Map<String, dynamic> json) {
    return SchoolEnrollmentRecord(
      collegeName: json['COLLEGE_NAME']?.toString() ?? '-',
      graduationYear: int.tryParse(json['GRADUATION_YEAR']?.toString() ?? ''),
      admissionCount: int.tryParse(json['ADMISSION_COUNT']?.toString() ?? ''),
      minScore: int.tryParse(json['MIN_SCORE']?.toString() ?? ''),
      minRank: int.tryParse(json['MIN_RANK']?.toString() ?? ''),
    );
  }

  String get graduationYearLabel => graduationYear?.toString() ?? '-';
  String get admissionCountLabel => admissionCount?.toString() ?? '-';
  String get minScoreLabel => minScore?.toString() ?? '-';
  String get minRankLabel => minRank?.toString() ?? '-';
}
