CREATE DATABASE  INOVATECH; -- CRIA O BANCO-- 

USE INOVATECH; -- BANCO UTILIZADO --

-- CRIAÇÃO TABELA CADASTRO --
CREATE TABLE IF NOT EXISTS cadastro (
	id INT AUTO_INCREMENT PRIMARY KEY,
    nome_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL 
); 
ALTER TABLE cadastro ADD COLUMN senha VARCHAR(25) NOT NULL; 
ALTER TABLE cadastro MODIFY COLUMN email VARCHAR(100) NOT NULL UNIQUE;

-- CRIAÇÃO TABELA ESCOLARIDADE --
CREATE TABLE IF NOT EXISTS escolaridade (
	id INT AUTO_INCREMENT PRIMARY KEY,
    grau VARCHAR(50) NOT NULL
); 
-- CRIAÇÃO TABELA CIDADE --
CREATE TABLE IF NOT EXISTS cidade (
	id INT AUTO_INCREMENT PRIMARY KEY,
    nome_cidade VARCHAR(60) NOT NULL,
    uf VARCHAR(2) NOT NULL
); 
-- CRIAÇÃO TABELA TRILHAS --
CREATE TABLE IF NOT EXISTS trilhas (
	id INT AUTO_INCREMENT PRIMARY KEY,
    nome_trilha VARCHAR(50) NOT NULL,
    descricao TEXT(200) NOT NULL,
    ativa BOOLEAN NOT NULL
); 
-- CRIAÇÃO TABELA INSCRIÇÕES --
CREATE TABLE IF NOT EXISTS inscricoes (
	id INT AUTO_INCREMENT PRIMARY KEY,
    cpf VARCHAR(14) NOT NULL,
    data_nasc DATE NOT NULL,
    genero VARCHAR(20) NOT NULL,
    celular VARCHAR(15) NOT NULL, 
    cadastro_id INT, 
    trilhas_id INT,
    escolaridade_id INT, 
    cidade_id INT, 
    FOREIGN KEY (cadastro_id) REFERENCES cadastro(id),
    FOREIGN KEY (trilhas_id) REFERENCES trilhas(id), 
    FOREIGN KEY (escolaridade_id) REFERENCES escolaridade(id), 
    FOREIGN KEY (cidade_id) REFERENCES cidade(id)
);

-- alteração tabela inscircoes --
ALTER TABLE inscricoes
ADD COLUMN nota INT DEFAULT 0, -- Nota do aluno
ADD COLUMN status VARCHAR(20) DEFAULT 'ativa'; -- Status da inscrição

-- CRIAÇÃO TABELA APROVADOS --
CREATE TABLE IF NOT EXISTS aprovados (
	id INT AUTO_INCREMENT PRIMARY KEY,
    nota INT NOT NULL,
    status_usuario VARCHAR(15) NOT NULL,
    trilhas_id INT,
    FOREIGN KEY (trilhas_id) REFERENCES trilhas(id)
);

-- alteração tabela aprovados --
ALTER TABLE aprovados
ADD inscricoes_id INT;

ALTER TABLE aprovados
ADD CONSTRAINT fk_inscricoes_aprovados
FOREIGN KEY (inscricoes_id) REFERENCES inscricoes(id);

-- remoção tabelas aprovados --
DROP TABLE IF EXISTS aprovados;

-- criando nova tabela aprovados --
CREATE TABLE IF NOT EXISTS aprovados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cadastro_id INT NOT NULL,
    trilhas_id INT NOT NULL,
    status_aprovacao VARCHAR(20) NOT NULL, -- 'aprovado' ou 'não aprovado'
    FOREIGN KEY (cadastro_id) REFERENCES cadastro(id),
    FOREIGN KEY (trilhas_id) REFERENCES trilhas(id)
);

-- Garantir integridade--
ALTER TABLE inscricoes
ADD CONSTRAINT chk_genero CHECK (genero IN ('Masculino', 'Feminino', 'Outro')),
ADD CONSTRAINT chk_cpf CHECK (LENGTH(cpf) = 14),
ADD CONSTRAINT chk_celular CHECK (LENGTH(celular) <= 15);

-- atualização do check
ALTER TABLE inscricoes DROP CONSTRAINT chk_genero;

ALTER TABLE inscricoes
ADD CONSTRAINT chk_genero CHECK (genero IN ('Masculino', 'Feminino', 'Nao-informar'));

-- Adicionar validações para trilhas ativas --
ALTER TABLE trilhas ADD CONSTRAINT chk_ativa CHECK (ativa IN (0, 1));


