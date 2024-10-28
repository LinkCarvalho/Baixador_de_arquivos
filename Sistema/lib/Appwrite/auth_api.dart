import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/widgets.dart';
import 'constantes.dart';
import 'dart:io' as dart_io;
import 'package:path_provider/path_provider.dart';


enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class authAPI extends ChangeNotifier{
  Client cliente = Client();
  late final Account conta;
  late final Storage storage;


  late User _currentUser;

  AuthStatus _status = AuthStatus.uninitialized;

  User get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get username => _currentUser.name;
  String? get email => _currentUser.email;
  String? get userid => _currentUser.$id;
  String? get createAt => _currentUser.$createdAt;

  authAPI(){
    init();
    loadUser();
  }

  init(){
    cliente
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_ID)
        .setSelfSigned(status: true);
    conta = Account(cliente);
    storage = Storage(cliente);
    //conecta com o servidor
  }

  loadUser() async {//muda o status para logar o usuario no sistema
    try {
      final user = await conta.get();
      _status = AuthStatus.authenticated;
      _currentUser = user;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<Session> criarSessaoEmail(
      // o usuario digita um email e senha validos e recebe a autenticação para entrar no sistema
          {required String email, required String password}) async {
    try {
      final session =
      await conta.createEmailPasswordSession(email: email, password: password);
      _currentUser = await conta.get();
      _status = AuthStatus.authenticated;
      return session;
    } finally {
      notifyListeners();
    }
  }

  signOut() async {//Ao tentar deslogar, muda o status para nao autenticado e a conta é fechada
    try {
      await conta.deleteSession(sessionId: 'current');
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<List<File>> getUserFiles(String bucketId) async {
    //cria uma lista com todos os arquivos do usuario logado que estão no servidor
    // para mostrar na tela
    final result = await storage.listFiles(bucketId: bucketId);
    return result.files;

  }

  Future<void> downloadArquivo(String bucketId, String fileId) async {
    //usa a função getFile para pegar o nome do arquivo
    // então baixa o arquivo na pasta de download
    final exameInfo = await storage.getFile(
      bucketId: bucketId,
      fileId: fileId,
    );
    final exame = await storage.getFileDownload(
      bucketId: bucketId,
      fileId: fileId,
    );
    final dart_io.Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      String filePath = '${downloadsDir.path}/${exameInfo.name}';
      final file = dart_io.File(filePath);

      file.writeAsBytesSync(exame);
      print('Arquivo baixado com sucesso em $filePath');// apenas para saber o caminho correto

    } else {
      print('Não foi possível acessar o diretório de downloads');
    }
  }

  Future<void> metadadoArquivo(String bucketId, String fileId) async {
    // salva todos os metadados de um arquivo num outro arquivo e então faz o download
    final fileInfo = await storage.getFile(
      bucketId: bucketId,
      fileId: fileId,
    );
    String metadados = '''
    Nome do arquivo: ${fileInfo.name}
    ID do arquivo: ${fileInfo.$id}
    Tamanho do arquivo: ${fileInfo.sizeOriginal} bytes 
    Data de criação: ${fileInfo.$createdAt}
    ''';

    final dart_io.Directory? downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      String filePath = '${downloadsDir.path}/metadados_${fileInfo.name}.txt';
      final file = dart_io.File(filePath);

      await file.writeAsString(metadados);

      print('Metadados salvos com sucesso em $filePath');
    }
  }


}