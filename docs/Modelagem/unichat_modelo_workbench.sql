-- Modelo lógico UniChat para visualização no MySQL Workbench.
-- Uso acadêmico/diagramas: não é o script de implantação do Supabase.

CREATE SCHEMA IF NOT EXISTS unichat_model
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE unichat_model;

CREATE TABLE auth_users (
  id CHAR(36) NOT NULL,
  email VARCHAR(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB COMMENT='Representação externa de auth.users (Supabase)';

CREATE TABLE profiles (
  id CHAR(36) NOT NULL,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(255) NOT NULL,
  role ENUM('student', 'professor') NOT NULL DEFAULT 'student',
  course VARCHAR(80) NOT NULL DEFAULT 'Sistemas de Informação',
  avatar_url TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_profiles_email (email),
  KEY idx_profiles_course (course),
  CONSTRAINT fk_profiles_auth_users FOREIGN KEY (id) REFERENCES auth_users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE user_preferences (
  user_id CHAR(36) NOT NULL,
  dark_mode BOOLEAN NOT NULL DEFAULT FALSE,
  push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  sound_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  vibration BOOLEAN NOT NULL DEFAULT TRUE,
  new_contact_notifications BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  CONSTRAINT fk_preferences_profile FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE chats (
  id INT NOT NULL AUTO_INCREMENT,
  is_group BOOLEAN NOT NULL DEFAULT FALSE,
  group_name TEXT NULL,
  group_image_url TEXT NULL,
  owner_id CHAR(36) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_chats_is_group (is_group),
  KEY idx_chats_owner (owner_id),
  CONSTRAINT fk_chats_owner FOREIGN KEY (owner_id) REFERENCES auth_users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE chat_participants (
  chat_id INT NOT NULL,
  user_id CHAR(36) NOT NULL,
  role ENUM('member', 'owner') NOT NULL DEFAULT 'member',
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chat_id, user_id),
  KEY idx_chat_participants_user (user_id),
  CONSTRAINT fk_participants_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_participants_profile FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE messages (
  id INT NOT NULL AUTO_INCREMENT,
  chat_id INT NOT NULL,
  sender_id CHAR(36) NOT NULL,
  content TEXT NULL,
  file_url TEXT NULL,
  status ENUM('sent', 'delivered', 'read') NOT NULL DEFAULT 'sent',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_messages_chat_created (chat_id, created_at),
  KEY idx_messages_sender (sender_id),
  KEY idx_messages_status (status),
  CONSTRAINT fk_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE message_read_receipts (
  message_id INT NOT NULL,
  user_id CHAR(36) NOT NULL,
  read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id, user_id),
  KEY idx_read_receipts_user (user_id),
  CONSTRAINT fk_receipts_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
  CONSTRAINT fk_receipts_user FOREIGN KEY (user_id) REFERENCES auth_users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pinned_messages (
  id INT NOT NULL AUTO_INCREMENT,
  chat_id INT NOT NULL,
  message_id INT NOT NULL,
  pinned_by CHAR(36) NOT NULL,
  pinned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pinned_chat_message (chat_id, message_id),
  KEY idx_pinned_messages_chat (chat_id),
  KEY idx_pinned_messages_expires (expires_at),
  KEY idx_pinned_messages_user (pinned_by),
  CONSTRAINT fk_pinned_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_pinned_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
  CONSTRAINT fk_pinned_user FOREIGN KEY (pinned_by) REFERENCES auth_users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;
