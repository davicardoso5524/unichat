# UniChat - Roteiro de Apresentação

## Ideia do projeto

O UniChat é um aplicativo de mensagens para ambiente universitário. A proposta é
aproximar alunos e professores em um espaço mais organizado que um chat comum:
o usuário se cadastra como aluno ou professor, informa seu curso e conversa com
pessoas ligadas ao seu contexto acadêmico.

Nesta versão, o aluno vê apenas contatos do mesmo curso. Isso prepara o app para
uma evolução futura: permitir conhecer pessoas da universidade de forma mais
controlada, por curso, turma ou comunidade.

## Principais funcionalidades

- Cadastro e login com e-mail e senha.
- Escolha entre aluno e professor no cadastro.
- Escolha obrigatória do curso no cadastro.
- Lista de conversas.
- Busca de contatos filtrada por curso para alunos.
- Chat em tempo real com mensagens de texto.
- Envio de arquivos como imagens e PDF.
- Grupos com membros, detalhes e mensagens fixadas.
- Perfil do usuário com nome, e-mail, curso e tipo de usuário.
- Tema claro e escuro.
- Destaque visual para mensagens enviadas por professores.

## Cursos disponíveis

- Sistemas de Informação
- Química
- Física
- Letras
- Pedagogia
- Ciências Biológicas
- Administração
- Ciências Contábeis

## Destaque do professor

O projeto separa alunos e professores pelo campo `role` do perfil. Quando uma
mensagem vem de um professor, a interface mostra uma borda de destaque e o selo
`Prof.` na bolha da mensagem.

Essa decisão é importante porque o professor ganha identificação imediata dentro
da conversa, sem mudar o funcionamento básico do chat. A mensagem continua sendo
uma mensagem normal, mas visualmente fica claro que ela tem origem em um
professor.

## Como o Flutter foi usado

O aplicativo foi desenvolvido em Flutter, usando a estrutura de widgets do
framework para montar as telas. Cada tela é composta por widgets menores e
reutilizáveis, como botões, campos de texto, avatar, cards de conversa, bolhas de
mensagem e selo de professor.

O estado da aplicação é controlado com `provider` e `ChangeNotifier`. Isso
permite que as telas reajam automaticamente quando uma informação muda, por
exemplo:

- quando o usuário faz login;
- quando o perfil é carregado;
- quando chegam novas mensagens;
- quando a lista de contatos muda;
- quando um arquivo está sendo enviado.

As rotas são organizadas com `go_router`, separando telas como login, cadastro,
home, contatos, chat, perfil e detalhes de grupo.

## Organização do código Flutter

O projeto segue uma divisão próxima de MVC:

- `models`: representam os dados principais, como perfil, chat e mensagem.
- `views`: telas que o usuário enxerga e interage.
- `controllers`: concentram regras, estados e comunicação com o Supabase.
- `widgets`: componentes visuais reaproveitados em várias telas.
- `routes`: configuração da navegação.
- `theme`: cores, textos e aparência geral do app.
- `config`: constantes e configuração do Supabase.

Essa separação facilita a explicação do projeto, porque cada parte tem uma
responsabilidade clara.

## Fluxo de cadastro

No cadastro, o usuário informa:

- nome;
- e-mail institucional;
- senha;
- curso;
- tipo de usuário: aluno ou professor.

Esses dados são enviados para o Supabase Auth. Depois, uma trigger no banco cria
automaticamente o registro correspondente na tabela `profiles`, guardando nome,
e-mail, tipo de usuário e curso.

## Fluxo de contatos por curso

Quando um aluno abre a tela de contatos, o app busca o perfil dele, identifica o
curso escolhido e lista apenas pessoas do mesmo curso. A mesma regra também foi
reforçada no Supabase com Row Level Security, para que o filtro não dependa só da
interface.

Para professores, a regra é mais aberta: eles conseguem visualizar os perfis,
pois no contexto acadêmico o professor pode precisar conversar com alunos.

## Chat e mensagens

As mensagens ficam na tabela `messages`. Cada mensagem guarda:

- chat ao qual pertence;
- usuário que enviou;
- texto ou arquivo;
- data de criação;
- status da mensagem.

No Flutter, a tela de chat usa um controller para carregar as mensagens e
escutar atualizações em tempo real. Quando uma nova mensagem chega, a lista é
atualizada e a interface redesenha as bolhas.

## Supabase no projeto

O Supabase foi usado como backend principal:

- Auth: cadastro, login e logout.
- Postgres: tabelas de perfis, chats, participantes e mensagens.
- Realtime: atualização das mensagens.
- Storage: envio e acesso a arquivos.
- RLS: regras de segurança para cada usuário acessar apenas o que deve.
- RPCs: funções no banco para criar chat, criar grupo, fixar mensagens e marcar
  mensagens como lidas.

O ponto mais importante para apresentar é que o Flutter não usa um backend
separado em API REST. Ele conversa diretamente com o Supabase pelo SDK
`supabase_flutter`.

## Demonstração sugerida

1. Abrir o app e mostrar login/cadastro.
2. Cadastrar ou mostrar um aluno com curso selecionado.
3. Abrir contatos e explicar que aparecem usuários do mesmo curso.
4. Entrar em uma conversa.
5. Enviar uma mensagem.
6. Mostrar uma mensagem de professor com o selo `Prof.`.
7. Mostrar o perfil com nome, e-mail, curso e tipo de usuário.
8. Se houver tempo, mostrar grupos, envio de arquivo e tema escuro.

## Pontos técnicos para comentar

- Flutter permite criar a mesma interface para web, desktop e mobile.
- `Provider` foi usado para gerenciar estado de forma simples.
- `ChangeNotifier` avisa a interface quando os dados mudam.
- `go_router` organiza a navegação por rotas.
- Os modelos deixam os dados mais organizados antes de exibir na tela.
- O Supabase reduz a necessidade de criar um backend manual do zero.
- As policies de RLS ajudam a manter a regra de acesso também no banco.

## Limitações atuais

- O tema escuro ainda é mantido em memória e pode ser melhorado com persistência.
- As notificações estão como tela de preferências, mas ainda não enviam push
  notification real.
- O filtro por curso é a base para funcionalidades futuras de conhecer outros
  alunos da universidade.
- Para apresentação, é importante ter usuários de teste já criados em cursos
  diferentes para demonstrar o filtro.

## Resumo final

O UniChat é um aplicativo Flutter de mensagens para universidade, integrado com
Supabase. O foco principal está em autenticação, organização da interface,
gerenciamento de estado, navegação, chat em tempo real e regras acadêmicas como
curso do aluno e destaque para professores.
