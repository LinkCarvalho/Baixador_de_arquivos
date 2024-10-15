import 'package:flutter/material.dart';
import 'package:projeto/Appwrite/auth_api.dart';
import 'package:provider/provider.dart';
import 'package:appwrite/models.dart' as appwrite;
import 'package:projeto/Appwrite/constantes.dart';

class pagina_download extends StatefulWidget {
  const pagina_download({super.key});

  @override
  State<pagina_download> createState() => _PaginaDownloadState();
}

class _PaginaDownloadState extends State<pagina_download> {
  late Future<List<appwrite.File>> _filesFuture;
  String _pesquisa = '';
  bool _selectionMode = false;
  List<String> _selectedFiles = [];


  @override
  void initState() {
    super.initState();
    final authAPI appwrite = context.read<authAPI>();
    _filesFuture = appwrite.getUserFiles(APPWRITE_BUCKET);
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }


  barraPesquisa() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar exames',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _pesquisa = capitalize(value);
        });
      },
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedFiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de exames', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              final authAPI appwrite = context.read<authAPI>();
              appwrite.signOut();
            },
          ),
          PopupMenuButton(
              onSelected: (valor) async{
                if(valor == 'Selecionar'){
                  _toggleSelectionMode();
                }
              },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'Selecionar',
                  child: Text('Selecionar'),
                ),
              ];
            }, color: Colors.white),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: barraPesquisa(),
          ),
          Expanded(
            child: FutureBuilder<List<appwrite.File>>( // Usando o File do Appwrite
              future: _filesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nenhum arquivo encontrado.'));
                } else {
                  final files = snapshot.data!
                      .where((file) => file.name.contains(_pesquisa))
                      .toList();

                  return ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      bool isSelected = _selectedFiles.contains(file.$id);
                      return ListTile(
                        title: Text(file.name),
                          leading: _selectionMode
                              ? Checkbox(
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedFiles.add(file.$id);
                                } else {
                                  _selectedFiles.remove(file.$id);
                                }
                              });
                            },
                          )
                              : null,
                        trailing: !_selectionMode
                            ? PopupMenuButton(
                            onSelected: (valor) async {
                              if(valor == 'download arquivo'){
                                final authAPI appwrite = context.read<authAPI>();
                                await appwrite.download(APPWRITE_BUCKET, file.$id);
                              }else if(valor == 'download metadados'){
                                final authAPI appwrite = context.read<authAPI>();
                                await appwrite.metadados(APPWRITE_BUCKET, file.$id);
                                await appwrite.download(APPWRITE_BUCKET, file.$id);
                              }
                            },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem(
                                value: 'download arquivo',
                                child: Text('Baixar Arquivo'),
                              ),
                              PopupMenuItem(
                                value: 'download metadados',
                                child: Text('Baixar Arquivo com Metadados'),
                              ),
                            ];
                          },
                          icon: Icon(Icons.download), )
                            : null,
                      );
                    },
                  );
                }
              },
            ),
          ),
          if (_selectionMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  final authAPI appwrite = context.read<authAPI>();
                  for (String fileId in _selectedFiles) {
                    await appwrite.download(APPWRITE_BUCKET, fileId);
                  }
                },
                child: const Text('Baixar selecionados'),
              ),
            ),
        ],
      ),
    );
  }
}


