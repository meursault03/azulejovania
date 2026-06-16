local programas = {
    {
        numero = "1",
        nome = "Estruturas de Dados",
        arquivo = "programas/estruturas_dados.azlj",
        descricao = "Cena de arvore binaria com nos se acendendo.",
    },
    {
        numero = "2",
        nome = "Algebra Linear",
        arquivo = "programas/algebra_linear.azlj",
        descricao = "Cena de vetores e transformacoes no plano.",
    },
    {
        numero = "3",
        nome = "Circuitos Digitais",
        arquivo = "programas/circuitos_digitais.azlj",
        descricao = "Cena de sinais passando por um circuito logico.",
    },
}

local function quote_arg(value)
    if value:find('[%s"]') then
        return '"' .. value:gsub('"', '\\"') .. '"'
    end

    return value
end

local function executar(programa)
    local love_cmd = os.getenv("LOVE_CMD") or "love"
    local comando = table.concat({
        quote_arg(love_cmd),
        "source/",
        quote_arg(programa.arquivo),
    }, " ")

    print("")
    print("Disciplina: " .. programa.nome)
    print("Relacao com a disciplina: " .. programa.descricao)
    print("Executando: " .. comando)
    print("Feche a janela do LOVE para voltar ao menu.")
    print("")

    local ok, _, code = os.execute(comando)
    local falhou = ok == nil
        or ok == false
        or (type(ok) == "number" and ok ~= 0)
        or (ok == true and code and code ~= 0)

    if falhou then
        print("Nao foi possivel executar o LOVE.")
        print("Confira se o LOVE2D esta instalado e se o comando 'love' funciona no terminal.")
    end
end

while true do
    print("========================================")
    print("Azulejovania - Menu de disciplinas")
    print("Pixel art 16-bit com clima gotico")
    print("========================================")

    for _, programa in ipairs(programas) do
        print(programa.numero .. " - " .. programa.nome)
    end

    print("0 - Sair")
    io.write("Escolha uma disciplina: ")

    local escolha = io.read("*l")

    if escolha == nil then
        print("")
        print("Entrada encerrada.")
        break
    end

    if escolha == "0" then
        print("Encerrado.")
        break
    end

    local selecionado = nil
    for _, programa in ipairs(programas) do
        if escolha == programa.numero then
            selecionado = programa
            break
        end
    end

    if selecionado then
        executar(selecionado)
    else
        print("")
        print("Opcao invalida.")
        print("")
    end
end
