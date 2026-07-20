# UniChat - Apresentação do Projeto Final

## 1. Objetivo do projeto

O UniChat é um aplicativo Flutter de mensagens voltado para o ambiente
universitário. A proposta é aproximar alunos e professores em um espaço
organizado, com cadastro por tipo de usuário, seleção de curso, conversas,
grupos e destaque visual para mensagens enviadas por professores.

O projeto foi desenvolvido para atender aos principais pontos do trabalho final
da disciplina Tópicos Especiais de Programação: interface, navegação,
gerenciamento de estado, persistência de dados, arquitetura em camadas e
apresentação funcional.

## 2. Requisitos técnicos atendidos

### Interface com múltiplas telas e navegação

O app possui várias telas, organizadas com rotas usando `go_router`:

- Login
- Cadastro
- Home com lista de conversas
- Contatos
- Chat
- Perfil
- Edição de perfil
- Notificações
- Criação de grupo
- Detalhes do grupo

Além das rotas, o app usa uma navegação principal com abas para separar as áreas
mais importantes da aplicação.

### Gerenciamento de estado com Provider

O gerenciamento de estado foi feito com `Provider` e `ChangeNotifier`.

Os controllers notificam as telas quando alguma informação muda, por exemplo:

- usuário autenticado;
- perfil carregado;
- conversas atualizadas;
- resultados de busca;
- mensagens recebidas;
- envio de arquivo em andamento;
- tema claro ou escuro.

Principais controllers:

- `AuthController`
- `HomeController`
- `ChatController`
- `ProfileController`
- `GroupController`
- `ThemeController`

### Persistência de dados

A persistência é externa, usando Supabase.

O Supabase foi usado para:

- autenticação com e-mail e senha;
- banco de dados Postgres;
- armazenamento dos perfis;
- armazenamento de chats e mensagens;
- upload de arquivos no Storage;
- mensagens em tempo real com Realtime;
- regras de segurança com Row Level Security.

### Arquitetura definida

O projeto usa uma organização próxima de MVC, separando responsabilidades:

- `models`: classes que representam os dados do sistema;
- `views`: telas e interface do usuário;
- `controllers`: regras de negócio, estado e comunicação com o Supabase;
- `widgets`: componentes reutilizáveis;
- `routes`: configuração de navegação;
- `theme`: cores, textos e estilos;
- `config`: constantes e configuração do app.

Essa separação facilita manutenção, explicação do código e divisão das partes do
projeto.

### Injeção de dependências

O projeto usa `Provider` para disponibilizar os controllers para a árvore de
widgets. Assim, as telas acessam os controllers com `context.read` e
`context.watch`, evitando criar manualmente esses objetos em cada tela.

Exemplo prático:

- a tela de login usa `AuthController`;
- a home usa `HomeController`;
- o chat usa `ChatController`;
- o perfil usa `AuthController` e `ThemeController`.

### API REST externa

O enunciado apresenta API REST externa como diferencial. Neste projeto, o app não
usa uma API REST externa tradicional. A comunicação principal é feita pelo SDK do
Supabase, que fornece autenticação, banco, storage e realtime.

Esse ponto pode ser citado como uma decisão de projeto: o Supabase substitui a
necessidade de criar ou consumir uma API REST separada para as funções principais
do UniChat.

## 3. Funcionalidades principais do app

- Cadastro e login de usuários.
- Escolha entre aluno e professor.
- Escolha obrigatória do curso no cadastro.
- Aluno visualiza apenas contatos do mesmo curso.
- Professor recebe destaque visual nas mensagens.
- Lista de conversas.
- Chat em tempo real.
- Envio de imagens e PDFs.
- Criação de grupos.
- Detalhes de grupo e gerenciamento de membros.
- Mensagens fixadas em grupos.
- Perfil do usuário.
- Tema claro e escuro.

## 4. Cursos disponíveis

No cadastro, o aluno seleciona um dos cursos:

- Sistemas de Informação
- Química
- Física
- Letras
- Pedagogia
- Ciências Biológicas
- Administração
- Ciências Contábeis

Essa escolha é usada para filtrar os contatos: um aluno só visualiza pessoas do
mesmo curso. Essa regra também existe no Supabase, para não depender apenas da
interface.

## 5. Modelagem de dados

A modelagem principal do projeto gira em torno das seguintes tabelas:

- `profiles`: dados do usuário, como nome, e-mail, tipo de usuário e curso;
- `chats`: conversas individuais e grupos;
- `chat_participants`: participantes de cada conversa;
- `messages`: mensagens enviadas;
- `message_read_receipts`: controle de leitura;
- `pinned_messages`: mensagens fixadas;
- `user_preferences`: preferências do usuário.

Relações principais:

- um usuário tem um perfil;
- um chat pode ter vários participantes;
- uma mensagem pertence a um chat;
- uma mensagem pertence a um remetente;
- uma mensagem pode ser fixada em um grupo;
- uma mensagem pode ter registros de leitura.

Para a entrega, a modelagem pode ser apresentada como diagrama simples com essas
tabelas e relacionamentos.

## 6. Artefatos exigidos no enunciado

O enunciado cobra 3 pontos em artefatos:

- Wireframes de baixa fidelidade - 1,0 ponto
- Design de alta fidelidade/protótipo - 1,0 ponto
- Modelagem de dados - 1,0 ponto

### Onde colocar no GitHub

