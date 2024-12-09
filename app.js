// Importar módulo express
const express = require('express');

// Importando módulo mysql
const mysql = require('mysql2');

//Importação módulo express-handlebars
const {engine} = require('express-handlebars');

// Instancia app express
const app = express();

//Adionando css
app.use('/css',express.static('./css'));

//adicioando img
app.use('/imagens',express.static('./imagens'))

//Configuração express-handelbars
app.engine('handlebars', engine());
app.set('view engine', 'handlebars');
app.set('views', './views');

//Manipulação de dados via rotas (json)
app.use(express.json());
app.use(express.urlencoded({extended:false}));

// Configuração de conexão
const conexao = mysql.createConnection({
    host: 'localhost',
    user:'root',
    password: '1234',
    database: 'inovatech'
});

// Teste de Conexão
conexao.connect(function(erro){
    if(erro) throw erro;
    console.log('conexão feita com sucesso');
});

// Rota homee
app.get('/', function(req, res){
    res.render('home-page');
});

//rota acessar 
app.get("/acessar", function(req,res){
    res.render('login');
});

// Rota de cadastro
app.post('/cadastrar', function (req, res) {
    // Obtendo dados do front
    let nome_completo = req.body.nome;
    let email = req.body.email;
    let senha = req.body.senha;

    // Verificar se o e-mail já existe
    let sqlCheck = `SELECT * FROM cadastro WHERE email = '${email}'`;


    conexao.query(sqlCheck, function (erro, resultados) {
        if (erro) throw erro;

        if (resultados.length > 0) {
            // E-mail já cadastrado
            res.send('Usuário já existe!');
        } else {
            // SQL para inserir o usuário
            let sqlInsert = `INSERT INTO cadastro (nome_completo, email, senha) VALUES('${nome_completo}', '${email}', '${senha}')`;

            conexao.query(sqlInsert, function (erro, retorno) {
                if (erro) throw erro;

                console.log(retorno);
                res.redirect('/acessar');
            });
        }
    });
});

//rota menu
app.get('/menu',function(req,res){
    res.render('menu');
});


//Rota login verificação
app.post('/login', function (req, res) {
    // Obtendo dados do front
    let email = req.body.email;
    let senha = req.body.senha;

    // SQL para verificar o usuário
    let sql = `SELECT * FROM cadastro WHERE email = '${email}' AND senha = '${senha}'`;
    

    conexao.query(sql, function (erro, resultados) {
        if (erro) throw erro;

        if (resultados.length > 0) {
            // Usuário encontrado
            let usuario = resultados[0]; // Dados do usuário
            console.log('Usuário logado:', usuario);
            res.redirect('/menu');
            res.send();
        } else {
            // Usuário não encontrado
            res.send('E-mail ou senha incorretos.');
        }
    });
});

// Rota de escrição
app.get('/escricao', function(req, res){
    res.render('inscrever');
});

app.post('/escreve',function(req, res){
    //obtendo dados do front 
    let nome = req.body.nomeCompleto;
    let dataNascimento = req.body.dataNascimento;
    let cpf = req.body.cpf;
    let genero = req.body.genero;
    let celular =req.body.celular;
    let escolaridade=req.body.escolaridade
    let cidade = req.body.cidade;
    let trilha = req.body.trilha;
    let nota = Math.floor(Math.random() * (50 - 1 + 1)) + 0;

    console.log(req.body , nota)

    let sql = `
        SELECT 
            (SELECT id FROM cadastro WHERE nome_completo = '${nome}') AS usuario_id,
            (SELECT id FROM trilhas WHERE nome_trilha = '${trilha}') AS trilha_id,
            (SELECT id FROM escolaridade WHERE  grau = '${escolaridade}') AS escolaridade_id,
            (SELECT id FROM cidade WHERE nome_cidade = '${cidade}') AS cidade_id
    `;

    conexao.query(sql, function (erro, resultados) {
        if (erro) throw erro;

        // Verificar se todas as chaves foram encontradas
        let chaves = resultados[0];
        if (!chaves.usuario_id || !chaves.trilha_id || !chaves.escolaridade_id || !chaves.cidade_id) {
            return res.send('Erro: Uma ou mais referências não encontradas.');
        }

        // Inserir na tabela 'pedidos' com as chaves estrangeiras 
        let sqlInsert = `
            INSERT INTO inscricoes (cpf ,data_nasc ,genero ,celular ,cadastro_id , trilhas_id , escolaridade_id , cidade_id ,nota )
            VALUES ('${cpf}','${dataNascimento}','${genero}','${celular}', ${chaves.usuario_id}, ${chaves.trilha_id}, ${chaves.escolaridade_id}, ${chaves.cidade_id} , ${nota})
        `;

        conexao.query(sqlInsert, function (erro, retorno) {
            if (erro) throw erro;
            res.redirect('/sucesso')
        });
    });
   
});

// rota cadastro com sucesso
app.get('/sucesso',function(req,res){
    res.render('sucesso');
});

app.get('/aprovados', function(req,res){
    let sql = ' SELECT aprovados.trilhas_id,trilhas.nome_trilha,cadastro.nome_completo,aprovados.status_aprovacao FROM aprovados INNER JOIN cadastro ON aprovados.cadastro_id = cadastro.id INNER JOIN trilhas ON aprovados.trilhas_id = trilhas.id WHERE aprovados.status_aprovacao = "aprovado" ';
 
    conexao.query(sql,function(erro,retorno){
        if(erro) throw erro;
        res.render('aprovados',{aprovados:retorno});
    });
});
// Servidor 
app.listen(8080);