-- Prevenir Inscrição em Trilhas Desativadas --
DELIMITER //
CREATE TRIGGER trg_prevent_inactive_trilhas
BEFORE INSERT ON inscricoes
FOR EACH ROW
BEGIN
  DECLARE trilha_ativa BOOLEAN;
  SELECT ativa INTO trilha_ativa FROM trilhas WHERE id = NEW.trilhas_id;
  IF NOT trilha_ativa THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Inscrição não permitida em trilhas desativadas.';
  END IF;
END;
//
DELIMITER ;


-- Registrar Nova Inscrição --
DELIMITER //
CREATE PROCEDURE sp_registrar_inscricao (
  IN p_cadastro_id INT,
  IN p_trilhas_id INT,
  IN p_escolaridade_id INT,
  IN p_cidade_id INT,
  IN p_cpf VARCHAR(14),
  IN p_data_nasc DATE,
  IN p_genero VARCHAR(20),
  IN p_celular VARCHAR(15)
)
BEGIN
  INSERT INTO inscricoes (cadastro_id, trilhas_id, escolaridade_id, cidade_id, cpf, data_nasc, genero, celular)
  VALUES (p_cadastro_id, p_trilhas_id, p_escolaridade_id, p_cidade_id, p_cpf, p_data_nasc, p_genero, p_celular);
END;
//
DELIMITER ;

