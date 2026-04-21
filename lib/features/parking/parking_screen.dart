import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/services/app_state.dart';
import 'camera_capture_screen.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  final _stallController = TextEditingController();
  final _streetController = TextEditingController();
  final _meterController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  final _customAlertController = TextEditingController();

  String? _photoBase64;
  String? _editingId;
  int _selectedAlertLead = 10;
  int _alertRepeatCount = 1;
  bool _useCustomAlert = false;
  double? _previewLatitude;
  double? _previewLongitude;
  bool _isLoadingPreviewLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    if (_durationController.text.isEmpty) {
      _durationController.text =
          appState.settingsService.defaultParkingMinutes.toString();
    }
    if (_previewLatitude == null &&
        _previewLongitude == null &&
        !_isLoadingPreviewLocation) {
      _loadPreviewLocation();
    }
  }

  @override
  void dispose() {
    _stallController.dispose();
    _streetController.dispose();
    _meterController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _customAlertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isCantonese = appState.isCantoneseMode;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: _panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editingId == null
                          ? (isCantonese ? '儲存泊車位置' : 'Save Parking Location')
                          : (isCantonese ? '編輯泊車位置' : 'Edit Parking Location'),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (_editingId != null)
                    TextButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.close_rounded),
                      label: Text(isCantonese ? '取消編輯' : 'Cancel'),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isCantonese
                    ? '目前位置：準備儲存新泊車紀錄\n時間：${DateFormat('h:mm a').format(DateTime.now())}'
                    : 'Current location: ready to save a new parking record\nTime: ${DateFormat('h:mm a').format(DateTime.now())}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFF8A9E8F)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _stallController,
                decoration: InputDecoration(
                  labelText: isCantonese ? '車位' : 'Parking Spot',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: isCantonese ? '街道 / 路口' : 'Street / Cross Street',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _meterController,
                decoration: InputDecoration(
                  labelText: isCantonese ? '泊車錶位置' : 'Parking Meter',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isCantonese ? '備註' : 'Notes',
                ),
              ),
              const SizedBox(height: 18),
              _PhotoPanel(
                photoBase64: _photoBase64,
                onCapture: _capturePhoto,
                onClear: () => setState(() => _photoBase64 = null),
                isCantonese: isCantonese,
              ),
              const SizedBox(height: 18),
              _LocationPreviewCard(
                isCantonese: isCantonese,
                latitude: _previewLatitude,
                longitude: _previewLongitude,
                isLoading: _isLoadingPreviewLocation,
                onOpenMap: _openCurrentPreviewMap,
                onRefresh: _loadPreviewLocation,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isCantonese
                      ? '泊車計時長度（分鐘）'
                      : 'Parking timer length (minutes)',
                  helperText:
                      isCantonese ? '預設 60 分鐘，可自行修改' : 'Default is 60 minutes',
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isCantonese ? '提醒時間' : 'Alert before',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  color: const Color(0xFF8A9E8F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AlertChip(
                    label: isCantonese ? '前 5 分鐘' : '5 min',
                    selected: _selectedAlertLead == 5,
                    onTap: () => _selectAlertLead(5),
                  ),
                  _AlertChip(
                    label: isCantonese ? '前 10 分鐘' : '10 min',
                    selected: _selectedAlertLead == 10,
                    onTap: () => _selectAlertLead(10),
                  ),
                  _AlertChip(
                    label: isCantonese ? '自訂' : 'Custom',
                    selected: _useCustomAlert,
                    onTap: () =>
                        setState(() => _useCustomAlert = !_useCustomAlert),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isCantonese ? '\u63d0\u9192\u6b21\u6578' : 'Reminder count',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8A9E8F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AlertChip(
                    label: isCantonese ? '\u97ff 1 \u6b21' : '1 time',
                    selected: _alertRepeatCount == 1,
                    onTap: () => setState(() => _alertRepeatCount = 1),
                  ),
                  _AlertChip(
                    label: isCantonese ? '\u97ff 2 \u6b21' : '2 times',
                    selected: _alertRepeatCount == 2,
                    onTap: () => setState(() => _alertRepeatCount = 2),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isCantonese
                    ? '\u5982\u679c\u8a2d\u5b9a\u97ff 2 \u6b21\uff0c\u7b2c\u4e8c\u6b21\u6703\u5728\u7b2c\u4e00\u6b21\u63d0\u9192\u5f8c 1 \u5206\u9418\u5167\u518d\u97ff\u3002'
                    : 'If set to 2 times, the second reminder will fire about 1 minute after the first one.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8A9E8F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isCantonese
                    ? '目前設定：提前 ${_useCustomAlert && _customAlertController.text.trim().isNotEmpty ? _customAlertController.text.trim() : _selectedAlertLead} 分鐘，響 $_alertRepeatCount 次'
                    : 'Current setup: ${_useCustomAlert && _customAlertController.text.trim().isNotEmpty ? _customAlertController.text.trim() : _selectedAlertLead} min before, $_alertRepeatCount time${_alertRepeatCount > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF486157),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_useCustomAlert) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customAlertController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        isCantonese ? '自訂提醒（分鐘）' : 'Custom alert (minutes)',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveTimer,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3D2B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(_editingId == null
                      ? Icons.add_task_rounded
                      : Icons.save_rounded),
                  label: Text(
                    _editingId == null
                        ? (isCantonese ? '儲存泊車位置' : 'Save Parking')
                        : (isCantonese ? '儲存修改' : 'Save Changes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFAF8F4),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1A3D2B).withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Future<void> _saveTimer() async {
    final appState = context.read<AppState>();
    final customAlertValue = int.tryParse(_customAlertController.text.trim());
    final primaryLead =
        _useCustomAlert && customAlertValue != null && customAlertValue > 0
            ? customAlertValue
            : _selectedAlertLead;
    final alertLeads = <int>[primaryLead];
    if (_alertRepeatCount == 2) {
      final secondLead = primaryLead > 1 ? primaryLead - 1 : 1;
      if (!alertLeads.contains(secondLead)) {
        alertLeads.add(secondLead);
      }
    }
    alertLeads.sort((a, b) => a.compareTo(b));

    await appState.saveParking(
      editingId: _editingId,
      label: [
        if (_stallController.text.trim().isNotEmpty)
          '車位：${_stallController.text.trim()}',
        if (_streetController.text.trim().isNotEmpty)
          '街道/路口：${_streetController.text.trim()}',
        if (_meterController.text.trim().isNotEmpty)
          '泊車錶位置：${_meterController.text.trim()}',
      ].join(' | '),
      notes: _notesController.text.trim(),
      durationMinutes: int.tryParse(_durationController.text.trim()) ??
          appState.settingsService.defaultParkingMinutes,
      alertLeadMinutes: alertLeads.first,
      alertLeadMinutesList: alertLeads,
      photoBase64: _photoBase64,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingId == null
              ? (appState.isCantoneseMode
                  ? '已新增泊車計時，並開始倒數。'
                  : 'Parking timer added and started.')
              : (appState.isCantoneseMode
                  ? '已更新泊車計時。'
                  : 'Parking timer updated.'),
        ),
      ),
    );

    _resetForm();
  }

  void _resetForm() {
    final appState = context.read<AppState>();
    setState(() {
      _editingId = null;
      _stallController.clear();
      _streetController.clear();
      _meterController.clear();
      _notesController.clear();
      _durationController.text =
          appState.settingsService.defaultParkingMinutes.toString();
      _customAlertController.clear();
      _photoBase64 = null;
      _selectedAlertLead = 10;
      _alertRepeatCount = 1;
      _useCustomAlert = false;
    });
  }

  void _loadSessionIntoForm(ParkingSession session) {
    final parsed = _splitSavedLabel(session.label);
    setState(() {
      _editingId = session.id;
      _stallController.text = parsed[0];
      _streetController.text = parsed[1];
      _meterController.text = parsed[2];
      _notesController.text = session.notes;
      _durationController.text = session.durationMinutes.toString();
      _photoBase64 = session.photoBase64;
      _alertRepeatCount = session.alertLeadMinutesList.length >= 2 ? 2 : 1;
      _selectedAlertLead = session.alertLeadMinutesList.isEmpty
          ? 10
          : session.alertLeadMinutesList.reduce((a, b) => a > b ? a : b);
      final custom = session.alertLeadMinutesList
          .where((item) => item != 5 && item != 10)
          .toList();
      _useCustomAlert = custom.isNotEmpty;
      _customAlertController.text =
          custom.isEmpty ? '' : custom.first.toString();
    });
  }

  Future<void> _loadPreviewLocation() async {
    setState(() => _isLoadingPreviewLocation = true);
    try {
      final position =
          await context.read<AppState>().locationService.getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _previewLatitude = position.latitude;
        _previewLongitude = position.longitude;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final isCantonese = context.read<AppState>().isCantoneseMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCantonese
                ? '未能載入目前定位預覽。'
                : 'Unable to load the current location preview.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreviewLocation = false);
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => CameraCaptureScreen(
            isCantonese: context.read<AppState>().isCantoneseMode,
          ),
          fullscreenDialog: true,
        ),
      );
      if (bytes == null || bytes.isEmpty) {
        return;
      }
      setState(() {
        _photoBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final isCantonese = context.read<AppState>().isCantoneseMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCantonese
                ? '這部裝置暫時未能拍照，請再試一次。'
                : 'Unable to capture a photo on this device right now.',
          ),
        ),
      );
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openCurrentPreviewMap() async {
    if (_previewLatitude == null || _previewLongitude == null) {
      await _loadPreviewLocation();
    }
    if (_previewLatitude == null || _previewLongitude == null) {
      return;
    }
    await _openMap(_previewLatitude!, _previewLongitude!);
  }

  void _selectAlertLead(int value) {
    setState(() {
      _selectedAlertLead = value;
      _useCustomAlert = false;
    });
  }

  List<String> _splitSavedLabel(String raw) {
    String stall = '';
    String street = '';
    String meter = '';

    for (final part in raw
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)) {
      if (part.startsWith('車位：')) {
        stall = part.replaceFirst('車位：', '').trim();
      } else if (part.startsWith('街道/路口：')) {
        street = part.replaceFirst('街道/路口：', '').trim();
      } else if (part.startsWith('泊車錶位置：')) {
        meter = part.replaceFirst('泊車錶位置：', '').trim();
      } else if (stall.isEmpty) {
        stall = part;
      } else if (street.isEmpty) {
        street = part;
      } else if (meter.isEmpty) {
        meter = part;
      }
    }

    return [stall, street, meter];
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A3D2B) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF1A3D2B) : const Color(0xFFD7DED9),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF3A4A42),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel({
    required this.photoBase64,
    required this.onCapture,
    required this.onClear,
    required this.isCantonese,
  });

  final String? photoBase64;
  final VoidCallback onCapture;
  final VoidCallback onClear;
  final bool isCantonese;

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      imageBytes = base64Decode(photoBase64!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCantonese ? '泊車相片' : 'Parking Photo',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            isCantonese
                ? '拍攝你嘅泊車位置、泊車錶或者附近環境。'
                : 'Take a photo of your parking spot, meter, or surroundings.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF66756E)),
          ),
          const SizedBox(height: 12),
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                imageBytes,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else
            Container(
              height: 146,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F2EA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3DDD1)),
              ),
              alignment: Alignment.center,
              child: Text(
                isCantonese ? '目前未有相片' : 'No photo selected yet',
                style: const TextStyle(
                  color: Color(0xFF8A9E8F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onCapture,
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(isCantonese ? '拍攝泊車相片' : 'Take Parking Photo'),
              ),
              if (imageBytes != null)
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(isCantonese ? '刪除目前相片' : 'Delete current photo'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationPreviewCard extends StatelessWidget {
  const _LocationPreviewCard({
    required this.isCantonese,
    required this.latitude,
    required this.longitude,
    required this.isLoading,
    required this.onOpenMap,
    required this.onRefresh,
  });

  final bool isCantonese;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final VoidCallback onOpenMap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final coords = latitude != null && longitude != null
        ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
        : (isCantonese ? '定位中...' : 'Resolving location...');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCantonese ? '目前位置地圖' : 'Current Location Map',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            coords,
            style: const TextStyle(
              color: Color(0xFF2D4338),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: isLoading ? null : onOpenMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(
                    isCantonese ? '在 Google Maps 開啟' : 'Open in Google Maps'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onRefresh,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(isCantonese ? '重新定位' : 'Refresh location'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactTrafficPanel extends StatelessWidget {
  const _CompactTrafficPanel({
    required this.appState,
    required this.isCantonese,
  });

  final AppState appState;
  final bool isCantonese;

  @override
  Widget build(BuildContext context) {
    final traffic = appState.localTraffic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isCantonese ? '附近即時交通' : 'Live Nearby Traffic',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: appState.isLoadingConditions
                    ? null
                    : () => appState.refreshLocalConditions(
                        radiusMiles: appState.trafficRadiusMiles),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: isCantonese ? '重新載入交通' : 'Refresh traffic',
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (appState.localConditionsError != null)
            Text(
              appState.localConditionsError!,
              style: const TextStyle(
                color: Color(0xFFC94B40),
                fontWeight: FontWeight.w700,
              ),
            )
          else if (traffic == null || appState.isLoadingConditions)
            Text(
              isCantonese ? '載入緊交通資料...' : 'Loading traffic data...',
              style: const TextStyle(
                color: Color(0xFF66756E),
                fontWeight: FontWeight.w700,
              ),
            )
          else if (!traffic.isAvailable)
            Text(
              isCantonese
                  ? '交通資料未能載入：${traffic.errorMessage ?? '未知道原因'}'
                  : 'Traffic could not be loaded: ${traffic.errorMessage ?? 'unknown reason'}',
              style: const TextStyle(
                color: Color(0xFFC94B40),
                fontWeight: FontWeight.w700,
              ),
            )
          else if (traffic.incidents.isEmpty)
            Text(
              isCantonese
                  ? '${traffic.radiusMiles} 英里內暫時未見明顯交通事件。'
                  : 'No major traffic incidents found within ${traffic.radiusMiles} miles.',
              style: const TextStyle(
                color: Color(0xFF66756E),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...traffic.incidents.take(3).map(
                  (incident) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _TrafficIncidentCard(
                      incident: incident,
                      color: appState.trafficSeverityColor(incident),
                      isCantonese: isCantonese,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _TrafficIncidentCard extends StatelessWidget {
  const _TrafficIncidentCard({
    required this.incident,
    required this.color,
    required this.isCantonese,
  });

  final TrafficIncident incident;
  final Color color;
  final bool isCantonese;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  incident.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C2B20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCantonese
                ? '延誤約 ${incident.delayMinutes} 分鐘'
                : 'About ${incident.delayMinutes} minutes delay',
            style: const TextStyle(
              color: Color(0xFF55655D),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openTrafficMap(incident),
            icon: const Icon(Icons.map_outlined),
            label:
                Text(isCantonese ? '在 Google Maps 查看' : 'View in Google Maps'),
          ),
        ],
      ),
    );
  }
}

Future<void> _openTrafficMap(TrafficIncident incident) async {
  final query = _trafficSearchQuery(incident);
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _trafficSearchQuery(TrafficIncident incident) {
  final normalized = incident.title
      .replaceAll('|', ' ')
      .replaceAll('/', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final withoutPrefix = normalized
      .replaceFirst(
        RegExp(
          r'^(Queueing traffic|Slow traffic|Stationary traffic|Heavy traffic)\s*',
          caseSensitive: false,
        ),
        '',
      )
      .trim();

  return withoutPrefix.isEmpty ? normalized : withoutPrefix;
}
