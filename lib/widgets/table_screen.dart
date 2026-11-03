import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/common.dart';
import '../core/theme.dart';

enum FType { text, multiline, number, date, boolean, select, lookup, image }

class FieldSpec {
  final String key;
  final String label;
  final FType type;
  final bool required;
  final List<MapEntry<String, String>>? options; // لـ select
  final Future<List<MapEntry<String, String>>> Function()? lookup; // لـ lookup
  final dynamic initial;
  FieldSpec(this.key, this.label, this.type,
      {this.required = false, this.options, this.lookup, this.initial});
}

/// قائمة بيانات عامة مع بحث وإضافة/تعديل/حذف (حسب الصلاحية).
/// الصلاحية الفعلية تفرضها RLS في قاعدة البيانات؛ canEdit هنا لإخفاء الأزرار فقط.
class TableScreen extends StatefulWidget {
  final String table;
  final String? writeTable;
  final String select;
  final List<FieldSpec> fields;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;
  final bool canEdit;
  final bool canAdd;
  final bool canDelete;
  final bool searchable;
  final String orderBy;
  final bool ascending;
  final Map<String, Object> filters;
  final Widget Function(List<Map<String, dynamic>>)? header;
  final Widget? Function(Map<String, dynamic>, int)? leading;
  final String? upsertOn;
  final String addLabel;
  final String emptyText;

  const TableScreen({
    super.key,
    required this.table,
    required this.select,
    required this.fields,
    required this.titleOf,
    required this.subtitleOf,
    this.writeTable,
    this.canEdit = false,
    this.canAdd = true,
    this.canDelete = true,
    this.searchable = true,
    this.orderBy = 'id',
    this.ascending = true,
    this.filters = const {},
    this.header,
    this.leading,
    this.upsertOn,
    this.addLabel = 'إضافة',
    this.emptyText = 'لا توجد بيانات بعد',
  });

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;
  String q = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      var query = sb.from(widget.table).select(widget.select);
      for (final e in widget.filters.entries) {
        query = query.eq(e.key, e.value);
      }
      final res = await query.order(widget.orderBy, ascending: widget.ascending);
      rows = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      error = errText(e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit(Map<String, dynamic>? row) async {
    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => RecordEditor(
        title: row == null ? widget.addLabel : 'تعديل',
        fields: widget.fields,
        row: row,
      ),
    );
    if (res == null) return;
    try {
      final t = widget.writeTable ?? widget.table;
      if (row == null) {
        if (widget.upsertOn != null) {
          await sb.from(t).upsert(res, onConflict: widget.upsertOn!);
        } else {
          await sb.from(t).insert(res);
        }
      } else {
        await sb.from(t).update(res).eq('id', row['id']);
      }
      bump();
      await _load();
      if (mounted) toast(context, 'تم الحفظ بنجاح');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    if (!await confirmDelete(context, widget.titleOf(row))) return;
    try {
      await sb.from(widget.writeTable ?? widget.table).delete().eq('id', row['id']);
      bump();
      await _load();
      if (mounted) toast(context, 'تم الحذف');
    } catch (e) {
      if (mounted) toast(context, errText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (widget.canEdit && widget.canAdd)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: Text(widget.addLabel),
            )
          : null,
      body: Column(children: [
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim()),
              decoration: const InputDecoration(
                hintText: 'بحث…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
        Expanded(child: RefreshIndicator(onRefresh: _load, child: _body())),
      ]),
    );
  }

  Widget _body() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return ListView(children: [
        const SizedBox(height: 80),
        Center(child: Text(error!, textAlign: TextAlign.center)),
        const SizedBox(height: 12),
        Center(child: FilledButton(onPressed: _load, child: const Text('إعادة المحاولة'))),
      ]);
    }
    final list = q.isEmpty
        ? rows
        : rows.where((r) => '${widget.titleOf(r)} ${widget.subtitleOf(r)}'.contains(q)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 96),
      children: [
        if (widget.header != null) widget.header!(rows),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
                child: Text(widget.emptyText,
                    style: const TextStyle(color: AppColors.muted))),
          ),
        for (var i = 0; i < list.length; i++) _item(list[i], i),
      ],
    );
  }

  Widget _item(Map<String, dynamic> r, int i) {
    final lead = widget.leading?.call(r, i);
    return SoftCard(
      child: Row(children: [
        if (lead != null) ...[lead, const SizedBox(width: 12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titleOf(r),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(widget.subtitleOf(r),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
          ]),
        ),
        if (widget.canEdit) ...[
          IconButton(
              tooltip: 'تعديل',
              onPressed: () => _edit(r),
              icon: const Icon(Icons.edit_outlined, color: AppColors.green)),
          if (widget.canDelete)
            IconButton(
                tooltip: 'حذف',
                onPressed: () => _delete(r),
                icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
        ],
      ]),
    );
  }
}

