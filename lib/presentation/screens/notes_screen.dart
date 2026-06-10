import 'package:flutter/material.dart';
import '../../core/secure_storage.dart';
import '../../data/datasources/notes_remote_data_source.dart';

class NotesScreen extends StatefulWidget {
  final String? lessonId;
  final String? lessonTitle;
  final int? currentVideoSeconds;

  const NotesScreen({
    super.key,
    this.lessonId,
    this.lessonTitle,
    this.currentVideoSeconds,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _ds = NotesRemoteDataSource();
  final _noteCtrl = TextEditingController();
  String? _token;
  List<dynamic> _notes = [];
  bool _loading = true;
  bool _saving = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _token = await SecureStorage.getToken();
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }
    final notes = widget.lessonId != null
        ? await _ds.getNotesForLesson(widget.lessonId!, _token!)
        : await _ds.getAllNotes(_token!);
    if (mounted) {
      setState(() {
        _notes = notes;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final content = _noteCtrl.text.trim();
    if (content.isEmpty || _token == null || widget.lessonId == null) return;
    setState(() => _saving = true);
    try {
      if (_editingId != null) {
        await _ds.updateNote(_editingId!, content, _token!);
        final idx = _notes.indexWhere((n) => n['id'] == _editingId);
        if (idx != -1) {
          setState(() {
            _notes[idx] = {..._notes[idx], 'content': content};
          });
        }
        _editingId = null;
      } else {
        final note = await _ds.createNote(
          widget.lessonId!,
          content,
          widget.currentVideoSeconds,
          _token!,
        );
        setState(() => _notes.insert(0, note));
      }
      _noteCtrl.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save note'),
              backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _delete(String noteId) async {
    if (_token == null) return;
    await _ds.deleteNote(noteId, _token!);
    setState(() => _notes.removeWhere((n) => n['id'] == noteId));
  }

  String _formatTimestamp(int? secs) {
    if (secs == null) return '';
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLesson = widget.lessonId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isLesson
            ? 'Notes — ${widget.lessonTitle ?? "Lesson"}'
            : 'My Notes'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (isLesson) _buildInputBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildNoteCard(_notes[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _noteCtrl,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: widget.currentVideoSeconds != null
                      ? 'Note at ${_formatTimestamp(widget.currentVideoSeconds)}...'
                      : 'Add a note...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _editingId != null ? Icons.check : Icons.add,
                          color: const Color(0xFF1A237E),
                        ),
                  tooltip: _editingId != null ? 'Update note' : 'Add note',
                ),
                if (_editingId != null)
                  IconButton(
                    onPressed: () {
                      setState(() => _editingId = null);
                      _noteCtrl.clear();
                    },
                    icon:
                        const Icon(Icons.close, color: Colors.grey, size: 18),
                    tooltip: 'Cancel',
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final content = note['content'] ?? '';
    final timestamp = note['timestamp'] as int?;
    final lessonTitle =
        note['lesson']?['title'] ?? note['lessonTitle'] ?? '';
    final isEditing = _editingId == note['id'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEditing
            ? const Color(0xFF1A237E).withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF1A237E)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (timestamp != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (lessonTitle.isNotEmpty)
                Expanded(
                  child: Text(lessonTitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.blueGrey.shade500),
                      overflow: TextOverflow.ellipsis),
                ),
              const Spacer(),
              if (widget.lessonId != null) ...[
                InkWell(
                  onTap: () {
                    setState(() => _editingId = note['id']);
                    _noteCtrl.text = content;
                  },
                  child: const Icon(Icons.edit_outlined,
                      size: 18, color: Colors.blueGrey),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _delete(note['id']),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_outlined,
                size: 56, color: Colors.blueGrey),
            const SizedBox(height: 16),
            Text(
              widget.lessonId != null
                  ? 'No notes yet. Add your first note above.'
                  : 'No notes yet. Start taking notes while watching lessons.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade500),
            ),
          ],
        ),
      );
}
