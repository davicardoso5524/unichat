# Modelagem do Banco de Dados — UniChat

## Visão geral

O UniChat utiliza o Supabase, que trabalha com PostgreSQL, para armazenar os dados do aplicativo. A modelagem organiza as informações de usuários, conversas, grupos, mensagens, leituras e preferências.

O modelo foi criado para permitir conversas diretas entre duas pessoas e conversas em grupo, mantendo os dados organizados e relacionados por chaves primárias e estrangeiras.

## Diagrama do banco

![Diagrama de modelagem do banco de dados do UniChat](modelagem.jfif)

## Tabelas principais

| Tabela | Função |
|---|---|
| `profiles` | Guarda os dados do usuário, como nome, e-mail, tipo de conta (aluno ou professor), curso e foto de perfil. |
| `user_preferences` | Armazena as preferências do usuário, como tema escuro e notificações. |
| `chats` | Representa cada conversa. Pode ser uma conversa direta ou um grupo. |
| `chat_participants` | Liga usuários aos chats dos quais participam. Também identifica o dono de um grupo. |
| `messages` | Guarda as mensagens enviadas em cada chat, incluindo texto, arquivo, remetente, data e status. |
| `message_read_receipts` | Registra quais usuários leram cada mensagem. |
| `pinned_messages` | Guarda as mensagens fixadas nos grupos e a data em que deixam de ficar fixadas. |

## Relacionamentos

- Cada usuário autenticado possui um perfil em `profiles` e pode ter uma configuração em `user_preferences`.
- Um usuário pode participar de vários chats e um chat pode ter vários usuários. Essa relação é feita pela tabela `chat_participants`.
- Um chat pode ter várias mensagens, mas cada mensagem pertence a apenas um chat.
- Cada mensagem possui um remetente, que é um usuário do sistema.
- Uma mensagem pode ser marcada como lida por vários participantes do chat.
- Em grupos, uma mensagem pode ser fixada por um período de tempo.

## Regras importantes

- Alunos podem conversar com usuários do mesmo curso. Professores podem visualizar usuários de todos os cursos.
- Apenas participantes podem acessar as mensagens de um chat.
- Em grupos, somente o dono pode editar informações, adicionar ou remover participantes e fixar mensagens.
- Cada leitura de mensagem é registrada uma única vez para cada usuário.
- Os arquivos enviados nas mensagens ficam no Supabase Storage; o banco salva apenas o link do arquivo.

## Observação técnica

O Supabase mantém a tabela de autenticação (`auth.users`). A tabela `profiles` complementa esses dados com as informações específicas do UniChat. As chaves estrangeiras garantem que os relacionamentos entre as tabelas sejam válidos e que os dados permaneçam organizados.
