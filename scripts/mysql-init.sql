CREATE DATABASE IF NOT EXISTS infra_db;

USE infra_db;

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO usuarios (nome, email) VALUES
('Carlos Henrique', 'carlos@example.com'),
('Ana Souza', 'ana@example.com'),
('Marcos Lima', 'marcos@example.com');