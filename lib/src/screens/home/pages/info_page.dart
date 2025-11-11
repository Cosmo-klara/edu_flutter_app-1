import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'package:zygc_flutter_prototype/src/models/auth_models.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({
    super.key,
    required this.onEditProfile,
    required this.onViewPreferences,
    required this.onViewAnalysis,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onViewPreferences;
  final VoidCallback onViewAnalysis;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final ApiClient _client = ApiClient();
  Future<List<StudentScore>>? _scoresFuture;
  late AuthSession _session;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final scope = AuthScope.of(context);
    _session = scope.session;
    _scoresFuture = _fetchScores();
    _initialized = true;
  }

  Future<List<StudentScore>> _fetchScores() async {
    final response = await _client.get(
      '/student-score/mine',
      headers: {'Authorization': 'Bearer ${_session.token}'},
    );
    final rows = response['data'] as List? ?? const [];
    return rows.map((e) => StudentScore.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: '基本信息',
            subtitle: '完善身份信息以匹配正确批次',
            trailing: FilledButton.tonal(onPressed: widget.onEditProfile, child: const Text('确认信息')),
            child: _InfoGrid(
              items: [
                _InfoItem(label: '所在省份', value: user.province ?? '未填写'),
                _InfoItem(label: '毕业高中', value: user.schoolName ?? '未填写'),
                _InfoItem(label: '年级', value: '高三（2026届）'),
                _InfoItem(label: '身份', value: '学生'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '成绩信息',
            subtitle: '同步最新模考成绩',
            trailing: FilledButton.tonal(onPressed: widget.onViewAnalysis, child: const Text('确认成绩')),
            child: FutureBuilder<List<StudentScore>>(
              future: _scoresFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingIndicator();
                }
                if (snapshot.hasError) {
                  return Text('成绩加载失败：${snapshot.error}');
                }
                final scores = snapshot.data ?? const [];
                if (scores.isEmpty) {
                  return const Text('暂无成绩，请同步最新成绩。');
                }
                final latest = scores.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoGrid(
                      items: [
                        _InfoItem(label: '总分 / 综合分', value: latest.totalScore.toString()),
                        _InfoItem(label: '全省位次', value: latest.rankLabel),
                        _InfoItem(label: '考试年份', value: latest.examYear.toString()),
                        _InfoItem(label: '录入时间', value: latest.createdAtLabel),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('成绩录入省份：${latest.province}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '选科信息',
            subtitle: '匹配不同省级招生政策',
            trailing: FilledButton.tonal(onPressed: widget.onViewPreferences, child: const Text('确认选科')),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                TagChip(label: '物理'),
                TagChip(label: '化学'),
                TagChip(label: '政治'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '志愿偏好',
            subtitle: '指导冲稳保比例与偏好匹配',
            trailing: FilledButton.tonal(onPressed: widget.onViewPreferences, child: const Text('确认偏好')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    TagChip(label: '地区：长三角'),
                    TagChip(label: '层次：985 优先'),
                    TagChip(label: '专业：教育学'),
                    TagChip(label: '冲/稳/保：2 · 5 · 3'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '喜欢充满人文氛围的城市，宿舍条件较为重要。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: items.map((item) {
        return Container(
          width: double.infinity, // 占据全宽
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label, 
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.value, 
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class StudentScore {
  const StudentScore({
    required this.examYear,
    required this.totalScore,
    required this.province,
    this.rankInProvince,
    this.createdAt,
  });

  final int examYear;
  final int totalScore;
  final String province;
  final int? rankInProvince;
  final String? createdAt;

  factory StudentScore.fromJson(Map<String, dynamic> json) {
    return StudentScore(
      examYear: int.tryParse(json['EXAM_YEAR']?.toString() ?? '') ?? 0,
      totalScore: int.tryParse(json['TOTAL_SCORE']?.toString() ?? '') ?? 0,
      province: json['PROVINCE']?.toString() ?? '-',
      rankInProvince: int.tryParse(json['RANK_IN_PROVINCE']?.toString() ?? ''),
      createdAt: json['CREATED_AT']?.toString(),
    );
  }

  String get rankLabel => rankInProvince == null ? '未提供' : rankInProvince.toString();
  String get createdAtLabel => (createdAt ?? '-').split(' ').first;
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
