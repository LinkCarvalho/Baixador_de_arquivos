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

  }

  loadUser() async {
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

  signOut() async {
    try {
      await conta.deleteSession(sessionId: 'current');
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<List<File>> getUserFiles(String bucketId) async {
    try {
      final result = await storage.listFiles(bucketId: bucketId);
      return result.files;
    } catch (e) {
      print('Erro ao buscar arquivos: $e');
      return [];
    }
  }

  Future<void> download(String bucketId, String fileId) async {
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
        print('Arquivo baixado com sucesso em $filePath');

      } else {
        print('Não foi possível acessar o diretório de downloads');
      }
  }

  Future<void> metadados(String bucketId, String fileId) async {
      final fileInfo = await storage.getFile(
        bucketId: bucketId,
        fileId: fileId,
      );
      String metadados = '''
    Nome do arquivo: ${fileInfo.name}
    ID do arquivo: ${fileInfo.$id}
    Tamanho do arquivo: ${fileInfo.sizeOriginal} bytes
    Tipo MIME: ${fileInfo.mimeType}
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