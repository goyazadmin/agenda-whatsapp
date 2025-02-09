const crypto = require('crypto');

// Função para gerar um código aleatório de 6 dígitos
const gerarCodigo = () => {
    return crypto.randomInt(100000, 999999).toString();
};

// Rota para enviar o código de verificação via WhatsApp
app.post('/enviar-codigo', async (req, res) => {
    const { userId, phone } = req.body;

    try {
        // Gera um código de 6 dígitos
        const codigo = gerarCodigo();

        // Define a expiração do código (10 minutos a partir de agora)
        const expiracao = new Date(Date.now() + 10 * 60 * 1000);

        // Salva o código no banco de dados
        await pool.query(
            'INSERT INTO codigos_verificacao (user_id, codigo, expiracao) VALUES (?, ?, ?)',
            [userId, codigo, expiracao]
        );

        // Envia o código via WhatsApp usando a Evolution API
        const mensagem = `Seu código de verificação é: ${codigo}`;
        const response = await axios.post(
            `${process.env.EVOLUTION_API_URL}/messages/send`,
            {
                phone: phone,
                message: mensagem,
                instance: process.env.EVOLUTION_INSTANCE_NAME
            },
            {
                headers: {
                    'Authorization': `Bearer ${process.env.EVOLUTION_API_TOKEN}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        res.json({ success: true, message: 'Código enviado com sucesso.' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// Rota para validar o código de verificação
app.post('/validar-codigo', async (req, res) => {
    const { userId, codigo } = req.body;

    try {
        // Busca o código no banco de dados
        const [rows] = await pool.query(
            'SELECT * FROM codigos_verificacao WHERE user_id = ? AND codigo = ? AND expiracao > NOW()',
            [userId, codigo]
        );

        if (rows.length === 0) {
            return res.status(400).json({ success: false, message: 'Código inválido ou expirado.' });
        }

        // Remove o código após a validação
        await pool.query('DELETE FROM codigos_verificacao WHERE user_id = ?', [userId]);

        res.json({ success: true, message: 'Código validado com sucesso.' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});