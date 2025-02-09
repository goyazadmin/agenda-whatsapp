document.addEventListener('DOMContentLoaded', async () => {
    const userId = localStorage.getItem('userId');

    if (!userId) {
        alert('Usuário não autenticado.');
        window.location.href = '/login.html';
        return;
    }

    // Envia o código de verificação ao carregar a página
    const phone = localStorage.getItem('phone'); // Supondo que o número do WhatsApp foi salvo no localStorage
    if (phone) {
        const response = await fetch('/enviar-codigo', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: userId, phone: phone })
        });

        const result = await response.json();
        if (!result.success) {
            alert('Erro ao enviar código de verificação.');
        }
    }

    // Valida o código digitado
    document.getElementById('validarCodigoButton').addEventListener('click', async () => {
        const codigo = document.getElementById('codigo').value;

        if (codigo.length !== 6) {
            alert('O código deve ter 6 dígitos.');
            return;
        }

        const response = await fetch('/validar-codigo', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: userId, codigo: codigo })
        });

        const result = await response.json();
        if (result.success) {
            alert('Código validado com sucesso!');
            window.location.href = '/index.html'; // Redireciona para a página principal
        } else {
            alert(result.message || 'Erro ao validar código.');
        }
    });
});