import 'package:flutter/material.dart';
import 'package:projeto/paginas/pagina_downloads.dart';
import 'package:provider/provider.dart';
import 'package:projeto/Appwrite/auth_api.dart';
import 'package:projeto/paginas/pagina_login.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => authAPI(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final value = context.watch<authAPI>().status;

    return MaterialApp(
      title: 'App de download',
      debugShowCheckedModeBanner: false,
      home: value == AuthStatus.uninitialized
          ? const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      )
          : value == AuthStatus.authenticated
      // verifica o status do usuario, se o usuario nao se desconectou, ao entrar no aplicativo
      // ele ja estará conectado
          ? const pagina_download()
          : const pagina_login(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.indigo,
        ),
      ),
    );
  }
}