class RecordEditor extends StatefulWidget {
  final String title;
  final List<FieldSpec> fields;
  final Map<String, dynamic>? row;
  const RecordEditor({super.key, required this.title, required this.fields, this.row});

  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final _form = GlobalKey<FormState>();
  final Map<String, dynamic> vals = {};
  final Map<String, TextEditingController> ctl = {};
  final Map<String, List<MapEntry<String, String>>> opts = {};
  bool uploading = false;

  bool _textual(FType t) =>
      t == FType.text || t == FType.multiline || t == FType.number || t == FType.date;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final init = widget.row != null ? widget.row![f.key] : f.initial;
      vals[f.key] = init;
      if (_textual(f.type)) {
        final isNum = f.type == FType.number || f.type == FType.date;
        ctl[f.key] = TextEditingController(
            text: init == null ? '' : (isNum ? ar(init.toString()) : init.toString()));
      }
      if (f.type == FType.lookup) {
        f.lookup!().then((l) {
          if (mounted) setState(() => opts[f.key] = l);
        }).catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    for (final c in ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final out = <String, dynamic>{};
    for (final f in widget.fields) {
      switch (f.type) {
        case FType.text:
        case FType.multiline:
          final t = ctl[f.key]!.text.trim();
          out[f.key] = t.isEmpty ? null : t;
          break;
        case FType.number:
          final t = toLatin(ctl[f.key]!.text.trim());
          out[f.key] = t.isEmpty ? null : num.parse(t);
          break;
        case FType.date:
          final t = toLatin(ctl[f.key]!.text.trim());
          out[f.key] = t.isEmpty ? null : t;
          break;
        case FType.boolean:
          out[f.key] = vals[f.key] == true;
          break;
        case FType.select:
        case FType.lookup:
        case FType.image:
          final v = vals[f.key];
          out[f.key] = (v == null || v.toString().isEmpty) ? null : v;
          break;
      }
    }
    Navigator.pop(context, out);
  }

  Widget _field(FieldSpec f) {
    String? req(String? v) => (f.required && (v == null || v.trim().isEmpty)) ? 'مطلوب' : null;
    switch (f.type) {
      case FType.text:
      case FType.multiline:
        return TextFormField(
          controller: ctl[f.key],
          maxLines: f.type == FType.multiline ? 4 : 1,
          decoration: InputDecoration(labelText: f.label),
          validator: req,
        );
      case FType.number:
        return TextFormField(
          controller: ctl[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: f.label),
          validator: (v) {
            final r = req(v);
            if (r != null) return r;
            if (v != null && v.trim().isNotEmpty && num.tryParse(toLatin(v.trim())) == null) {
              return 'أدخل رقماً صحيحاً';
            }
            return null;
          },
        );
      case FType.date:
        return TextFormField(
          controller: ctl[f.key],
          readOnly: true,
          decoration: InputDecoration(
              labelText: f.label, suffixIcon: const Icon(Icons.calendar_month_outlined)),
          validator: req,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (d != null) {
              final s =
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              ctl[f.key]!.text = ar(s);
            }
          },
        );
      case FType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: vals[f.key] == true,
          onChanged: (v) => setState(() => vals[f.key] = v),
        );
      case FType.select:
        final o = f.options ?? [];
        final cur = o.any((e) => e.key == vals[f.key]) ? vals[f.key] as String : null;
        return DropdownButtonFormField<String>(
          value: cur,
          isExpanded: true,
          decoration: InputDecoration(labelText: f.label),
          items: [for (final e in o) DropdownMenuItem(value: e.key, child: Text(e.value))],
          validator: (v) => (f.required && v == null) ? 'مطلوب' : null,
          onChanged: (v) => setState(() => vals[f.key] = v),
        );
      case FType.lookup:
        final o = opts[f.key] ?? [];
        final cur = o.any((e) => e.key == vals[f.key]) ? vals[f.key] as String : null;
        return DropdownButtonFormField<String>(
          value: cur,
          isExpanded: true,
          decoration: InputDecoration(labelText: f.label),
          items: [for (final e in o) DropdownMenuItem(value: e.key, child: Text(e.value))],
          validator: (v) => (f.required && v == null) ? 'مطلوب' : null,
          onChanged: (v) => setState(() => vals[f.key] = v),
        );
      case FType.image:
        final url = vals[f.key] as String?;
        return Row(children: [
          if (url != null && url.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: uploading
                  ? null
                  : () async {
                      setState(() => uploading = true);
                      try {
                        final u = await pickAndUploadImage();
                        if (u != null) vals[f.key] = u;
                      } catch (e) {
                        if (mounted) toast(context, errText(e), error: true);
                      }
                      if (mounted) setState(() => uploading = false);
                    },
              icon: uploading
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.image_outlined),
              label: Text(url == null || url.isEmpty ? f.label : 'تغيير ${f.label}'),
            ),
          ),
          if (url != null && url.isNotEmpty)
            IconButton(
                onPressed: () => setState(() => vals[f.key] = null),
                icon: const Icon(Icons.close)),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            for (final f in widget.fields) ...[_field(f), const SizedBox(height: 12)],
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: _save, child: const Text('حفظ'))),
            ]),
          ]),
        ),
      ),
    );
  }
}
