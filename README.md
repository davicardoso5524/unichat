# UniChat

Aplicativo de mensagens acadêmico (alunos e professores), feito em **Flutter** com
**Supabase** como backend (autenticação, banco de dados, Realtime e Storage).

## Funcionalidades

- Cadastro e login de usuários (aluno ou professor)
- Seleção de curso no cadastro
- Lista de conversas
- Chat com mensagens em tempo real (Supabase Realtime)
- Envio de arquivos (imagens e PDF) via Supabase Storage
- Busca de contatos filtrada por curso para alunos
- Destaque visual para mensagens enviadas por professores
- Perfil do usuário com edição de nome
- Tema claro/escuro

## Arquitetura (MVC)

O projeto segue o padrão **MVC**, organizado por camadas dentro de `frontend/lib/`:

```
lib/
├── config/        # configurações (Supabase, constantes)
├── models/        # modelos de dados (Model)
├── views/         # telas da interface (View)
├── controllers/   # lógica e estado da aplicação (Controller)
├── widgets/       # componentes de interface reutilizáveis
├── theme/         # cores, estilos de texto e botões
├── routes/        # rotas de navegação (go_router)
└── main.dart      # ponto de entrada
```

- **Model:** classes que representam os dados (`ProfileModel`, `ChatModel`, `MessageModel`).
- **View:** telas que o usuário vê (`LoginView`, `HomeView`, `ChatView`, ...).
- **Controller:** classes `ChangeNotifier` que fazem a ponte entre as views e o
  Supabase, guardando o estado e notificando a interface (`AuthController`,
  `HomeController`, `ChatController`, ...).

## Tecnologias

- Flutter / Dart
- Supabase (Auth, Postgres, Realtime, Storage)
- provider (gerência de estado)
- go_router (navegação)

## Configuração do Supabase

Os scripts de criação do banco estão na pasta `supabase/`. No painel do Supabase,
abra o **SQL Editor** e execute as migrações da pasta `supabase/migrations/` na ordem.

Depois, preencha as credenciais em `frontend/lib/config/supabase_config.dart`:

```dart
static const String url = 'https://SEU-PROJETO.supabase.co';
static const String anonKey = 'SUA_CHAVE_PUBLISHABLE';
```

## Como rodar

```bash
cd frontend
flutter pub get
flutter run
```

Para testar no navegador: `flutter run -d chrome`.

> Observação: para rodar como app de Windows (desktop) é necessário ativar o
> Modo de Desenvolvedor do Windows. Para web e Android não é preciso.

## Autores

- Davi Santos Cardoso
- João Keweni Resende

## Professor

- Ericles