-- Função para Contar Inscritos em Trilhas --
DELIMITER //
CREATE FUNCTION fn_contar_inscritos(p_trilha_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  RETURN (SELECT COUNT(*) FROM inscricoes WHERE trilhas_id = p_trilha_id);
END;
//
DELIMITER ;

-- Número de Inscritos por Trilha --
SELECT trilhas.nome_trilha, COUNT(inscricoes.id) AS inscritos
FROM trilhas
LEFT JOIN inscricoes ON trilhas.id = inscricoes.trilhas_id
GROUP BY trilhas.id;

-- Relatório de Inscrições por Cidade --
SELECT cidade.nome_cidade, COUNT(inscricoes.id) AS total_inscricoes
FROM cidade
LEFT JOIN inscricoes ON cidade.id = inscricoes.cidade_id
GROUP BY cidade.id;

ALTER TABLE cidade
CHANGE uf estado VARCHAR(2) NOT NULL;

DESCRIBE cidade;


select * from cadastro;

-- Dados para a tabela 'cadastro'
INSERT INTO cadastro (nome_completo, email, senha)
VALUES 
('Guilherme Cristian Silva Cutrim', 'cristian.silva@gmail.com', 'senha123'),
('Joanna Sharon', 'joanna.sharon@gmail.com', 'senha456'),
('Haiely Santos', 'hariely.santos@gmail.com', 'senha789');

-- Dados para a tabela 'escolaridade'
INSERT INTO escolaridade (grau)
VALUES 
('Ensino Médio'),
('Ensino Superior Incompleto'),
('Ensino Superior Completo');

-- Dados para a tabela 'cidade'
INSERT INTO cidade (nome_cidade, estado)
VALUES 
('São Luís', 'MA'),
('Imperatriz', 'MA'),
('Caxias', 'MA');

-- Dados para a tabela 'trilhas'
INSERT INTO trilhas (nome_trilha, descricao, ativa)
VALUES 
('Front-end', 'Desenvolvimento de interfaces web.', 1),
('Back-end', 'Desenvolvimento de sistemas e APIs.', 1),
('Ciência de Dados', 'Análise de dados e machine learning.', 0); -- Trilha desativada

-- Dados para a tabela 'inscricoes'
INSERT INTO inscricoes (cpf, data_nasc, genero, celular, cadastro_id, trilhas_id, escolaridade_id, cidade_id)
VALUES 
('123.456.789-00', '1990-01-15', 'Masculino', '98999999999', 1, 1, 2, 1),
('987.654.321-00', '1995-05-20', 'Feminino', '98988888888', 2, 2, 3, 2),
('456.123.789-00', '1988-12-10', 'Outro', '98977777777', 3, 1, 1, 3);


-- Criando tabela temporária
CREATE TEMPORARY TABLE temp_inscritos_por_trilha (
    trilha_id INT,
    nome_trilha VARCHAR(50),
    total_inscritos INT
);

-- Populando a tabela temporária
INSERT INTO temp_inscritos_por_trilha (trilha_id, nome_trilha, total_inscritos)
SELECT 
    t.id AS trilha_id,
    t.nome_trilha,
    COUNT(i.id) AS total_inscritos
FROM trilhas t
LEFT JOIN inscricoes i ON t.id = i.trilhas_id
GROUP BY t.id;

-- Consultando a tabela temporária
SELECT * FROM temp_inscritos_por_trilha;

-- É descartada automaticamente ao final da sessão.


-- Views --
-- Lista de Inscrições com Informações Completas --
CREATE VIEW vw_inscricoes_detalhadas AS
SELECT 
    i.id AS inscricao_id,
    c.nome_completo,
    c.email,
    t.nome_trilha,
    t.ativa AS trilha_ativa,
    e.grau AS escolaridade,
    ci.nome_cidade AS cidade,
    i.cpf,
    i.data_nasc,
    i.genero,
    i.celular
FROM inscricoes i
JOIN cadastro c ON i.cadastro_id = c.id
JOIN trilhas t ON i.trilhas_id = t.id
JOIN escolaridade e ON i.escolaridade_id = e.id
JOIN cidade ci ON i.cidade_id = ci.id;

-- Relatório de Inscrições por Trilha --
CREATE VIEW vw_relatorio_trilhas AS
SELECT 
    t.nome_trilha,
    COUNT(i.id) AS total_inscritos,
    SUM(CASE WHEN t.ativa = 1 THEN 1 ELSE 0 END) AS trilhas_ativas
FROM trilhas t
LEFT JOIN inscricoes i ON t.id = i.trilhas_id
GROUP BY t.id;

-- Inscritos por Cidade --
CREATE VIEW vw_inscritos_por_cidade AS
SELECT 
    ci.nome_cidade,
    COUNT(i.id) AS total_inscritos
FROM cidade ci
LEFT JOIN inscricoes i ON ci.id = i.cidade_id
GROUP BY ci.id;

-- Limita as incrções para não se escrever na mesma trilha duas vezes --
DELIMITER //
CREATE TRIGGER trg_prevent_duplicate_inscription
BEFORE INSERT ON inscricoes
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1
    FROM inscricoes
    WHERE cpf = NEW.cpf AND trilhas_id = NEW.trilhas_id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'A pessoa já está inscrita nesta trilha.';
  END IF;
END;
//
DELIMITER ; 

-- não permitir uma pessoa já escrita se escrever em outra trilha --
DELIMITER //

CREATE TRIGGER trg_prevent_multiple_trilhas
BEFORE INSERT ON inscricoes
FOR EACH ROW
BEGIN
    DECLARE existing_trilha INT;

    -- Verificar se o usuário já está inscrito em alguma trilha
    SELECT COUNT(*) INTO existing_trilha
    FROM inscricoes
    WHERE cadastro_id = NEW.cadastro_id;

    -- Se já houver uma inscrição, impedir a nova inserção
    IF existing_trilha > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O usuário já está inscrito em uma trilha. Não é permitido inscrever-se em outra.';
    END IF;
END;
//
DELIMITER ;


-- gatilho aprovação tabela aprovados -- 
DELIMITER //

CREATE TRIGGER trg_inscricoes_status
AFTER UPDATE ON inscricoes
FOR EACH ROW
BEGIN
    -- Inserir na tabela aprovados com base na nota
    IF NEW.nota < 30 THEN
        -- Inserir com status 'reprovado'
        INSERT INTO aprovados (cadastro_id, trilhas_id, status_aprovacao, status)
        VALUES (NEW.cadastro_id, NEW.trilhas_id, 'reprovado','encerrado');
    ELSE
        -- Inserir com status 'aprovado'
        INSERT INTO aprovados (cadastro_id, trilhas_id, status_aprovacao)
        VALUES (NEW.cadastro_id, NEW.trilhas_id, 'aprovado');
    END IF;
END;

//
DELIMITER ;

-- gatilho tabela isncricoes status --


-- dropando gatilho --
drop trigger trg_inscricoes_nota;

-- teste tabela aprovação --
UPDATE inscricoes
SET nota = 22 -- Para testar o status 'reprovado'
WHERE cadastro_id = 6;

-- drop tabela inscricoes colum status --
ALTER TABLE inscricoes
DROP COLUMN status;

-- adicionar colum status na tab aprovados 
ALTER TABLE aprovados
ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'ativa';

-- novo gatilho para insert e update --
DELIMITER //

CREATE TRIGGER trg_inscricoes_nota
AFTER INSERT ON inscricoes
FOR EACH ROW
BEGIN
    -- Verifica se a nota inserida é menor que 30
    IF NEW.nota < 30 THEN
        -- Inserir na tabela aprovados com status 'reprovado' e 'encerrado'
        INSERT INTO aprovados (cadastro_id, trilhas_id, status_aprovacao, status)
        VALUES (NEW.cadastro_id, NEW.trilhas_id, 'reprovado', 'encerrado');
    ELSE
        -- Inserir na tabela aprovados com status 'aprovado'
        INSERT INTO aprovados (cadastro_id, trilhas_id, status_aprovacao)
        VALUES (NEW.cadastro_id, NEW.trilhas_id, 'aprovado');
    END IF;
END;

//
DELIMITER ;

-- insert tabela cidades --
INSERT INTO cidade (nome_cidade, estado)
VALUES
('Timon', 'MA'),
('Codó', 'MA'),
('Paço do Lumiar', 'MA'),
('Açailândia', 'MA'),
('Bacabal', 'MA'),
('Santa Inês', 'MA'),
('Chapadinha', 'MA'),
('Balsas', 'MA'),
('Pinheiro', 'MA'),
('Itapecuru Mirim', 'MA'),
('Barra do Corda', 'MA'),
('Grajaú', 'MA'),
('Coroatá', 'MA'),
('Viana', 'MA'),
('Zé Doca', 'MA'),
('Estreito', 'MA'),
('Outras', 'MA');
-- drop procedimento --
drop procedure AtualizarNota;

-- Procedimento para Atualizar Nota --
DELIMITER //
CREATE PROCEDURE AtualizarNota(
    IN p_inscricoes_id INT,
    IN p_nota INT
)
BEGIN
    -- Atualiza a nota do aluno na tabela 'inscricoes'
    UPDATE inscricoes
    SET nota = p_nota
    WHERE id = p_inscricoes_id;
END;
//
DELIMITER ;

CALL AtualizarNota(18, 50); -- Atualiza a nota da inscrição com ID 1 para 50.

-- Função para Calcular a Média de Notas por Trilha --
DELIMITER //
CREATE FUNCTION MediaNotaTrilha(p_trilhas_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE media DECIMAL(5,2);

    SELECT AVG(nota) INTO media
    FROM inscricoes
    WHERE trilhas_id = p_trilhas_id;

    RETURN media;
END;
//
DELIMITER ;

SELECT MediaNotaTrilha(1); -- Retorna a média das notas para a trilha com ID 2.

-- Função para Verificar Aprovação
DELIMITER //
CREATE FUNCTION VerificarAprovacao(p_nota INT)
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    RETURN IF(p_nota >= 30, 'aprovado', 'não aprovado');
END;
//
DELIMITER ;

SELECT VerificarAprovacao(25); -- Retorna 'não aprovado'.
SELECT VerificarAprovacao(35); -- Retorna 'aprovado'.

-- Criar uma Tabela Temporária para Análise de Inscrições --
CREATE TEMPORARY TABLE TempInscricoes AS
SELECT
    cadastro_id,
    trilhas_id,
    nota
FROM inscricoes
WHERE nota >= 30;

SELECT * FROM TempInscricoes; -- Exibe as inscrições com nota >= 30.

-- View para Listar Alunos Aprovados --
CREATE OR REPLACE VIEW ViewAprovados AS
SELECT
    i.cadastro_id,
    i.trilhas_id,
    i.nota,
    'aprovado' AS status_aprovacao
FROM inscricoes i
WHERE i.nota >= 30;

SELECT * FROM ViewAprovados; -- Exibe os alunos aprovados.


-- gatilho para não aceitar menores de 16 anos --
DELIMITER //

CREATE TRIGGER verifica_idade_usuarios
BEFORE INSERT ON inscricoes
FOR EACH ROW
BEGIN
    DECLARE idade INT;
    SET idade = TIMESTAMPDIFF(YEAR, NEW.data_nasc, CURDATE());

    IF idade < 16 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Usuário deve ter pelo menos 16 anos.';
    END IF;
END //

DELIMITER ;


SELECT 
    aprovados.trilhas_id,
    aprovados.cadastro_id,
    aprovados.status_aprovacao
FROM 
    aprovados
WHERE 
    aprovados.status_aprovacao = 'aprovado';



SELECT 
    aprovados.trilhas_id,
    trilhas.nome_trilha,
    cadastro.nome_completo,
    aprovados.status_aprovacao
FROM 
    aprovados
INNER JOIN 
    cadastro ON aprovados.cadastro_id = cadastro.id
INNER JOIN 
    trilhas ON aprovados.trilhas_id = trilhas.id
WHERE 
    aprovados.status_aprovacao = 'aprovado';
