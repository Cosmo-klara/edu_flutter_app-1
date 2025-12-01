import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';

class SystemDataAdminPage extends StatefulWidget {
  const SystemDataAdminPage({super.key});

  @override
  State<SystemDataAdminPage> createState() => _SystemDataAdminPageState();
}

class _SystemDataAdminPageState extends State<SystemDataAdminPage> {
  bool majors = true;
  bool colleges = true;
  bool enrollment = true;

  final timeCtrl = TextEditingController(text: '02:00');
  bool scheduling = false;
  Map<String, dynamic>? status;

  Future<void> _refreshStatus() async {
    final client = ApiClient();
    try {
      final s = await client.get('/admin/import/status');
      setState(() => status = s);
    } catch (_) {}
  }

  Future<void> _runImport() async {
    final scope = AuthScope.of(context);
    final token = scope.session.token;
    final client = ApiClient();
    final datasets = [
      if (majors) 'majors',
      if (colleges) 'colleges',
      if (enrollment) 'enrollment',
    ];
    try {
      await client.post(
        '/admin/import/run',
        headers: {'Authorization': 'Bearer $token'},
        body: {'datasets': datasets},
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已触发导入任务')));
      await _refreshStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  Future<void> _enableSchedule() async {
    final scope = AuthScope.of(context);
    final token = scope.session.token;
    final client = ApiClient();
    final datasets = [
      if (majors) 'majors',
      if (colleges) 'colleges',
      if (enrollment) 'enrollment',
    ];
    setState(() => scheduling = true);
    try {
      await client.post(
        '/admin/import/schedule',
        headers: {'Authorization': 'Bearer $token'},
        body: {'time': timeCtrl.text, 'datasets': datasets},
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已启用自动导入')));
      await _refreshStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置失败: $e')));
    } finally {
      setState(() => scheduling = false);
    }
  }

  Future<void> _disableSchedule() async {
    final scope = AuthScope.of(context);
    final token = scope.session.token;
    final client = ApiClient();
    setState(() => scheduling = true);
    try {
      await client.delete(
        '/admin/import/schedule',
        headers: {'Authorization': 'Bearer $token'},
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已停用自动导入')));
      await _refreshStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    } finally {
      setState(() => scheduling = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = status;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('系统数据管理员'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SectionCard(
              title: '数据源选择',
              subtitle: '选择需要爬取并导入的数据',
              child: Column(
                children: [
                  _CheckRow(label: '专业信息（majors）', value: majors, onChanged: (v) => setState(() => majors = v)),
                  const Divider(height: 24),
                  _CheckRow(label: '院校信息（colleges）', value: colleges, onChanged: (v) => setState(() => colleges = v)),
                  const Divider(height: 24),
                  _CheckRow(label: '招生计划（enrollment）', value: enrollment, onChanged: (v) => setState(() => enrollment = v)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _runImport,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('手动爬取并导入'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: '自动导入',
              subtitle: '设置每日固定时间自动执行',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: timeCtrl,
                    decoration: const InputDecoration(
                      labelText: '每日时间（HH:mm）',
                      hintText: '例如 02:00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: scheduling ? null : _enableSchedule,
                          icon: const Icon(Icons.schedule_rounded),
                          label: const Text('启用自动导入'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: scheduling ? null : _disableSchedule,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('停用'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF04F52)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (s != null) ...[
                    Text('当前状态：${s['enabled'] == true ? '已启用' : '未启用'}'),
                    const SizedBox(height: 4),
                    Text('计划时间：${s['time'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('最近运行：${s['lastRun'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('退出码：${s['lastExitCode']?.toString() ?? '-'}'),
                    const SizedBox(height: 4),
                    if (s['lastError'] != null) Text('错误：${s['lastError']}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}