# UniChat - Backend Supabase

## Estrutura

```
supabase/
├── migrations/
│   ├── 001_create_tables.sql    # Tabelas + triggers
│   ├── 002_rls_policies.sql     # Segurança (RLS)
│   └── 003_storage.sql          # Bucket de uploads
└── README.md                    # Este arquivo
```

## Setup do Supabase (passo a passo)

### 1. Criar projeto no Supabase

1. Acesse [supabase.com](https://supabase.com) e crie uma conta
2. Crie um novo projeto (anote a **senha do banco**)
3. Aguarde o projeto ser provisionado (~2 min)

### 2. Executar as migrations

No painel do Supabase:
1. Vá em **SQL Editor**
2. Execute os scripts **na ordem**:
   - `001_create_tables.sql`
   - `002_rls_policies.sql`
   - `003_storage.sql`

### 3. Habilitar Realtime

1. Vá em **Database** → **Replication**
2. Ative o Realtime para a tabela `messages`
3. (Opcional) Ative para `chat_participants` se quiser notificar quando alguém cria um chat

### 4. Obter credenciais para o Flutter

No painel do Supabase, vá em **Settings** → **API**:
- `Project URL` → ex: `https://xxxxx.supabase.co`
- `anon/public key` → chave pública para o Flutter

---

## Contrato de API (Backend ↔ Frontend)

O frontend Flutter vai interagir diretamente com o Supabase usando o SDK `supabase_flutter`. Abaixo está o contrato completo:

---

### AUTH (Autenticação)

| Operação | Método Supabase | Dados |
|----------|----------------|-------|
| Registro | `supabase.auth.signUp()` | `email`, `password`, `data: {name, role}` |
| Login | `supabase.auth.signInWithPassword()` | `email`, `password` |
| Logout | `supabase.auth.signOut()` | — |
| Usuário atual | `supabase.auth.currentUser` | — |
| Escutar mudança de auth | `supabase.auth.onAuthStateChange` | — |

**Nota:** Ao fazer signUp, o trigger `handle_new_user()` cria automaticamente o profile na tabela `profiles`.

---

### PROFILES

| Operação | Query Supabase |
|----------|---------------|
| Buscar meu profile | `supabase.from('profiles').select().eq('id', myId).single()` |
| Buscar profile por ID | `supabase.from('profiles').select().eq('id', userId).single()` |
| Buscar todos (para lista de contatos) | `supabase.from('profiles').select().neq('id', myId)` |
| Atualizar meu profile | `supabase.from('profiles').update({name: ...}).eq('id', myId)` |

**Formato do Profile:**
```json
{
  "id": "uuid",
  "name": "João Silva",
  "email": "joao@uni.edu",
  "role": "student",
  "avatar_url": null,
  "created_at": "2026-07-05T00:00:00Z",
  "updated_at": "2026-07-05T00:00:00Z"
}
```

---

### CHATS

| Operação | Query Supabase |
|----------|---------------|
| Listar meus chats | `supabase.from('chat_participants').select('chat_id, chats(*)').eq('user_id', myId)` |
| Criar chat | `supabase.from('chats').insert({}).select().single()` → depois inserir participantes |
| Verificar chat existente | `supabase.rpc('get_existing_chat', {user1: myId, user2: otherId})` |

**Criar chat completo (2 steps):**
```dart
// 1. Criar chat
final chat = await supabase.from('chats').insert({}).select().single();

// 2. Adicionar participantes
await supabase.from('chat_participants').insert([
  {'chat_id': chat['id'], 'user_id': myId},
  {'chat_id': chat['id'], 'user_id': otherUserId},
]);
```

**Listar chats com info do outro participante:**
```dart
final myChats = await supabase
  .from('chat_participants')
  .select('chat_id, chats(id, created_at)')
  .eq('user_id', myId);
```

---

### MESSAGES

| Operação | Query Supabase |
|----------|---------------|
| Listar mensagens de um chat | `supabase.from('messages').select('*, profiles(name)').eq('chat_id', chatId).order('created_at')` |
| Enviar mensagem de texto | `supabase.from('messages').insert({chat_id, sender_id, content})` |
| Enviar arquivo | Upload no Storage → inserir mensagem com `file_url` |
| Escutar em tempo real | `supabase.from('messages').stream(primaryKey: ['id']).eq('chat_id', chatId)` |

**Formato da Message:**
```json
{
  "id": 1,
  "chat_id": 1,
  "sender_id": "uuid",
  "content": "Olá!",
  "file_url": null,
  "created_at": "2026-07-05T00:00:00Z",
  "profiles": {
    "name": "João Silva"
  }
}
```

---

### STORAGE (Upload de arquivos)

| Operação | Método Supabase |
|----------|----------------|
| Upload | `supabase.storage.from('chat-uploads').upload(path, file)` |
| Obter URL pública | `supabase.storage.from('chat-uploads').getPublicUrl(path)` |

**Padrão de path:** `{user_id}/{uuid}.{extensão}`

```dart
final path = '${myId}/${uuid.v4()}.png';
await supabase.storage.from('chat-uploads').upload(path, file);
final url = supabase.storage.from('chat-uploads').getPublicUrl(path);
// Depois insere mensagem com file_url = url
```

**Tipos aceitos:** PDF, PNG, JPG, JPEG

---

### REALTIME (Mensagens em tempo real)

```dart
// Stream de mensagens de um chat específico
supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('chat_id', chatId)
  .order('created_at')
  .listen((messages) {
    // messages = List<Map<String, dynamic>>
    // Atualiza a UI automaticamente
  });
```

---

## Dependências Flutter necessárias

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  uuid: ^4.0.0
```

## Inicialização no Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://SEU_PROJECT_ID.supabase.co',
    anonKey: 'SUA_ANON_KEY',
  );
  
  runApp(MyApp());
}

// Atalho global
final supabase = Supabase.instance.client;
```
