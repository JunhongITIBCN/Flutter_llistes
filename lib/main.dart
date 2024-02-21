import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotesProvider(),
      child: MaterialApp(
        title: 'Notes App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: NotesListScreen(),
      ),
    );
  }
}

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  Future<void> loadNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? notesJson = prefs.getStringList('notes');

    if (notesJson != null) {
      _notes = notesJson.map((noteJson) => Note.fromJson(noteJson)).toList();
      notifyListeners();
    }
  }

  Future<void> saveNotes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> notesJson = _notes.map((note) => note.toJson()).toList();
    await prefs.setStringList('notes', notesJson);
    notifyListeners();
  }

  void addNote(Note note) {
    _notes.add(note);
    saveNotes();
  }

  void editNote(Note editedNote) {
    final index = _notes.indexWhere((n) => n.id == editedNote.id);
    if (index != -1) {
      _notes[index] = editedNote;
      saveNotes();
    }
  }

  void deleteNote(Note note) {
    _notes.removeWhere((n) => n.id == note.id);
    saveNotes();
  }
}

class NotesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Consumer<NotesProvider>(
        builder: (context, notesProvider, child) {
          final notes = notesProvider.notes;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.content),
                onTap: () => _editNote(context, note),
                onLongPress: () => _deleteNote(context, note),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _addNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditNoteScreen()),
    );
  }

  void _editNote(BuildContext context, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditNoteScreen(note: note)),
    );
  }

  void _deleteNote(BuildContext context, Note note) {
    Provider.of<NotesProvider>(context, listen: false).deleteNote(note);
  }
}

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  AddEditNoteScreen({Key? key, this.note}) : super(key: key);

  @override
  _AddEditNoteScreenState createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Content'),
              maxLines: null,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _saveNote(context),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNote(BuildContext context) {
    final newNote = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text,
      content: _contentController.text,
    );

    if (widget.note == null) {
      Provider.of<NotesProvider>(context, listen: false).addNote(newNote);
    } else {
      Provider.of<NotesProvider>(context, listen: false).editNote(newNote);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class Note {
  final int id;
  final String title;
  final String content;

  Note({
    required this.id,
    required this.title,
    required this.content,
  });

  factory Note.fromJson(String json) {
    final map = Map<String, dynamic>.from(jsonDecode(json));
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
    );
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'title': title,
      'content': content,
    });
  }
}