Sugestão de organização para adicionar depois:

```text
docs/
├── wireframes/
│   └── arquivos dos wireframes de baixa fidelidade
├── prototipo/
│   └── link ou imagens do protótipo de alta fidelidade
└── modelagem/
    └── diagrama ou documento da modelagem de dados
```

Quando esses arquivos forem adicionados, o README ou este documento pode apontar
para eles.

## 7. Execução do projeto - pontos do barema

O vídeo vale 4 pontos na parte de execução. Para cobrir o barema, a apresentação
deve mostrar:

### UI, navegação e funcionamento geral - 1,0 ponto

Mostrar o app abrindo, navegando entre login, cadastro, home, contatos, chat e
perfil. Demonstrar que as telas estão conectadas e que o fluxo principal
funciona.

### Gerenciamento de estado com Provider - 0,75 ponto

Explicar que o app usa `Provider` e `ChangeNotifier`. Mostrar um exemplo simples:
quando o usuário faz login, quando chegam mensagens ou quando o tema muda, a
interface é atualizada a partir dos controllers.

### Persistência de dados - 0,75 ponto

Explicar que os dados ficam salvos no Supabase. Mostrar que usuários, perfis,
conversas e mensagens não são dados fixos no app, mas vêm do banco.

### Arquitetura + injeção de dependências - 1,0 ponto

Mostrar a pasta `frontend/lib` e explicar a separação em `models`, `views`,
`controllers`, `widgets`, `routes`, `theme` e `config`.

Também comentar que os controllers são disponibilizados para as telas com
`Provider`.

### Qualidade de código e versionamento - 0,5 ponto

Mostrar o repositório no GitHub, commits, organização das pastas e testes
automatizados. Comentar que foram feitos `flutter analyze`, `flutter test` e
build web para validar o projeto.

## 8. Vídeo de apresentação

O enunciado pede vídeo no YouTube com duração máxima de 15 minutos.

Sugestão de divisão do vídeo:

1. Apresentar a ideia do UniChat.
2. Mostrar login e cadastro.
3. Explicar escolha de curso e tipo de usuário.
4. Demonstrar contatos filtrados por curso.
5. Abrir chat e enviar mensagem.
6. Mostrar destaque de professor.
7. Mostrar grupos e mensagens fixadas.
8. Explicar Provider e controllers.
9. Explicar persistência no Supabase.
10. Explicar arquitetura de pastas.
11. Mostrar o GitHub e os artefatos.

Se o grupo tiver mais de um membro, cada pessoa deve explicar pelo menos uma
tecnologia ou conceito aplicado no projeto. O professor deixou claro que não
vale cada membro apenas se apresentar; todos precisam demonstrar domínio de uma
parte real do sistema.

## 9. Apresentação presencial

A apresentação presencial vale 3 pontos:

- Demonstração funcional - 1,0 ponto
- Domínio técnico e defesa - 1,0 ponto
- Clareza e organização - 0,5 ponto
- Gestão do tempo e participação - 0,5 ponto

### Roteiro recomendado para a apresentação em sala

1. Explicar rapidamente o problema: comunicação acadêmica entre alunos e
   professores.
2. Mostrar o app funcionando.
3. Demonstrar cadastro com curso.
4. Demonstrar contatos filtrados.
5. Demonstrar chat.
6. Demonstrar destaque de professor.
7. Mostrar a organização do código Flutter.
8. Explicar Provider e Supabase.
9. Mostrar os artefatos do GitHub.
10. Encerrar explicando limitações e possíveis melhorias.

## 10. Demonstração sugerida

Antes da apresentação, deixar usuários de teste prontos:

- um aluno de Sistemas de Informação;
- um aluno de outro curso;
- um professor.

Fluxo de demo:

1. Entrar com um aluno.
2. Abrir contatos e mostrar que só aparecem pessoas do mesmo curso.
3. Abrir uma conversa.
4. Enviar uma mensagem.
5. Entrar ou mostrar uma conversa com professor.
6. Mostrar que a mensagem do professor aparece com selo `Prof.`.
7. Criar ou abrir um grupo.
8. Mostrar detalhes do grupo.
9. Mostrar perfil e tema claro/escuro.

## 11. Limitações atuais

- As notificações ainda são uma tela de preferências, mas não enviam push
  notification real.
- O tema escuro ainda pode evoluir para persistência completa por usuário.
- O filtro por curso é a base para funcionalidades futuras, como conhecer
  pessoas de outros cursos ou comunidades da universidade.
- Os wireframes e protótipos devem ser adicionados na pasta de artefatos antes
  da entrega final.

## 12. Checklist final antes de enviar

- Código-fonte no GitHub.
- Wireframes de baixa fidelidade adicionados.
- Protótipo de alta fidelidade adicionado ou linkado.
- Modelagem de dados adicionada.
- Vídeo publicado no YouTube.
- Link do GitHub enviado.
- Link do YouTube enviado.
- App testado antes da apresentação.
- Usuários de demonstração preparados.

## 13. Resumo final

O UniChat atende ao objetivo de ser um aplicativo Flutter completo, com múltiplas
telas, navegação, Provider, persistência externa com Supabase, arquitetura em
camadas e funcionalidades demonstráveis. Para ficar totalmente alinhado ao
enunciado, a entrega final precisa incluir também os artefatos visuais e a
modelagem de dados no repositório.
