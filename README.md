# Azulejovania

Projeto de animações em pixel art 16-bit com clima gótico, feito na base da linguagem **Azulejo**.  
Arquivos Azulejo têm extensão `.azlj`. O runtime é gerenciado pela **LÖVE2D**.

## Propósito

Azulejovania usa a DSL declarativa Azulejo para desenhar cenas em grade de pixels. Cada programa descreve uma disciplina como uma cena visual animada usando comandos simples. A base Azulejo não é Turing-completa — e nem precisa ser.

## Trabalho Individual: Menu de Disciplinas

Este repositório inclui um menu em Lua para executar três pequenos programas de Azulejovania feitos sobre a base Azulejo:

- `programas/estruturas_dados.azlj`: castelo/vitral com árvore binária acendendo.
- `programas/algebra_linear.azlj`: sala gótica com eixos e vetores brilhando.
- `programas/circuitos_digitais.azlj`: torre elétrica com portas lógicas e sinal acendendo.

O menu não altera a linguagem. Ele só chama o runtime já existente com o comando:

```bash
love source/ programas/nome_do_programa.azlj
```

### Para quem nunca usou Lua

Lua é a linguagem usada no arquivo `menu.lua`. Para rodar este trabalho você não precisa programar em Lua; só precisa ter o comando `lua` disponível no terminal para abrir o menu.

Você também precisa instalar o **LÖVE2D**, que é o programa que abre a janela gráfica das animações.

1. Instale o LÖVE2D 11.x: <https://love2d.org/>
2. Instale Lua, caso o comando `lua` ainda não exista no terminal.
3. Abra o terminal na pasta do projeto.

No Windows PowerShell, por exemplo:

```powershell
cd C:\caminho\para\azulejovania
lua menu.lua
```

Depois escolha uma opção:

```text
1 - Estruturas de Dados
2 - Algebra Linear
3 - Circuitos Digitais
0 - Sair
```

Ao escolher uma disciplina, o menu executa a animação correspondente no LÖVE2D. Para fechar a animação, feche a janela ou pressione `Esc`.

### Se o comando `love` não funcionar

O menu usa o comando `love`. Se o LÖVE2D estiver instalado, mas o terminal não reconhecer `love`, você tem duas opções:

- Adicionar o LÖVE2D ao `PATH` do sistema.
- Informar o caminho do executável antes de rodar o menu.

No Windows PowerShell:

```powershell
$env:LOVE_CMD = "C:\Program Files\LOVE\love.exe"
lua menu.lua
```

### Rodar sem o menu

Se você ainda não tiver Lua instalado, pode executar cada programa diretamente pelo LÖVE2D:

```bash
love source/ programas/estruturas_dados.azlj
love source/ programas/algebra_linear.azlj
love source/ programas/circuitos_digitais.azlj
```

No Windows PowerShell, usando o caminho completo do LÖVE2D:

```powershell
& "C:\Program Files\LOVE\love.exe" source/ programas/estruturas_dados.azlj
```

## Como Usar

```bash
love source/ caminho/para/arquivo.azlj
```

---

## Tipos

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `int` | Inteiro positivo | `16`, `255` |
| `coord` | Par de coordenadas | `2,4` |
| `color` | Hex RGB ou RGBA | `#FF0000`, `#FF0000FF` |
| `size` | Dimensão do canvas | `16x16` |

---

## Comandos

### Canvas

```
size LARGURAxALTURA
```
**Obrigatório. Deve ser o primeiro comando.** Define tamanho da grade.

```
background #RRGGBB
```
Preenche fundo com cor sólida. Padrão: branco.

### Cor

```
color #RRGGBB
```
Define cor ativa para todos os comandos de desenho seguintes.

### Primitivas de Desenho

```
pixel x,y
```
Pixel único em `x,y`.

```
line x1,y1 x2,y2
```
Linha de `(x1,y1)` até `(x2,y2)`.

```
rect x1,y1 x2,y2
```
Retângulo vazio.

```
fill x1,y1 x2,y2
```
Retângulo preenchido.

```
circle x,y r
```
Círculo com centro `(x,y)` e raio `r`.

---

### Animação

Azulejo suporta animações frame-a-frame. Comandos de metadados vão **antes do primeiro `@frame`**. Comandos de desenho antes do primeiro `@frame` são executados em **todos os frames** (útil para background e elementos fixos).

#### Metadados

```
type animation
```
Declara arquivo como animação. Padrão: `image`.

```
framerate N
```
No runtime atual, `N` é o tempo em segundos entre um frame e outro. Padrão: `1.0`. Deve ser `> 0`.

Exemplos: `0.10`, `0.12`, `0.15`.

```
loop true
loop true N
loop false
```
Ativa loop. `N` opcional define número de repetições (`>= 1`). Sem `N`: loop infinito.

#### Frames

```
@frame
```
Marca início de um novo frame. Cada bloco entre marcadores é um frame independente.

---

## Estrutura de um Arquivo de Animação

```azlj
-- animacao.azlj
size 16x16
type animation
framerate 0.12
loop true

background #1a1a2e   -- executado em todos os frames

@frame
color #e94560
fill 4,4 8,8

@frame
color #e94560
fill 8,8 12,12

@frame
color #e94560
fill 4,8 8,12
```

> Comandos antes do primeiro `@frame` rodam como um conjunto de comandos fixos antes da execução de cada frame.  
> Se não houver nenhum `@frame`, o arquivo inteiro é tratado como imagem estática.

---

## Exemplo — Imagem Estática

```azlj
-- hello.azlj
size 16x16
background #1a1a2e
color #e94560
fill 4,4 12,12
color #ffffff
pixel 6,7
pixel 10,7
line 6,10 10,10
```

---

## Comentários

```
-- comentário de linha
```

Comentários podem aparecer no final de qualquer linha.

---

## Estrutura do Projeto

```
azulejovania/
├── README.md
├── source/
│   ├── main.lua        # entry point LÖVE2D
│   ├── tokenizer.lua
│   ├── parser.lua
│   ├── draw.lua
│   ├── state.lua
│   └── debug.lua
└── examples/
    ├── hello.azlj
    └── ...
```

---

## Dependências

- [Lua](https://www.lua.org/)
- [LÖVE2D 11.x](https://love2d.org/)

---

## Roadmap

- [ ] `repeat` / blocos de repetição
- [ ] `sprite` / `stamp` (sprites reutilizáveis)
