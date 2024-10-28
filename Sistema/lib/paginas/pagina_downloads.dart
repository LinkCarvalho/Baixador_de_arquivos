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
  late Future<List<appwrite.File>> _filesFuture; // recebe todos os arquivo do servidor
  String _pesquisa = '';
  bool _selecao = false; //variavel de controle para alternar entre baixar um arquivo ou mais de uma vez
  List<String> _arquivosSelecionados = []; //lista que armazena todos os arquivos selecionados para download

  @override
  void initState() {
    super.initState();
    final authAPI appwrite = context.read<authAPI>();
    _filesFuture = appwrite.getUserFiles(APPWRITE_BUCKET);
  }

  String capitalize(String s) {//função de apoio para barraPesquisa
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  barraPesquisa() { //Cria uma barra de pesquisa para pesquisar os exames pelo nome
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

  void _selecionarArquivos() {// controla a alternancia entre baixar 1 ou mais arquivos
    setState(() {
      _selecao = !_selecao;
      _arquivosSelecionados.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página de exames',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(// botao que alterna as formas de download, com um menu popup para isso
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              final authAPI appwrite = context.read<authAPI>();
              appwrite.signOut();
            },
          ),
          PopupMenuButton(
              onSelected: (valor) async {
                if (valor == 'Selecionar') {
                  _selecionarArquivos();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    value: 'Selecionar',
                    child: Text('Selecionar'),
                  ),
                ];
              },
              color: Colors.white),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: barraPesquisa(),
          ),
          Expanded(
            child: FutureBuilder<List<appwrite.File>>(
              future: _filesFuture, //lista todos os arquivos um abaixo do outro
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum arquivo encontrado.'));
                } else {
                  final files = snapshot.data!
                      .where((file) => file.name.contains(_pesquisa))
                      .toList();

                  return ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      bool isSelected = _arquivosSelecionados.contains(file.$id);
                      return ListTile(
                        title: Text(file.name),
                        leading: _selecao
                            ? Checkbox(//se estiver no modo de baixar mais de um arquivo, aparece
                          // uma checkbox para escolher o arquivo ao lado
                          value: isSelected,
                          onChanged: (bool? selected) {
                            setState(() {
                              if (selected == true) {
                                _arquivosSelecionados.add(file.$id);
                              } else {
                                _arquivosSelecionados.remove(file.$id);
                              }
                            });
                          },
                        )
                            : null,
                        trailing: !_selecao
                            ? PopupMenuButton(// se estiver no modo de arquivo unico,
                          //outro menu pop irá mostrar a opção entra baixar so o arquivo ou baixar
                          //o arquivo e seus metadados
                          onSelected: (valor) async {
                            if (valor == 'download arquivo') {
                              final authAPI appwrite =
                              context.read<authAPI>();
                              await appwrite.downloadArquivo(
                                  APPWRITE_BUCKET, file.$id);
                            } else if (valor == 'download metadados') {
                              final authAPI appwrite =
                              context.read<authAPI>();
                              await appwrite.metadadoArquivo(
                                  APPWRITE_BUCKET, file.$id);
                              await appwrite.downloadArquivo(
                                  APPWRITE_BUCKET, file.$id);
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
                                child:
                                Text('Baixar Arquivo com Metadados'),
                              ),
                            ];
                          },
                          icon: Icon(Icons.download),
                        )
                            : null,
                      );
                    },
                  );
                }
              },
            ),
          ),
          if (_selecao)
            Padding( // botao para baixar multiplos arquivos
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  final authAPI appwrite = context.read<authAPI>();
                  for (String fileId in _arquivosSelecionados) {
                    await appwrite.downloadArquivo(APPWRITE_BUCKET, fileId);
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
