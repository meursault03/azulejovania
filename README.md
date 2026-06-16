# Azulejovania

Azulejovania é um conjunto de animações em pixel art feitas com a linguagem **Azulejo**.

O projeto usa o runtime da linguagem Azulejo para abrir arquivos `.azlj` no **LÖVE2D** e adiciona um menu em Lua para escolher qual animação executar.

A proposta é representar três disciplinas do curso por meio de pequenas cenas animadas em estilo 16-bit.

## Programas disponíveis

O menu executa três animações:

```text
1 - Estruturas de Dados
2 - Algebra Linear
3 - Circuitos Digitais
0 - Sair
```

Arquivos principais:

```text
menu.lua
programas/estruturas_dados.azlj
programas/algebra_linear.azlj
programas/circuitos_digitais.azlj
source/
```

A pasta `source/` contém o runtime da linguagem Azulejo.

A pasta `programas/` contém os programas escritos em Azulejo para este trabalho.

## Requisitos

Para executar o projeto, é necessário ter instalado:

* Lua, para abrir o menu pelo terminal.
* LÖVE2D 11.x, para executar a janela gráfica das animações.

Links:

```text
https://www.lua.org/
https://love2d.org/
```

No Windows, depois de instalar o LÖVE2D, verifique se o comando abaixo funciona no PowerShell:

```powershell
love --version
```

Se o comando não for reconhecido, o LÖVE2D provavelmente não está no `PATH` do sistema.

## Como executar pelo menu

Abra o terminal na pasta do projeto:

```powershell
cd C:\caminho\para\azulejovania
```

Execute:

```powershell
lua menu.lua
```

Escolha uma das opções do menu.

Ao selecionar uma disciplina, o menu chama o runtime da linguagem com o arquivo `.azlj` correspondente.

Exemplo do que o menu executa internamente:

```powershell
love source/ programas/estruturas_dados.azlj
```

Para fechar a animação, feche a janela do LÖVE2D ou pressione `Esc`.

## Se o comando `love` não funcionar

Se o LÖVE2D estiver instalado, mas o terminal não reconhecer o comando `love`, existem duas opções.

A primeira é adicionar o LÖVE2D ao `PATH` do Windows.

A segunda é informar manualmente o caminho do executável antes de rodar o menu:

```powershell
$env:LOVE_CMD = "C:\Program Files\LOVE\love.exe"
lua menu.lua
```

Ajuste o caminho caso o LÖVE2D esteja instalado em outra pasta.

## Como executar sem o menu

Também é possível abrir cada animação diretamente:

```powershell
love source/ programas/estruturas_dados.azlj
love source/ programas/algebra_linear.azlj
love source/ programas/circuitos_digitais.azlj
```

Usando o caminho completo do LÖVE2D no Windows:

```powershell
& "C:\Program Files\LOVE\love.exe" source/ programas/estruturas_dados.azlj
```

## Como os arquivos funcionam

O menu é escrito em Lua comum. Ele lê a opção digitada no terminal e executa o arquivo `.azlj` correspondente.

As animações ficam nos arquivos Azulejo:

```text
programas/estruturas_dados.azlj
programas/algebra_linear.azlj
programas/circuitos_digitais.azlj
```

Cada arquivo `.azlj` descreve uma cena em grade de pixels usando comandos da linguagem, como:

```azlj
size 64x36
type animation
framerate 0.10
loop false

background #080711

@frame
color #F5C542
circle 24,8 2
```

Comandos antes do primeiro `@frame` formam a base fixa da cena.

Comandos depois de cada `@frame` formam os quadros da animação.

Neste runtime, o valor de `framerate` funciona como intervalo entre frames, em segundos. Por isso os programas usam valores como `0.08`, `0.10` ou `0.12`.

## Estrutura do projeto

```text
azulejovania/
├── README.md
├── menu.lua
├── programas/
│   ├── estruturas_dados.azlj
│   ├── algebra_linear.azlj
│   └── circuitos_digitais.azlj
└── source/
    ├── main.lua
    ├── tokenizer.lua
    ├── parser.lua
    ├── draw.lua
    ├── state.lua
    └── debug.lua
```

## Observação sobre autoria

O repositório original é [Azulejo](https://github.com/Anthhon/azulejo/tree/main) esolang criada para a disciplina de paradigmas de programação. Tonha is added

A parte individual deste repositório é composta pelo menu de execução e pelos programas `.azlj` na pasta `programas/`.
