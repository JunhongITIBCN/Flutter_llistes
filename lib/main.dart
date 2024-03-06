import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => NotaProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Consumer<NotaProvider>(
        builder: (context, notaProvider, child) {
          return ListView.builder(
            itemCount: notaProvider.notes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(notaProvider.notes[index].titol),
                subtitle: Text(
                  notaProvider.notes[index].descripcio,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaginaEditarNota(nota: notaProvider.notes[index])),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaginaAfegirNota()),
          );
        },
      ),
    );
  }
}

class PaginaAfegirNota extends StatefulWidget {
  @override
  _PaginaAfegirNotaState createState() => _PaginaAfegirNotaState();
}

class _PaginaAfegirNotaState extends State<PaginaAfegirNota> {
  final _titolController = TextEditingController();
  final _descripcioController = TextEditingController();

  @override
  void dispose() {
    _titolController.dispose();
    _descripcioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Afegir Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titolController,
              decoration: InputDecoration(labelText: 'Titol'),
            ),
            TextField(
              controller: _descripcioController,
              decoration: InputDecoration(labelText: 'Descripcio'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  child: Text('Afegir Nota'),
                  onPressed: () {
                    if (_titolController.text.isNotEmpty) {
                      var nota = Nota(titol: _titolController.text, descripcio: _descripcioController.text);
                      Provider.of<NotaProvider>(context, listen: false).afegirNotes(nota);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('El titol ha de ser obligatori'),
                        ),
                      );
                    }
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}

class PaginaEditarNota extends StatefulWidget {
  final Nota nota;

  PaginaEditarNota({required this.nota});

  @override
  _PaginaEditarNotaState createState() => _PaginaEditarNotaState();
}

class _PaginaEditarNotaState extends State<PaginaEditarNota> {
  late TextEditingController _titolController;
  late TextEditingController _descripcioController;

  @override
  void initState() {
    super.initState();
    _titolController = TextEditingController(text: widget.nota.titol);
    _descripcioController = TextEditingController(text: widget.nota.descripcio);
  }

  @override
  void dispose() {
    _titolController.dispose();
    _descripcioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titolController,
              decoration: InputDecoration(labelText: 'Titol'),
            ),
            TextField(
              controller: _descripcioController,
              decoration: InputDecoration(labelText: 'Descripcio'),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                child: Text('Actualitzar nota'),
                onPressed: () {
                  if (_titolController.text.isNotEmpty) {
                    var nota = Nota(titol: _titolController.text, descripcio: _descripcioController.text);
                    Provider.of<NotaProvider>(context, listen: false).eliminarNotes(widget.nota);
                    Provider.of<NotaProvider>(context, listen: false).afegirNotes(nota);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('El titol ha de ser obligatori'),
                      ),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.delete),
        onPressed: () {
          Provider.of<NotaProvider>(context, listen: false).eliminarNotes(widget.nota);
          Navigator.pop(context);
        },
      ),
    );
  }
}


class Nota {
  String titol;
  String descripcio;

  Nota({required this.titol, this.descripcio = ''});

  Map<String, dynamic> toMap() {
    return {
      'titol': titol,
      'descripcio': descripcio,
    };
  }

  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      titol: map['titol'],
      descripcio: map['descripcio'],
    );
  }
}


class NotaProvider extends ChangeNotifier {
  List<Nota> _notes = [];

  List<Nota> get notes => _notes;

  NotaProvider() {
    carregarNotes();
  }

  void afegirNotes(Nota nota) {
    _notes.add(nota);
    guardarNotes();
    notifyListeners();
  }

  void eliminarNotes(Nota nota) {
    _notes.remove(nota);
    guardarNotes();
    notifyListeners();
  }

  Future<void> guardarNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stringNotes = _notes.map((nota) => jsonEncode(nota.toMap())).toList();
    await prefs.setStringList('notes', stringNotes);
  }

  Future<void> carregarNotes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? stringNotes = prefs.getStringList('notes');
    if (stringNotes != null) {
      _notes = stringNotes.map((nota) => Nota.fromMap(jsonDecode(nota))).toList();
      notifyListeners();
    }
  }
}