# Baixador_de_arquivos

 Sistema para baixar arquivos PDF usando Flutter e Appwrite com login de usuário para dispositivos android

 ## Bibliotecas
 
 Dependências do arquivo pubspec.yaml para conhecer as bibliotecas

 * [Appwrite](https://pub.dev/packages/appwrite)
 * [Path provider](https://pub.dev/packages/path_provider)

## Como executar
 
* Instalar o [flutter SDK](https://docs.flutter.dev/)  
* Instalar uma Ferramenta de desenvolvimento (Visual Studio ou Android Studio)  
* Criar um servidor usando [Appwrite](https://appwrite.io/docs/advanced/self-hosting) e [Docker](https://www.docker.com/)  
* Criar um [projeto](https://appwrite.io/docs/quick-starts/flutter) dentro do Appwrite e criar os usuários e arquivos, dando as permissões de leitura de um arquivo para no máximo um usuário  
* Definir os IDs do projeto, da Url do servidor(no caso de self hosting será o IP), do banco de dados e do Bucket com os arquivos no arquivo constantes.dart
* Alterar o AndroidManifest.xml como mostrado no site do Appwrite para usar o ID do seu projeto
* Para self hosting e for usado um dispositvo android fisico, tanto o aparelho quanto o servidor precisam estar na mesma rede

